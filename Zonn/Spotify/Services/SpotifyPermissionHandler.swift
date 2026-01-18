import AppKit
import Foundation
import OSLog

/// Logger for SpotifyPermissionHandler (defined at module level to avoid Sendable issues)
private let permissionLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.zonn", category: "SpotifyPermission")

// MARK: - SpotifyPermissionHandler

@MainActor
final class SpotifyPermissionHandler: SpotifyPermissionProtocol {

    // MARK: - Constants

    /// Bundle identifier for Spotify application
    private static let spotifyBundleIdentifier = "com.spotify.client"

    /// Time to wait for Spotify to launch before attempting permission request
    private static let spotifyLaunchWaitTime: TimeInterval = 2.0

    private enum AppleScriptError {
        /// Error code indicating the user has not authorized automation
        static let notAuthorized = -1743

        /// Error code indicating the target application is not running
        static let applicationNotRunning = -600
    }

    private enum Script {
        /// Script to check if we have permission by querying Spotify's running state
        static let checkPermission = """
            tell application id "com.spotify.client" to return running
            """

        /// Benign script to trigger the permission prompt by talking to Spotify directly
        /// This will cause macOS to prompt for automation permission for Spotify
        static let requestPermission = """
            tell application id "com.spotify.client" to return name
            """
    }

    // MARK: - SpotifyPermissionProtocol

    var permissionStatus: SpotifyPermissionStatus {
        get async {
            await checkPermissionStatus()
        }
    }

    func requestPermission() async -> Bool {
        // Ensure Spotify is running before attempting to request permission
        // The permission dialog only appears when we communicate with a running app
        let isRunning = isSpotifyRunning()

        if !isRunning {
            permissionLogger.info("Spotify not running, launching before requesting permission")

            guard await launchSpotify() else {
                permissionLogger.error("Failed to launch Spotify")
                return false
            }

            // Wait for Spotify to initialize before triggering permission request
            try? await Task.sleep(for: .seconds(Self.spotifyLaunchWaitTime))
        }

        // Execute on main thread to ensure permission dialog appears
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let script = NSAppleScript(source: Script.requestPermission)
                var errorInfo: NSDictionary?

                script?.executeAndReturnError(&errorInfo)

                let granted: Bool
                if let error = errorInfo,
                   let errorNumber = error[NSAppleScript.errorNumber] as? Int {
                    permissionLogger.debug("Permission request returned error code: \(errorNumber)")
                    // If we get the "not authorized" error, permission was denied
                    granted = errorNumber != AppleScriptError.notAuthorized
                } else {
                    // No error means the script executed successfully
                    permissionLogger.info("Permission granted successfully")
                    granted = true
                }

                continuation.resume(returning: granted)
            }
        }
    }

    // MARK: - Private Helpers

    /// Checks if Spotify is currently running
    private func isSpotifyRunning() -> Bool {
        NSWorkspace.shared.runningApplications.contains { app in
            app.bundleIdentifier == Self.spotifyBundleIdentifier
        }
    }

    /// Launches Spotify application
    /// - Returns: `true` if Spotify was launched successfully, `false` otherwise
    private func launchSpotify() async -> Bool {
        guard let spotifyURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.spotifyBundleIdentifier) else {
            permissionLogger.error("Could not find Spotify application")
            return false
        }

        do {
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = false // Don't bring Spotify to foreground

            _ = try await NSWorkspace.shared.openApplication(at: spotifyURL, configuration: configuration)
            permissionLogger.info("Spotify launched successfully")
            return true
        } catch {
            permissionLogger.error("Failed to launch Spotify: \(error.localizedDescription)")
            return false
        }
    }

    func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    // MARK: - Private

    private func checkPermissionStatus() async -> SpotifyPermissionStatus {
        // Check for cancellation before starting work
        guard !Task.isCancelled else { return .notDetermined }

        // Use an actor-isolated flag to track if continuation has been resumed
        let resumedFlag = ResumedFlag()

        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    // Check if task was cancelled before doing work
                    guard !Task.isCancelled else {
                        Task {
                            let alreadyResumed = await resumedFlag.tryMarkResumed()
                            if !alreadyResumed {
                                continuation.resume(returning: .notDetermined)
                            }
                        }
                        return
                    }

                    let script = NSAppleScript(source: Script.checkPermission)
                    var errorInfo: NSDictionary?

                    script?.executeAndReturnError(&errorInfo)

                    let status: SpotifyPermissionStatus

                    if let error = errorInfo,
                       let errorNumber = error[NSAppleScript.errorNumber] as? Int {
                        // Log the error details for debugging
                        let errorMessage = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
                        permissionLogger.debug("AppleScript error \(errorNumber): \(errorMessage)")

                        switch errorNumber {
                        case AppleScriptError.notAuthorized:
                            // User has explicitly denied automation permission
                            permissionLogger.info("Permission status: denied (user has not authorized automation)")
                            status = .denied
                        case AppleScriptError.applicationNotRunning:
                            // Spotify is not running - we cannot determine permission status
                            // The user needs to have Spotify running for us to check/request permission
                            permissionLogger.info("Permission status: notDetermined (Spotify is not running)")
                            status = .notDetermined
                        default:
                            // Other errors - treat as not determined
                            permissionLogger.warning("Permission status: notDetermined (unexpected error code: \(errorNumber))")
                            status = .notDetermined
                        }
                    } else {
                        // No error means script executed successfully - we have permission
                        permissionLogger.info("Permission status: authorized")
                        status = .authorized
                    }

                    Task {
                        let alreadyResumed = await resumedFlag.tryMarkResumed()
                        if !alreadyResumed {
                            continuation.resume(returning: status)
                        }
                    }
                }
            }
        } onCancel: {
            Task {
                let alreadyResumed = await resumedFlag.tryMarkResumed()
                if !alreadyResumed {
                    // Cancellation occurred - continuation will be resumed with notDetermined
                    permissionLogger.debug("Permission check cancelled")
                }
            }
        }
    }
}

// MARK: - ResumedFlag

/// Actor to safely track whether a continuation has been resumed.
/// Prevents double-resumption of continuations in async/cancellation scenarios.
private actor ResumedFlag {
    private var resumed = false

    /// Attempts to mark the flag as resumed.
    /// - Returns: `true` if the flag was already resumed (meaning you should NOT resume the continuation),
    ///            `false` if this is the first call (meaning you SHOULD resume the continuation).
    func tryMarkResumed() -> Bool {
        let wasResumed = resumed
        resumed = true
        return wasResumed
    }
}

// MARK: - MockSpotifyPermissionHandler

@MainActor
final class MockSpotifyPermissionHandler: SpotifyPermissionProtocol {

    // MARK: - Test Configuration

    var mockStatus: SpotifyPermissionStatus = .authorized
    var requestPermissionResult: Bool = true
    var openSettingsCalled = false

    // MARK: - SpotifyPermissionProtocol

    var permissionStatus: SpotifyPermissionStatus {
        get async { mockStatus }
    }

    func requestPermission() async -> Bool {
        requestPermissionResult
    }

    func openSystemSettings() {
        openSettingsCalled = true
    }
}
