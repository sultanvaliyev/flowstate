import SwiftUI

/// Color constants for Spotify integration UI
/// Designed to complement the existing Zonn forest theme
extension AppColors {
    // MARK: - Spotify Widget Colors

    /// Background for the Spotify player widget (semi-transparent dark)
    static let spotifyWidgetBackground = Color.black.opacity(0.25)

    /// Border color for the widget
    static let spotifyWidgetBorder = Color.white.opacity(0.15)

    /// Color for playback control buttons
    static let spotifyControlButton = Color.white.opacity(0.9)

    /// Color for disabled/inactive controls
    static let spotifyControlDisabled = Color.white.opacity(0.4)

    /// Background for control buttons on hover
    static let spotifyControlHover = Color.white.opacity(0.2)

    /// Spotify brand green (for optional accent)
    static let spotifyGreen = Color(red: 0.12, green: 0.84, blue: 0.38)

    /// Track progress bar background
    static let spotifyProgressTrack = Color.white.opacity(0.2)

    /// Track progress bar fill
    static let spotifyProgressFill = Color.white.opacity(0.8)
}
