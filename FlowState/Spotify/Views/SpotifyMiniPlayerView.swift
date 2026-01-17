import SwiftUI
import AppKit

/// A minimal Spotify player view for compact window layouts.
/// Shows track info and essential controls (play/pause, skip) in a horizontal layout.
struct SpotifyMiniPlayerView: View {
    @ObservedObject var spotifyManager: SpotifyManager

    var body: some View {
        Group {
            if spotifyManager.isConnected {
                connectedView
            } else {
                disconnectedView
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private var connectedView: some View {
        HStack(spacing: 10) {
            // Track info
            VStack(alignment: .leading, spacing: 2) {
                Text(spotifyManager.trackName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.textOnGreen)
                    .lineLimit(1)

                if !spotifyManager.artistName.isEmpty {
                    Text(spotifyManager.artistName)
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.textOnGreenSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Mini controls
            HStack(spacing: 8) {
                Button(action: { Task { await spotifyManager.togglePlayPause() } }) {
                    Image(systemName: spotifyManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.white.opacity(0.15)))
                }
                .buttonStyle(.plain)

                Button(action: { Task { await spotifyManager.nextTrack() } }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var disconnectedView: some View {
        HStack(spacing: 8) {
            Image(systemName: "music.note")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textOnGreenSecondary)

            Text("Spotify not connected")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppColors.textOnGreenSecondary)

            Spacer()

            Button(action: {
                if let url = URL(string: "spotify:") {
                    NSWorkspace.shared.open(url)
                }
            }) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.11, green: 0.72, blue: 0.33))
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview("Connected") {
    SpotifyMiniPlayerView(spotifyManager: SpotifyManager(service: MockSpotifyService.playing()))
        .padding()
        .background(AppColors.forestGreen)
        .frame(width: 260)
}

#Preview("Disconnected") {
    SpotifyMiniPlayerView(spotifyManager: SpotifyManager(service: MockSpotifyService.disconnected()))
        .padding()
        .background(AppColors.forestGreen)
        .frame(width: 260)
}
