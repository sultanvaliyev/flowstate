import SwiftUI

/// Color constants for the Zonn app theme
/// Inspired by forest/nature aesthetics for focus and productivity
enum AppColors {
    // MARK: - Main Background Colors

    /// Forest green - main background color
    /// A calming deep green reminiscent of forest canopy
    static let forestGreen = Color(red: 0.4, green: 0.65, blue: 0.55)

    /// Lighter forest green for dark mode backgrounds
    static let forestGreenDark = Color(red: 0.35, green: 0.55, blue: 0.45)

    // MARK: - Progress Ring Colors

    /// Lighter green for the active progress ring
    static let ringGreen = Color(red: 0.55, green: 0.8, blue: 0.65)

    /// Muted green for the background ring track
    static let ringTrack = Color(red: 0.35, green: 0.5, blue: 0.42).opacity(0.4)

    // MARK: - Button Colors

    /// Green for the Plant/Start button
    static let buttonGreen = Color(red: 0.45, green: 0.75, blue: 0.55)

    /// Pressed/active state for button
    static let buttonGreenPressed = Color(red: 0.4, green: 0.65, blue: 0.5)

    /// Cancel/Stop button color
    static let buttonCancel = Color(red: 0.85, green: 0.55, blue: 0.5)

    // MARK: - Surface Colors

    /// Light cream color for center circle background
    static let creamBackground = Color(red: 0.98, green: 0.96, blue: 0.92)

    /// Slightly darker cream for borders/shadows
    static let creamBorder = Color(red: 0.9, green: 0.87, blue: 0.82)

    // MARK: - Accent Colors

    /// Earth brown for soil/ground elements in tree view
    static let earthBrown = Color(red: 0.55, green: 0.4, blue: 0.3)

    /// Darker brown for depth
    static let earthBrownDark = Color(red: 0.45, green: 0.32, blue: 0.22)

    /// Tree trunk brown
    static let treeBrown = Color(red: 0.5, green: 0.35, blue: 0.25)

    // MARK: - Text Colors

    /// Primary text on dark/green backgrounds
    static let textOnGreen = Color.white

    /// Secondary text on dark/green backgrounds
    static let textOnGreenSecondary = Color.white.opacity(0.8)

    /// Primary text on light/cream backgrounds
    static let textOnCream = Color(red: 0.25, green: 0.35, blue: 0.3)

    /// Secondary text on light backgrounds
    static let textOnCreamSecondary = Color(red: 0.35, green: 0.45, blue: 0.4)

    // MARK: - Status Colors

    /// Success/completed state
    static let success = Color(red: 0.5, green: 0.8, blue: 0.55)

    /// Warning state
    static let warning = Color(red: 0.9, green: 0.75, blue: 0.4)

    /// Error/cancel state
    static let error = Color(red: 0.85, green: 0.45, blue: 0.45)
}

// MARK: - Color Extensions for Convenience

extension Color {
    /// Quick access to Zonn forest green
    static var zonnGreen: Color { AppColors.forestGreen }

    /// Quick access to Zonn cream background
    static var zonnCream: Color { AppColors.creamBackground }
}
