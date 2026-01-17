import Foundation

/// Provides motivational text based on timer phase and progress
struct MotivationalTextProvider {

    // MARK: - Phase-Based Messages

    /// Returns motivational text for the idle phase
    static func idleMessage() -> String {
        "Start planting today!"
    }

    /// Returns a random motivational message for the running phase
    static func runningMessage() -> String {
        let messages = [
            "Hang in there!",
            "Stay focused!",
            "You're doing great!"
        ]
        return messages.randomElement() ?? messages[0]
    }

    /// Returns a random completion message
    static func completedMessage() -> String {
        let messages = [
            "Great job!",
            "Tree planted!"
        ]
        return messages.randomElement() ?? messages[0]
    }

    /// Returns message for cancelled sessions
    static func cancelledMessage() -> String {
        "Maybe next time!"
    }

    /// Returns message for paused state
    static func pausedMessage() -> String {
        "Take a breather..."
    }

    // MARK: - Progress-Based Encouragement

    /// Returns encouragement message based on progress percentage (0.0 to 1.0)
    static func progressEncouragement(progress: Double) -> String? {
        switch progress {
        case 0.24...0.26:
            return "Quarter way there!"
        case 0.49...0.51:
            return "Halfway done!"
        case 0.74...0.76:
            return "Almost there!"
        case 0.89...0.91:
            return "Final stretch!"
        default:
            return nil
        }
    }

    // MARK: - Combined Message Provider

    /// Returns the appropriate motivational text based on phase and progress
    static func message(for phase: TimerPhase, progress: Double = 0.0) -> String {
        // Check for progress milestones first when running
        if phase == .running, let progressMessage = progressEncouragement(progress: progress) {
            return progressMessage
        }

        switch phase {
        case .idle:
            return idleMessage()
        case .running:
            return runningMessage()
        case .paused:
            return pausedMessage()
        case .completed:
            return completedMessage()
        case .cancelled:
            return cancelledMessage()
        }
    }
}
