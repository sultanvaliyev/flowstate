import Foundation
import UserNotifications

/// Manages macOS system notifications for focus session events
@MainActor
class NotificationManager: NSObject {
    static let shared = NotificationManager()

    private let notificationCenter = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        notificationCenter.delegate = self
    }

    // MARK: - Authorization

    /// Requests permission to display notifications
    /// - Returns: Whether authorization was granted
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                print("Notification authorization granted")
            } else {
                print("Notification authorization denied")
            }
            return granted
        } catch {
            print("Failed to request notification authorization: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Session Notifications

    /// Shows a notification when a focus session ends
    /// - Parameters:
    ///   - duration: The duration of the session in seconds
    ///   - label: The session label (e.g., "Deep Work", "Focus")
    ///   - wasCompleted: Whether the session completed naturally or was cancelled
    func showSessionCompletionNotification(duration: Int, label: String, wasCompleted: Bool) {
        let content = UNMutableNotificationContent()

        if wasCompleted {
            content.title = "Focus Session Complete!"
            content.body = formatCompletionBody(duration: duration, label: label)
            content.sound = .default
        } else {
            content.title = "Session Ended"
            content.body = formatCancellationBody(duration: duration, label: label)
            content.sound = .default
        }

        // Use a unique identifier for each notification
        let identifier = "session-\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Private Helpers

    private func formatCompletionBody(duration: Int, label: String) -> String {
        let formattedDuration = formatDuration(duration)
        return "Great work! You focused on \"\(label)\" for \(formattedDuration)."
    }

    private func formatCancellationBody(duration: Int, label: String) -> String {
        let formattedDuration = formatDuration(duration)
        return "You worked on \"\(label)\" for \(formattedDuration)."
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        } else {
            return "less than a minute"
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    /// Allows notifications to be displayed even when the app is in the foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    /// Handles user interaction with notifications
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap if needed in the future
        completionHandler()
    }
}
