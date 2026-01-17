import Foundation

/// Represents the current phase of the focus timer
enum TimerPhase: String, Codable {
    case idle
    case running
    case paused
    case completed
    case cancelled

    /// Whether the timer is currently active (running or paused)
    var isActive: Bool {
        switch self {
        case .running, .paused:
            return true
        case .idle, .completed, .cancelled:
            return false
        }
    }

    /// Whether a new timer session can be started from this phase
    var canStart: Bool {
        switch self {
        case .idle, .completed, .cancelled:
            return true
        case .running, .paused:
            return false
        }
    }

    /// Whether the current session can be cancelled
    var canCancel: Bool {
        switch self {
        case .running, .paused:
            return true
        case .idle, .completed, .cancelled:
            return false
        }
    }
}
