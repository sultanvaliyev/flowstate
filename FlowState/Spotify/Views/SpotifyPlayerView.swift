import SwiftUI
import AppKit

/// A SwiftUI view that displays Spotify playback information and controls.
/// Shows either a connected view with track info and controls, or a disconnected
/// view prompting the user to open Spotify.
struct SpotifyPlayerView: View {
    // MARK: - Properties

    @ObservedObject var spotifyManager: SpotifyManager

    /// When true, displays a more compact layout suitable for embedding
    var isCompact: Bool = false

    // MARK: - Body

    var body: some View {
        Group {
            if spotifyManager.hasPermissionError {
                SpotifyPermissionView(spotifyManager: spotifyManager)
            } else if spotifyManager.isConnected {
                connectedView
            } else {
                disconnectedView
            }
        }
        .padding(isCompact ? 12 : 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.spotifyWidgetBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.spotifyWidgetBorder, lineWidth: 1)
                )
        )
        .onAppear {
            Task {
                await spotifyManager.checkPermission()
            }
        }
    }

    // MARK: - Connected View

    private var connectedView: some View {
        VStack(spacing: isCompact ? 10 : 14) {
            // Track info row
            trackInfoRow

            // Progress bar
            progressBar

            // Playback controls
            playbackControls
        }
    }

    private var trackInfoRow: some View {
        HStack(spacing: 12) {
            // Album art
            AlbumArtView(
                artworkURL: spotifyManager.albumArtworkURL,
                size: isCompact ? 44 : 56,
                cornerRadius: isCompact ? 6 : 8
            )

            // Track and artist info
            VStack(alignment: .leading, spacing: 2) {
                Text(spotifyManager.trackName)
                    .font(.system(size: isCompact ? 13 : 14, weight: .semibold))
                    .foregroundColor(AppColors.textOnGreen)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if !spotifyManager.artistName.isEmpty {
                    Text(spotifyManager.artistName)
                        .font(.system(size: isCompact ? 11 : 12))
                        .foregroundColor(AppColors.textOnGreenSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }

            Spacer()
        }
    }

    private var progressBar: some View {
        VStack(spacing: 4) {
            // Progress track
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppColors.spotifyProgressTrack)
                        .frame(height: 4)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppColors.spotifyProgressFill)
                        .frame(width: geometry.size.width * spotifyManager.trackProgress, height: 4)
                        .animation(.linear(duration: 0.3), value: spotifyManager.trackProgress)
                }
            }
            .frame(height: 4)

            // Time labels
            HStack {
                Text(spotifyManager.formattedPosition)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(AppColors.textOnGreenSecondary)

                Spacer()

                Text(spotifyManager.formattedDuration)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(AppColors.textOnGreenSecondary)
            }
        }
    }

    private var playbackControls: some View {
        SpotifyPlaybackControls(
            isPlaying: spotifyManager.isPlaying,
            isDisabled: !spotifyManager.isConnected,
            spacing: isCompact ? 12 : 16,
            onPrevious: {
                Task {
                    await spotifyManager.previousTrack()
                }
            },
            onPlayPause: {
                Task {
                    await spotifyManager.togglePlayPause()
                }
            },
            onNext: {
                Task {
                    await spotifyManager.nextTrack()
                }
            }
        )
    }

    // MARK: - Disconnected View

    private var disconnectedView: some View {
        VStack(spacing: 12) {
            // Spotify icon placeholder
            Image(systemName: "music.note")
                .font(.system(size: isCompact ? 24 : 32))
                .foregroundColor(AppColors.textOnGreenSecondary)

            Text("Spotify not connected")
                .font(.system(size: isCompact ? 12 : 14, weight: .medium))
                .foregroundColor(AppColors.textOnGreenSecondary)

            // Open Spotify button
            Button(action: openSpotify) {
                HStack(spacing: 6) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 14))
                    Text("Open Spotify")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(AppColors.textOnGreen)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(AppColors.spotifyGreen)
                )
            }
            .buttonStyle(.plain)
            .help("Open Spotify app")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, isCompact ? 8 : 12)
    }

    // MARK: - Actions

    private func openSpotify() {
        if let spotifyURL = URL(string: "spotify:") {
            NSWorkspace.shared.open(spotifyURL)
        }
    }
}

// MARK: - Previews

#Preview("Connected - Playing") {
    let mockService = MockSpotifyService.playing()
    let manager = SpotifyManager(service: mockService)

    return SpotifyPlayerView(spotifyManager: manager)
        .padding()
        .background(AppColors.forestGreen)
        .frame(width: 300)
        .onAppear {
            manager.startPolling()
        }
}

#Preview("Connected - Paused") {
    let mockService = MockSpotifyService.paused()
    let manager = SpotifyManager(service: mockService)

    return SpotifyPlayerView(spotifyManager: manager)
        .padding()
        .background(AppColors.forestGreen)
        .frame(width: 300)
        .onAppear {
            manager.startPolling()
        }
}

#Preview("Disconnected") {
    let mockService = MockSpotifyService.disconnected()
    let manager = SpotifyManager(service: mockService)

    return SpotifyPlayerView(spotifyManager: manager)
        .padding()
        .background(AppColors.forestGreen)
        .frame(width: 300)
}

#Preview("Compact Mode - Playing") {
    let mockService = MockSpotifyService.playing()
    let manager = SpotifyManager(service: mockService)

    return SpotifyPlayerView(spotifyManager: manager, isCompact: true)
        .padding()
        .background(AppColors.forestGreen)
        .frame(width: 280)
        .onAppear {
            manager.startPolling()
        }
}

#Preview("Compact Mode - Disconnected") {
    let mockService = MockSpotifyService.disconnected()
    let manager = SpotifyManager(service: mockService)

    return SpotifyPlayerView(spotifyManager: manager, isCompact: true)
        .padding()
        .background(AppColors.forestGreen)
        .frame(width: 280)
}

// Note: Permission Error preview requires MockSpotifyService to support
// permission status simulation. Once that's added, use:
// MockSpotifyService.permissionDenied() to create a service that simulates
// the permission error state.
