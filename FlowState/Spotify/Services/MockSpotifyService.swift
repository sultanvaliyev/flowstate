import Foundation

/// Mock implementation of SpotifyServiceProtocol for testing and SwiftUI previews.
/// Provides controllable playback state without requiring the actual Spotify application.
@MainActor
final class MockSpotifyService: SpotifyServiceProtocol {

    // MARK: - Configuration

    private var mockState: SpotifyPlaybackState
    private var shouldSimulateRunning: Bool
    private var pollingTimer: Timer?
    private var updateHandler: ((SpotifyPlaybackState) -> Void)?

    // MARK: - Initialization

    init(state: SpotifyPlaybackState, isRunning: Bool = true) {
        self.mockState = state
        self.shouldSimulateRunning = isRunning
    }

    deinit {
        pollingTimer?.invalidate()
    }

    // MARK: - Factory Methods

    /// Creates a mock service simulating active playback.
    static func playing() -> MockSpotifyService {
        MockSpotifyService(state: Self.samplePlayingState)
    }

    /// Creates a mock service simulating paused playback.
    static func paused() -> MockSpotifyService {
        MockSpotifyService(state: Self.samplePausedState)
    }

    /// Creates a mock service simulating Spotify not running.
    static func disconnected() -> MockSpotifyService {
        MockSpotifyService(state: .disconnected, isRunning: false)
    }

    // MARK: - Sample Data

    private static let samplePlayingState = SpotifyPlaybackState(
        isPlaying: true,
        trackName: "Bohemian Rhapsody",
        artistName: "Queen",
        albumName: "A Night at the Opera",
        albumArtworkURL: URL(string: "https://i.scdn.co/image/ab67616d0000b273e8b066f70c206551210d902b"),
        trackDurationSeconds: 354,
        trackPositionSeconds: 127,
        isConnected: true
    )

    private static let samplePausedState = SpotifyPlaybackState(
        isPlaying: false,
        trackName: "Bohemian Rhapsody",
        artistName: "Queen",
        albumName: "A Night at the Opera",
        albumArtworkURL: URL(string: "https://i.scdn.co/image/ab67616d0000b273e8b066f70c206551210d902b"),
        trackDurationSeconds: 354,
        trackPositionSeconds: 127,
        isConnected: true
    )

    // MARK: - SpotifyServiceProtocol

    var isSpotifyRunning: Bool {
        get async {
            shouldSimulateRunning
        }
    }

    func fetchPlaybackState() async throws -> SpotifyPlaybackState {
        guard shouldSimulateRunning else {
            return .disconnected
        }
        return mockState
    }

    func execute(_ command: SpotifyCommand) async throws {
        guard shouldSimulateRunning else {
            throw SpotifyServiceError.spotifyNotRunning
        }

        switch command {
        case .play:
            mockState = SpotifyPlaybackState(
                isPlaying: true,
                trackName: mockState.trackName,
                artistName: mockState.artistName,
                albumName: mockState.albumName,
                albumArtworkURL: mockState.albumArtworkURL,
                trackDurationSeconds: mockState.trackDurationSeconds,
                trackPositionSeconds: mockState.trackPositionSeconds,
                isConnected: mockState.isConnected
            )

        case .pause:
            mockState = SpotifyPlaybackState(
                isPlaying: false,
                trackName: mockState.trackName,
                artistName: mockState.artistName,
                albumName: mockState.albumName,
                albumArtworkURL: mockState.albumArtworkURL,
                trackDurationSeconds: mockState.trackDurationSeconds,
                trackPositionSeconds: mockState.trackPositionSeconds,
                isConnected: mockState.isConnected
            )

        case .togglePlayPause:
            mockState = SpotifyPlaybackState(
                isPlaying: !mockState.isPlaying,
                trackName: mockState.trackName,
                artistName: mockState.artistName,
                albumName: mockState.albumName,
                albumArtworkURL: mockState.albumArtworkURL,
                trackDurationSeconds: mockState.trackDurationSeconds,
                trackPositionSeconds: mockState.trackPositionSeconds,
                isConnected: mockState.isConnected
            )

        case .nextTrack:
            // Simulate changing to next track
            mockState = SpotifyPlaybackState(
                isPlaying: mockState.isPlaying,
                trackName: "Don't Stop Me Now",
                artistName: "Queen",
                albumName: "Jazz",
                albumArtworkURL: URL(string: "https://i.scdn.co/image/ab67616d0000b273e319baafd16e84f0408af2a0"),
                trackDurationSeconds: 209,
                trackPositionSeconds: 0,
                isConnected: true
            )

        case .previousTrack:
            // Simulate going to previous track
            mockState = SpotifyPlaybackState(
                isPlaying: mockState.isPlaying,
                trackName: "We Will Rock You",
                artistName: "Queen",
                albumName: "News of the World",
                albumArtworkURL: URL(string: "https://i.scdn.co/image/ab67616d0000b273e319baafd16e84f0408af2a0"),
                trackDurationSeconds: 122,
                trackPositionSeconds: 0,
                isConnected: true
            )
        }

        // Notify handler of the state change
        updateHandler?(mockState)
    }

    func startPolling(interval: TimeInterval, onUpdate: @escaping (SpotifyPlaybackState) -> Void) {
        stopPolling()

        updateHandler = onUpdate

        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                if self.shouldSimulateRunning {
                    // Simulate track position advancing when playing
                    if self.mockState.isPlaying {
                        let newPosition = min(
                            self.mockState.trackPositionSeconds + Int(interval),
                            self.mockState.trackDurationSeconds
                        )
                        self.mockState = SpotifyPlaybackState(
                            isPlaying: self.mockState.isPlaying,
                            trackName: self.mockState.trackName,
                            artistName: self.mockState.artistName,
                            albumName: self.mockState.albumName,
                            albumArtworkURL: self.mockState.albumArtworkURL,
                            trackDurationSeconds: self.mockState.trackDurationSeconds,
                            trackPositionSeconds: newPosition,
                            isConnected: self.mockState.isConnected
                        )
                    }
                    onUpdate(self.mockState)
                } else {
                    onUpdate(.disconnected)
                }
            }
        }

        RunLoop.main.add(timer, forMode: .common)
        pollingTimer = timer

        // Immediately deliver initial state
        Task {
            onUpdate(mockState)
        }
    }

    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        updateHandler = nil
    }

    // MARK: - Test Helpers

    /// Updates the mock state directly. Useful for testing specific scenarios.
    func setState(_ state: SpotifyPlaybackState) {
        mockState = state
        updateHandler?(state)
    }

    /// Simulates Spotify becoming available or unavailable.
    func setRunning(_ isRunning: Bool) {
        shouldSimulateRunning = isRunning
        if !isRunning {
            updateHandler?(.disconnected)
        }
    }
}
