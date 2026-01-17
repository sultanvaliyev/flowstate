import Foundation
import Combine

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

    // MARK: - Computed Properties

    /// Whether a permission-related error is blocking functionality
    var hasPermissionError: Bool {
        if case .scriptExecutionFailed(let message) = lastError,
           message.contains("not authorized") || message.contains("-1743") {
            return true
        }
        return permissionStatus == .denied
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

    /// Starts polling Spotify for playback state updates.
    /// Updates will be received at the configured `pollingInterval`.
    func startPolling() {
        guard !isPolling else { return }

        isPolling = true
        lastError = nil

        // Check permission first, then start polling only if authorized
        Task {
            await checkPermission()
            if permissionStatus == .denied {
                lastError = .scriptExecutionFailed("Automation permission denied")
                isPolling = false
                return
            }

            // Only start actual polling if permission is granted
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
        let granted = await permissionHandler.requestPermission()
        await checkPermission()
        return granted
    }

    /// Opens System Settings to the Automation pane
    func openSystemSettings() {
        permissionHandler.openSystemSettings()
    }

    // MARK: - Manual Refresh

    /// Fetches the current playback state immediately.
    /// Use this for one-off refreshes outside of regular polling.
    func refresh() async {
        do {
            lastError = nil
            playbackState = try await service.fetchPlaybackState()
        } catch let error as SpotifyServiceError {
            lastError = error
            playbackState = .disconnected
        } catch {
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
