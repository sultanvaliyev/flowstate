import AppKit
import Foundation

// MARK: - SpotifyPermissionHandler

@MainActor
final class SpotifyPermissionHandler: SpotifyPermissionProtocol {

    // MARK: - Constants

    private enum AppleScriptError {
        /// Error code indicating the user has not authorized automation
        static let notAuthorized = -1743

        /// Error code indicating the target application is not running
        static let applicationNotRunning = -600
    }

    private enum Script {
        /// Script to check if we have permission by querying Spotify's running state
        static let checkPermission = """
            tell application "Spotify" to return running
            """

        /// Benign script to trigger the permission prompt by talking to Spotify directly
        /// This will cause macOS to prompt for automation permission for Spotify
        static let requestPermission = """
            tell application "Spotify" to return name
            """
    }

    // MARK: - SpotifyPermissionProtocol

    var permissionStatus: SpotifyPermissionStatus {
        get async {
            await checkPermissionStatus()
        }
    }

    func requestPermission() async -> Bool {
        // Check for cancellation before starting work
        guard !Task.isCancelled else { return false }

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
                                continuation.resume(returning: false)
                            }
                        }
                        return
                    }

                    let script = NSAppleScript(source: Script.requestPermission)
                    var errorInfo: NSDictionary?

                    script?.executeAndReturnError(&errorInfo)

                    let granted: Bool
                    if let error = errorInfo,
                       let errorNumber = error[NSAppleScript.errorNumber] as? Int {
                        // If we get the "not authorized" error, permission was denied
                        granted = errorNumber != AppleScriptError.notAuthorized
                    } else {
                        // No error means the script executed successfully
                        granted = true
                    }

                    Task {
                        let alreadyResumed = await resumedFlag.tryMarkResumed()
                        if !alreadyResumed {
                            continuation.resume(returning: granted)
                        }
                    }
                }
            }
        } onCancel: {
            Task {
                let alreadyResumed = await resumedFlag.tryMarkResumed()
                if !alreadyResumed {
                    // Cancellation occurred - continuation will be resumed with false
                }
            }
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
                        switch errorNumber {
                        case AppleScriptError.notAuthorized:
                            // User has explicitly denied automation permission
                            status = .denied
                        case AppleScriptError.applicationNotRunning:
                            // App not running is fine - we still have permission to automate it
                            status = .authorized
                        default:
                            // Other errors - treat as not determined
                            status = .notDetermined
                        }
                    } else {
                        // No error means script executed successfully - we have permission
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
