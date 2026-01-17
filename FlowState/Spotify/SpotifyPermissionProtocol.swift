import Foundation

/// Permission status for Spotify automation
enum SpotifyPermissionStatus: Equatable {
    case notDetermined
    case authorized
    case denied
    case restricted
}

/// Protocol for checking and requesting Spotify automation permissions
@MainActor
protocol SpotifyPermissionProtocol {
    /// Current permission status for Spotify automation
    var permissionStatus: SpotifyPermissionStatus { get async }

    /// Attempts to trigger the permission prompt by executing a benign AppleScript
    /// Returns true if permission was granted
    func requestPermission() async -> Bool

    /// Opens System Settings to the Automation privacy pane
    func openSystemSettings()
}
