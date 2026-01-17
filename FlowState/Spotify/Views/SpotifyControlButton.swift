import SwiftUI

/// A reusable button component for Spotify playback controls.
/// Displays a circular button with an SF Symbol icon that responds to hover.
struct SpotifyControlButton: View {
    // MARK: - Properties

    /// SF Symbol name for the button icon
    let iconName: String

    /// Whether the button is disabled
    var isDisabled: Bool = false

    /// Size of the button circle
    var size: CGFloat = 36

    /// Scale factor for the icon relative to the button size
    var iconScale: CGFloat = 0.5

    /// Whether this is a primary action button (larger, with permanent background)
    var isPrimary: Bool = false

    /// Action to perform when the button is tapped
    let action: () -> Void

    // MARK: - State

    @State private var isHovered: Bool = false

    // MARK: - Computed Properties

    private var iconColor: Color {
        isDisabled ? AppColors.spotifyControlDisabled : AppColors.spotifyControlButton
    }

    private var backgroundColor: Color {
        if isDisabled {
            return .clear
        }
        if isPrimary || isHovered {
            return AppColors.spotifyControlHover
        }
        return .clear
    }

    private var tooltipText: String {
        switch iconName {
        case "play.fill":
            return "Play"
        case "pause.fill":
            return "Pause"
        case "forward.fill":
            return "Next"
        case "backward.fill":
            return "Previous"
        default:
            return iconName
        }
    }

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: size, height: size)

                Image(systemName: iconName)
                    .font(.system(size: size * iconScale, weight: .semibold))
                    .foregroundColor(iconColor)
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .help(tooltipText)
    }
}

// MARK: - Factory Methods

extension SpotifyControlButton {
    /// Creates a play button with primary styling.
    /// - Parameters:
    ///   - isDisabled: Whether the button is disabled.
    ///   - action: The action to perform when tapped.
    /// - Returns: A configured SpotifyControlButton for play action.
    static func play(isDisabled: Bool = false, action: @escaping () -> Void) -> SpotifyControlButton {
        SpotifyControlButton(
            iconName: "play.fill",
            isDisabled: isDisabled,
            size: 44,
            iconScale: 0.45,
            isPrimary: true,
            action: action
        )
    }

    /// Creates a pause button with primary styling.
    /// - Parameters:
    ///   - isDisabled: Whether the button is disabled.
    ///   - action: The action to perform when tapped.
    /// - Returns: A configured SpotifyControlButton for pause action.
    static func pause(isDisabled: Bool = false, action: @escaping () -> Void) -> SpotifyControlButton {
        SpotifyControlButton(
            iconName: "pause.fill",
            isDisabled: isDisabled,
            size: 44,
            iconScale: 0.45,
            isPrimary: true,
            action: action
        )
    }

    /// Creates a next track button.
    /// - Parameters:
    ///   - isDisabled: Whether the button is disabled.
    ///   - action: The action to perform when tapped.
    /// - Returns: A configured SpotifyControlButton for next track action.
    static func next(isDisabled: Bool = false, action: @escaping () -> Void) -> SpotifyControlButton {
        SpotifyControlButton(
            iconName: "forward.fill",
            isDisabled: isDisabled,
            size: 32,
            iconScale: 0.5,
            isPrimary: false,
            action: action
        )
    }

    /// Creates a previous track button.
    /// - Parameters:
    ///   - isDisabled: Whether the button is disabled.
    ///   - action: The action to perform when tapped.
    /// - Returns: A configured SpotifyControlButton for previous track action.
    static func previous(isDisabled: Bool = false, action: @escaping () -> Void) -> SpotifyControlButton {
        SpotifyControlButton(
            iconName: "backward.fill",
            isDisabled: isDisabled,
            size: 32,
            iconScale: 0.5,
            isPrimary: false,
            action: action
        )
    }
}

// MARK: - Grouped Playback Controls

/// A grouped set of Spotify playback controls (previous, play/pause, next).
struct SpotifyPlaybackControls: View {
    // MARK: - Properties

    /// Whether music is currently playing
    let isPlaying: Bool

    /// Whether all controls should be disabled
    var isDisabled: Bool = false

    /// Spacing between control buttons
    var spacing: CGFloat = 16

    // MARK: - Callbacks

    /// Called when the previous track button is tapped
    let onPrevious: () -> Void

    /// Called when the play/pause button is tapped
    let onPlayPause: () -> Void

    /// Called when the next track button is tapped
    let onNext: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: spacing) {
            SpotifyControlButton.previous(isDisabled: isDisabled, action: onPrevious)

            if isPlaying {
                SpotifyControlButton.pause(isDisabled: isDisabled, action: onPlayPause)
            } else {
                SpotifyControlButton.play(isDisabled: isDisabled, action: onPlayPause)
            }

            SpotifyControlButton.next(isDisabled: isDisabled, action: onNext)
        }
    }
}

// MARK: - Previews

#Preview("Play Button") {
    ZStack {
        AppColors.forestGreen
        SpotifyControlButton.play { }
    }
    .frame(width: 100, height: 100)
}

#Preview("Pause Button") {
    ZStack {
        AppColors.forestGreen
        SpotifyControlButton.pause { }
    }
    .frame(width: 100, height: 100)
}

#Preview("Next Button") {
    ZStack {
        AppColors.forestGreen
        SpotifyControlButton.next { }
    }
    .frame(width: 100, height: 100)
}

#Preview("Disabled Button") {
    ZStack {
        AppColors.forestGreen
        SpotifyControlButton.play(isDisabled: true) { }
    }
    .frame(width: 100, height: 100)
}

#Preview("Grouped Controls - Playing") {
    ZStack {
        AppColors.forestGreen
        SpotifyPlaybackControls(
            isPlaying: true,
            onPrevious: { },
            onPlayPause: { },
            onNext: { }
        )
    }
    .frame(width: 200, height: 100)
}

#Preview("Grouped Controls - Paused") {
    ZStack {
        AppColors.forestGreen
        SpotifyPlaybackControls(
            isPlaying: false,
            onPrevious: { },
            onPlayPause: { },
            onNext: { }
        )
    }
    .frame(width: 200, height: 100)
}

#Preview("Grouped Controls - Disabled") {
    ZStack {
        AppColors.forestGreen
        SpotifyPlaybackControls(
            isPlaying: false,
            isDisabled: true,
            onPrevious: { },
            onPlayPause: { },
            onNext: { }
        )
    }
    .frame(width: 200, height: 100)
}
