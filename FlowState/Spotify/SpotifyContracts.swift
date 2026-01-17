import Foundation

// MARK: - Playback State

/// Represents the current state of Spotify playback
struct SpotifyPlaybackState: Equatable {
    let isPlaying: Bool
    let trackName: String
    let artistName: String
    let albumName: String
    let albumArtworkURL: URL?
    let trackDurationSeconds: Int
    let trackPositionSeconds: Int

    /// Whether Spotify is running and connected
    let isConnected: Bool

    static let disconnected = SpotifyPlaybackState(
        isPlaying: false,
        trackName: "",
        artistName: "",
        albumName: "",
        albumArtworkURL: nil,
        trackDurationSeconds: 0,
        trackPositionSeconds: 0,
        isConnected: false
    )

    static let idle = SpotifyPlaybackState(
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

// MARK: - Playback Command

/// Commands that can be sent to Spotify
enum SpotifyCommand {
    case play
    case pause
    case togglePlayPause
    case nextTrack
    case previousTrack
}

// MARK: - Service Protocol

/// Protocol defining the interface for Spotify communication
/// Implementations handle the actual Spotify API or AppleScript calls
@MainActor
protocol SpotifyServiceProtocol {
    /// Whether Spotify app is currently running
    var isSpotifyRunning: Bool { get async }

    /// Fetch the current playback state
    func fetchPlaybackState() async throws -> SpotifyPlaybackState

    /// Execute a playback command
    func execute(_ command: SpotifyCommand) async throws

    /// Start polling for playback state changes
    func startPolling(interval: TimeInterval, onUpdate: @escaping (SpotifyPlaybackState) -> Void)

    /// Stop polling
    func stopPolling()
}

// MARK: - Service Error

/// Errors that can occur when communicating with Spotify
enum SpotifyServiceError: Error, LocalizedError {
    case spotifyNotRunning
    case scriptExecutionFailed(String)
    case invalidResponse
    case connectionFailed

    var errorDescription: String? {
        switch self {
        case .spotifyNotRunning:
            return "Spotify is not running"
        case .scriptExecutionFailed(let message):
            return "Script execution failed: \(message)"
        case .invalidResponse:
            return "Invalid response from Spotify"
        case .connectionFailed:
            return "Failed to connect to Spotify"
        }
    }
}
