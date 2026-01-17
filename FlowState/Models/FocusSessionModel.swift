import Foundation
import SwiftData

/// SwiftData model for persisting focus sessions
@Model
final class FocusSessionModel {
    @Attribute(.unique) var id: UUID
    var startTime: Date
    var endTime: Date
    var durationSeconds: Int
    var targetDurationSeconds: Int
    var label: String

    /// Whether the session met or exceeded the target duration
    var wasCompleted: Bool {
        targetDurationSeconds > 0 && durationSeconds >= targetDurationSeconds
    }

    init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date,
        durationSeconds: Int,
        targetDurationSeconds: Int = 0,
        label: String = "Focus"
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.durationSeconds = durationSeconds
        self.targetDurationSeconds = targetDurationSeconds
        self.label = label
    }

    /// Convert from legacy FocusSession struct
    convenience init(from session: FocusSession) {
        self.init(
            id: session.id,
            startTime: session.startTime,
            endTime: session.endTime,
            durationSeconds: session.durationSeconds,
            targetDurationSeconds: session.targetDurationSeconds,
            label: session.label
        )
    }

    /// Convert to FocusSession struct for compatibility
    func toFocusSession() -> FocusSession {
        FocusSession(
            id: id,
            startTime: startTime,
            endTime: endTime,
            durationSeconds: durationSeconds,
            targetDurationSeconds: targetDurationSeconds,
            label: label
        )
    }
}
