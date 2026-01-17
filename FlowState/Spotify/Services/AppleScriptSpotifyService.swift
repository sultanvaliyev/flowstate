import AppKit
import Foundation

/// AppleScript-based implementation of SpotifyServiceProtocol.
/// Uses NSAppleScript to communicate with the Spotify desktop application.
@MainActor
final class AppleScriptSpotifyService: SpotifyServiceProtocol {

    // MARK: - Constants

    private static let spotifyBundleIdentifier = "com.spotify.client"

    // MARK: - State

    private var pollingTimer: Timer?
    private var updateHandler: ((SpotifyPlaybackState) -> Void)?

    // MARK: - Initialization

    init() {}

    deinit {
        pollingTimer?.invalidate()
    }

    // MARK: - SpotifyServiceProtocol

    var isSpotifyRunning: Bool {
        get async {
            checkSpotifyRunning()
        }
    }

    func fetchPlaybackState() async throws -> SpotifyPlaybackState {
        guard checkSpotifyRunning() else {
            return .disconnected
        }

        // Check for cancellation before starting work
        try Task.checkCancellation()

        // Use an actor-isolated flag to track if continuation has been resumed
        let resumedFlag = ResumedFlag()

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    // Check if task was cancelled before doing work
                    guard !Task.isCancelled else {
                        Task {
                            let alreadyResumed = await resumedFlag.tryMarkResumed()
                            if !alreadyResumed {
                                continuation.resume(throwing: CancellationError())
                            }
                        }
                        return
                    }

                    do {
                        let state = try self.fetchPlaybackStateSync()
                        Task {
                            let alreadyResumed = await resumedFlag.tryMarkResumed()
                            if !alreadyResumed {
                                continuation.resume(returning: state)
                            }
                        }
                    } catch {
                        Task {
                            let alreadyResumed = await resumedFlag.tryMarkResumed()
                            if !alreadyResumed {
                                continuation.resume(throwing: error)
                            }
                        }
                    }
                }
            }
        } onCancel: {
            Task {
                let alreadyResumed = await resumedFlag.tryMarkResumed()
                if !alreadyResumed {
                    // The continuation will be resumed with cancellation error
                    // Note: This is a best-effort cancellation; the work may still complete
                }
            }
        }
    }

    func execute(_ command: SpotifyCommand) async throws {
        guard checkSpotifyRunning() else {
            throw SpotifyServiceError.spotifyNotRunning
        }

        // Check for cancellation before starting work
        try Task.checkCancellation()

        let script = commandScript(for: command)

        // Use an actor-isolated flag to track if continuation has been resumed
        let resumedFlag = ResumedFlag()

        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                DispatchQueue.global(qos: .userInitiated).async {
                    // Check if task was cancelled before doing work
                    guard !Task.isCancelled else {
                        Task {
                            let alreadyResumed = await resumedFlag.tryMarkResumed()
                            if !alreadyResumed {
                                continuation.resume(throwing: CancellationError())
                            }
                        }
                        return
                    }

                    do {
                        try self.executeScriptSync(script)
                        Task {
                            let alreadyResumed = await resumedFlag.tryMarkResumed()
                            if !alreadyResumed {
                                continuation.resume()
                            }
                        }
                    } catch {
                        Task {
                            let alreadyResumed = await resumedFlag.tryMarkResumed()
                            if !alreadyResumed {
                                continuation.resume(throwing: error)
                            }
                        }
                    }
                }
            }
        } onCancel: {
            Task {
                let alreadyResumed = await resumedFlag.tryMarkResumed()
                if !alreadyResumed {
                    // The continuation will be resumed with cancellation error
                    // Note: This is a best-effort cancellation; the work may still complete
                }
            }
        }
    }

    func startPolling(interval: TimeInterval, onUpdate: @escaping (SpotifyPlaybackState) -> Void) {
        stopPolling()

        updateHandler = onUpdate

        // Create timer that runs in .common mode so it continues during UI interactions
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.pollPlaybackState()
            }
        }

        RunLoop.main.add(timer, forMode: .common)
        pollingTimer = timer

        // Immediately fetch the initial state
        Task {
            await pollPlaybackState()
        }
    }

    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        updateHandler = nil
    }

    // MARK: - Private Helpers

    private func checkSpotifyRunning() -> Bool {
        NSWorkspace.shared.runningApplications.contains { app in
            app.bundleIdentifier == Self.spotifyBundleIdentifier
        }
    }

    private func pollPlaybackState() async {
        guard let handler = updateHandler else { return }

        do {
            let state = try await fetchPlaybackState()
            handler(state)
        } catch {
            // On error, report disconnected state
            handler(.disconnected)
        }
    }

    // MARK: - AppleScript Execution (Sync, runs on background queue)

    /// Fetches playback state synchronously. Must be called from a background queue.
    private nonisolated func fetchPlaybackStateSync() throws -> SpotifyPlaybackState {
        let delimiter = "|||"
        let script = """
        tell application "Spotify"
            if player state is stopped then
                return "stopped"
            end if

            set trackName to name of current track
            set artistName to artist of current track
            set albumName to album of current track
            set artworkURL to artwork url of current track
            set trackDuration to duration of current track
            set trackPosition to player position
            set playState to player state as string

            return trackName & "\(delimiter)" & artistName & "\(delimiter)" & albumName & "\(delimiter)" & artworkURL & "\(delimiter)" & trackDuration & "\(delimiter)" & trackPosition & "\(delimiter)" & playState
        end tell
        """

        let result = try executeScriptSync(script)
        return try parsePlaybackResponse(result, delimiter: delimiter)
    }

    /// Executes an AppleScript synchronously and returns the string result.
    /// Must be called from a background queue.
    @discardableResult
    private nonisolated func executeScriptSync(_ source: String) throws -> String {
        var errorInfo: NSDictionary?

        guard let appleScript = NSAppleScript(source: source) else {
            throw SpotifyServiceError.scriptExecutionFailed("Failed to create script")
        }

        let result = appleScript.executeAndReturnError(&errorInfo)

        if let error = errorInfo {
            let message = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
            throw SpotifyServiceError.scriptExecutionFailed(message)
        }

        return result.stringValue ?? ""
    }

    /// Parses the delimited response string into a SpotifyPlaybackState.
    private nonisolated func parsePlaybackResponse(_ response: String, delimiter: String = "|||") throws -> SpotifyPlaybackState {
        // Handle stopped state
        if response == "stopped" {
            return SpotifyPlaybackState(
                isPlaying: false,
                trackName: "Not Playing",
                artistName: "",
                albumName: "",
                albumArtworkURL: nil,
                trackDurationSeconds: 0,
                trackPositionSeconds: 0,
                isConnected: true
            )
        }

        let components = response.components(separatedBy: delimiter)

        guard components.count == 7 else {
            throw SpotifyServiceError.invalidResponse
        }

        let trackName = components[0]
        let artistName = components[1]
        let albumName = components[2]
        let artworkURLString = components[3]
        let durationMilliseconds = Int(components[4]) ?? 0
        let positionSeconds = Int(Double(components[5]) ?? 0)
        let playStateString = components[6]

        // Duration from Spotify is in milliseconds, convert to seconds
        let durationSeconds = durationMilliseconds / 1000

        // Parse play state - "playing" or "paused"
        let isPlaying = playStateString.lowercased() == "playing"

        return SpotifyPlaybackState(
            isPlaying: isPlaying,
            trackName: trackName,
            artistName: artistName,
            albumName: albumName,
            albumArtworkURL: URL(string: artworkURLString),
            trackDurationSeconds: durationSeconds,
            trackPositionSeconds: positionSeconds,
            isConnected: true
        )
    }

    /// Returns the AppleScript command string for the given command.
    private func commandScript(for command: SpotifyCommand) -> String {
        let spotifyCommand: String

        switch command {
        case .play:
            spotifyCommand = "play"
        case .pause:
            spotifyCommand = "pause"
        case .togglePlayPause:
            spotifyCommand = "playpause"
        case .nextTrack:
            spotifyCommand = "next track"
        case .previousTrack:
            spotifyCommand = "previous track"
        }

        return """
        tell application "Spotify"
            \(spotifyCommand)
        end tell
        """
    }
}

// MARK: - ResumedFlag

/// Actor to safely track whether a continuation has been resumed.
/// Prevents double-resumption of continuations in async/cancellation scenarios.
private actor ResumedFlag {
    private var resumed = false

    /// Attempts to mark the flag as resumed.
    /// - Returns: `true` if the flag was already resumed (meaning you should NOT resume the continuation),
    ///            `false` if this is the first call (meaning you SHOULD resume the continuation).
    func tryMarkResumed() -> Bool {
        let wasResumed = resumed
        resumed = true
        return wasResumed
    }
}
