import SwiftUI

/// View displayed when Spotify automation permission is needed.
/// Shows a warning message and provides buttons to grant permission or open System Settings.
struct SpotifyPermissionView: View {
    // MARK: - Properties

    @ObservedObject var spotifyManager: SpotifyManager
    @State private var isRequestingPermission = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            // Warning icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28))
                .foregroundColor(AppColors.warning)

            // Title
            Text("Permission Required")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textOnGreen)

            // Description
            Text("FlowState needs permission to control Spotify. Please grant automation access to enable music controls.")
                .font(.system(size: 12))
                .foregroundColor(AppColors.textOnGreenSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            // Action buttons
            VStack(spacing: 8) {
                // Grant Permission button
                Button(action: requestPermission) {
                    HStack(spacing: 6) {
                        if isRequestingPermission {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.7)
                                .frame(width: 14, height: 14)
                        } else {
                            Image(systemName: "lock.open.fill")
                                .font(.system(size: 12))
                        }
                        Text("Grant Permission")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(AppColors.spotifyGreen)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isRequestingPermission)
                .help("Request permission to control Spotify")

                // Open System Settings button
                Button(action: openSettings) {
                    Text("Open System Settings")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppColors.textOnGreenSecondary)
                        .underline()
                }
                .buttonStyle(.plain)
                .help("Open System Settings to manage permissions")
            }
            .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func requestPermission() {
        isRequestingPermission = true

        Task {
            _ = await spotifyManager.requestPermission()
            isRequestingPermission = false
        }
    }

    private func openSettings() {
        spotifyManager.openSystemSettings()
    }
}

// MARK: - Previews

#Preview("Permission Required") {
    let mockService = MockSpotifyService.disconnected()
    let manager = SpotifyManager(service: mockService)

    return SpotifyPermissionView(spotifyManager: manager)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.spotifyWidgetBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.spotifyWidgetBorder, lineWidth: 1)
                )
        )
        .padding()
        .background(AppColors.forestGreen)
        .frame(width: 300)
}

#Preview("In Widget Context") {
    let mockService = MockSpotifyService.disconnected()
    let manager = SpotifyManager(service: mockService)

    return VStack {
        SpotifyPermissionView(spotifyManager: manager)
    }
    .padding(16)
    .background(
        RoundedRectangle(cornerRadius: 12)
            .fill(AppColors.spotifyWidgetBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.spotifyWidgetBorder, lineWidth: 1)
            )
    )
    .padding()
    .background(AppColors.forestGreen)
    .frame(width: 300)
}
