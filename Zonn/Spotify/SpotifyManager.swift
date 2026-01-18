import Foundation
import Combine
import os.log

private let logger = Logger(subsystem: "app.zonn.Zonn", category: "SpotifyManager")

/// Manages Spotify playback state and provides an observable interface for SwiftUI views.
/// Uses dependency injection for the underlying Spotify service to enable testing.
@MainActor
final class SpotifyManager: ObservableObject {

    // MARK: - Published Properties

    /// Current playback state from Spotify
    @Published private(set) var playbackState: SpotifyPlaybackState = .disconnected

    /// Whether the manager is actively polling for state updates
    @Published private(set) var isPolling: Bool = false

    /// The most recent error encountered, if any
    @Published private(set) var lastError: SpotifyServiceError?

    /// Whether automation permission has been granted
    @Published private(set) var permissionStatus: SpotifyPermissionStatus = .notDetermined

    // MARK: - Configuration

    /// Interval between polling updates in seconds
    var pollingInterval: TimeInterval = 1.0

    // MARK: - Dependencies

    private let service: SpotifyServiceProtocol
    private let permissionHandler: SpotifyPermissionProtocol

    // MARK: - Initialization

    /// Creates a new SpotifyManager with the specified service.
    /// - Parameter service: The Spotify service implementation to use for communication.
    /// - Parameter permissionHandler: The permission handler for automation permissions.
    init(service: SpotifyServiceProtocol, permissionHandler: SpotifyPermissionProtocol? = nil) {
        self.service = service
        self.permissionHandler = permissionHandler ?? SpotifyPermissionHandler()
    }

    // MARK: - Permission Error Codes

    /// AppleScript error codes related to automation permissions
    private enum AppleScriptErrorCode: Int {
        case notAuthorized = -1743      // Application not authorized for automation
        case userCancelled = -1744      // User cancelled the permission dialog
        case accessNotAllowed = -10004  // Access not allowed (alternative error)
    }

    // MARK: - Computed Properties

    /// Whether a permission-related error is blocking functionality
    var hasPermissionError: Bool {
        // Check explicit permission status first
        if permissionStatus == .denied {
            return true
        }

        // Check for permission-related errors in lastError
        guard case .scriptExecutionFailed(let message) = lastError else {
            return false
        }

        // Check for known permission error codes using regex for reliable extraction
        let permissionErrorCodes: [AppleScriptErrorCode] = [.notAuthorized, .userCancelled, .accessNotAllowed]
        for errorCode in permissionErrorCodes {
            // Match error code in various formats: "-1743", "error -1743", "(-1743)"
            let patterns = [
                "\\b\(errorCode.rawValue)\\b",           // Standalone number with word boundary
                "error\\s*\(errorCode.rawValue)",        // "error -1743" format
                "\\(\(errorCode.rawValue)\\)"            // "(-1743)" format
            ]
            for pattern in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                   regex.firstMatch(in: message, options: [], range: NSRange(message.startIndex..., in: message)) != nil {
                    return true
                }
            }
        }

        // Check for common permission-related phrases (fallback)
        let permissionPhrases = [
            "not authorized",
            "not granted",
            "permission denied",
            "automation permission",
            "not allowed to send apple events"
        ]
        let lowercasedMessage = message.lowercased()
        return permissionPhrases.contains { lowercasedMessage.contains($0) }
    }

    /// Whether Spotify is connected and running
    var isConnected: Bool {
        playbackState.isConnected
    }

    /// Whether music is currently playing
    var isPlaying: Bool {
        playbackState.isPlaying
    }

    /// Name of the currently playing track, or empty string if none
    var trackName: String {
        playbackState.trackName
    }

    /// Name of the artist for the current track, or empty string if none
    var artistName: String {
        playbackState.artistName
    }

    /// Name of the album for the current track, or empty string if none
    var albumName: String {
        playbackState.albumName
    }

    /// URL for the album artwork, or nil if unavailable
    var albumArtworkURL: URL? {
        playbackState.albumArtworkURL
    }

    /// Track progress as a value from 0.0 to 1.0
    var trackProgress: Double {
        guard playbackState.trackDurationSeconds > 0 else { return 0.0 }
        let progress = Double(playbackState.trackPositionSeconds) / Double(playbackState.trackDurationSeconds)
        return min(max(progress, 0.0), 1.0)
    }

    /// Current position formatted as "M:SS" (e.g., "1:23")
    var formattedPosition: String {
        formatTime(playbackState.trackPositionSeconds)
    }

    /// Track duration formatted as "M:SS" (e.g., "3:45")
    var formattedDuration: String {
        formatTime(playbackState.trackDurationSeconds)
    }

    // MARK: - Polling Control

    /// Whether polling was stopped due to permission denial (requires manual retry)
    @Published private(set) var isBlockedByPermission: Bool = false

    /// Starts polling Spotify for playback state updates.
    /// Updates will be received at the configured `pollingInterval`.
    /// If permission is denied, sets `isBlockedByPermission` to true and requires manual retry via `retryAfterPermissionGranted()`.
    func startPolling() {
        guard !isPolling else { return }

        isPolling = true
        lastError = nil
        isBlockedByPermission = false

        Task {
            let permissionGranted = await ensurePermissionGranted()

            if !permissionGranted {
                // Permission was denied or user cancelled - don't keep retrying automatically
                isPolling = false
                isBlockedByPermission = true

                // Set a clear error state based on permission status
                switch permissionStatus {
                case .denied:
                    lastError = .scriptExecutionFailed("Automation permission denied. Please enable Spotify automation in System Settings > Privacy & Security > Automation.")
                    logger.warning("Polling blocked: Automation permission explicitly denied")
                case .notDetermined:
                    lastError = .scriptExecutionFailed("Automation permission not granted. Please allow Spotify automation when prompted, or enable it in System Settings.")
                    logger.warning("Polling blocked: Automation permission not determined after request")
                case .restricted:
                    lastError = .scriptExecutionFailed("Automation permission is restricted by system policy.")
                    logger.warning("Polling blocked: Automation permission restricted")
                case .authorized:
                    // This shouldn't happen if permissionGranted is false, but handle it gracefully
                    break
                }
                return
            }

            logger.debug("Permission granted, starting Spotify polling")
            service.startPolling(interval: pollingInterval) { [weak self] state in
                Task { @MainActor in
                    self?.playbackState = state
                }
            }
        }
    }

    /// Stops polling for playback state updates.
    func stopPolling() {
        guard isPolling else { return }

        service.stopPolling()
        isPolling = false
    }

    // MARK: - Permission Management

    /// Checks the current permission status and updates published state
    func checkPermission() async {
        permissionStatus = await permissionHandler.permissionStatus
    }

    /// Attempts to request automation permission
    @discardableResult
    func requestPermission() async -> Bool {
        logger.debug("requestPermission() called")
        let granted = await permissionHandler.requestPermission()
        await checkPermission()
        logger.debug("requestPermission() result: granted=\(granted), status=\(String(describing: self.permissionStatus))")
        return granted
    }

    /// Opens System Settings to the Automation pane
    func openSystemSettings() {
        permissionHandler.openSystemSettings()
    }

    /// Ensures that automation permission is granted before performing Spotify operations.
    /// This is the single entry point for permission checks.
    /// - Returns: `true` if permission is authorized, `false` otherwise.
    func ensurePermissionGranted() async -> Bool {
        logger.debug("ensurePermissionGranted() called")

        // First, check current permission status
        await checkPermission()

        switch permissionStatus {
        case .authorized:
            logger.debug("ensurePermissionGranted(): Already authorized")
            return true

        case .notDetermined:
            // Permission not yet requested - trigger the permission prompt
            logger.debug("ensurePermissionGranted(): Status not determined, requesting permission")
            let granted = await requestPermission()
            if granted {
                logger.debug("ensurePermissionGranted(): Permission granted after request")
                return true
            } else {
                logger.debug("ensurePermissionGranted(): Permission denied or cancelled after request")
                return false
            }

        case .denied:
            logger.debug("ensurePermissionGranted(): Permission explicitly denied")
            return false

        case .restricted:
            logger.debug("ensurePermissionGranted(): Permission restricted by system policy")
            return false
        }
    }

    /// Called after the user might have granted permission in System Settings.
    /// Re-checks the permission status and starts polling if now authorized.
    func retryAfterPermissionGranted() async {
        logger.debug("retryAfterPermissionGranted() called")

        // Clear previous error state to give a fresh start
        lastError = nil

        // Re-check permission status (user may have enabled in System Settings)
        await checkPermission()

        switch permissionStatus {
        case .authorized:
            logger.debug("retryAfterPermissionGranted(): Permission now authorized, starting polling")
            isBlockedByPermission = false
            startPolling()

        case .notDetermined:
            // This is unusual after a retry, but try requesting again
            logger.debug("retryAfterPermissionGranted(): Permission still not determined, requesting")
            let granted = await requestPermission()
            if granted {
                isBlockedByPermission = false
                startPolling()
            } else {
                isBlockedByPermission = true
                lastError = .scriptExecutionFailed("Automation permission not granted. Please enable Spotify automation in System Settings.")
            }

        case .denied:
            logger.debug("retryAfterPermissionGranted(): Permission still denied")
            isBlockedByPermission = true
            lastError = .scriptExecutionFailed("Automation permission is still denied. Please enable Spotify automation in System Settings > Privacy & Security > Automation.")

        case .restricted:
            logger.debug("retryAfterPermissionGranted(): Permission restricted")
            isBlockedByPermission = true
            lastError = .scriptExecutionFailed("Automation permission is restricted by system policy.")
        }
    }

    // MARK: - Manual Refresh

    /// Fetches the current playback state immediately.
    /// Use this for one-off refreshes outside of regular polling.
    func refresh() async {
        logger.debug("refresh() called")
        do {
            lastError = nil
            playbackState = try await service.fetchPlaybackState()
            logger.debug("refresh() success - isConnected: \(self.playbackState.isConnected), track: \(self.playbackState.trackName)")
        } catch let error as SpotifyServiceError {
            logger.error("refresh() failed with SpotifyServiceError: \(error.localizedDescription)")
            lastError = error
            playbackState = .disconnected
        } catch {
            logger.error("refresh() failed with error: \(error.localizedDescription)")
            lastError = .connectionFailed
            playbackState = .disconnected
        }
    }

    // MARK: - Playback Controls

    /// Toggles between play and pause states.
    /// Performs an optimistic UI update before sending the command.
    func togglePlayPause() async {
        // Optimistic UI update
        let previousState = playbackState
        let optimisticState = SpotifyPlaybackState(
            isPlaying: !playbackState.isPlaying,
            trackName: playbackState.trackName,
            artistName: playbackState.artistName,
            albumName: playbackState.albumName,
            albumArtworkURL: playbackState.albumArtworkURL,
            trackDurationSeconds: playbackState.trackDurationSeconds,
            trackPositionSeconds: playbackState.trackPositionSeconds,
            isConnected: playbackState.isConnected
        )
        playbackState = optimisticState

        do {
            lastError = nil
            try await service.execute(.togglePlayPause)
        } catch let error as SpotifyServiceError {
            // Revert optimistic update on failure
            lastError = error
            playbackState = previousState
        } catch {
            lastError = .connectionFailed
            playbackState = previousState
        }
    }

    /// Starts playback.
    func play() async {
        do {
            lastError = nil
            try await service.execute(.play)
            await refresh()
        } catch let error as SpotifyServiceError {
            lastError = error
        } catch {
            lastError = .connectionFailed
        }
    }

    /// Pauses playback.
    func pause() async {
        do {
            lastError = nil
            try await service.execute(.pause)
            await refresh()
        } catch let error as SpotifyServiceError {
            lastError = error
        } catch {
            lastError = .connectionFailed
        }
    }

    /// Skips to the next track.
    /// Includes a small delay before refreshing to allow Spotify to update.
    func nextTrack() async {
        do {
            lastError = nil
            try await service.execute(.nextTrack)
            // Small delay to let Spotify update its state
            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
            await refresh()
        } catch let error as SpotifyServiceError {
            lastError = error
        } catch {
            lastError = .connectionFailed
        }
    }

    /// Returns to the previous track.
    /// Includes a small delay before refreshing to allow Spotify to update.
    func previousTrack() async {
        do {
            lastError = nil
            try await service.execute(.previousTrack)
            // Small delay to let Spotify update its state
            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
            await refresh()
        } catch let error as SpotifyServiceError {
            lastError = error
        } catch {
            lastError = .connectionFailed
        }
    }

    // MARK: - Private Helpers

    /// Formats seconds into "M:SS" format.
    /// - Parameter seconds: Total seconds to format.
    /// - Returns: Formatted string like "1:23" or "0:00".
    private func formatTime(_ seconds: Int) -> String {
        guard seconds >= 0 else { return "0:00" }
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}
