import Foundation

/// Represents a completed focus session
struct FocusSession: Codable, Identifiable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let durationSeconds: Int

    var durationMinutes: Double {
        Double(durationSeconds) / 60.0
    }

    var formattedDuration: String {
        let hours = durationSeconds / 3600
        let minutes = (durationSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

/// Aggregated statistics for display
struct SessionStatistics {
    let totalSessions: Int
    let totalFocusTimeSeconds: Int
    let averageSessionSeconds: Int
    let todaySessions: Int
    let todayFocusTimeSeconds: Int
    let thisWeekSessions: Int
    let thisWeekFocusTimeSeconds: Int

    var totalFocusTimeFormatted: String {
        formatDuration(totalFocusTimeSeconds)
    }

    var averageSessionFormatted: String {
        formatDuration(averageSessionSeconds)
    }

    var todayFocusTimeFormatted: String {
        formatDuration(todayFocusTimeSeconds)
    }

    var thisWeekFocusTimeFormatted: String {
        formatDuration(thisWeekFocusTimeSeconds)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    static let empty = SessionStatistics(
        totalSessions: 0,
        totalFocusTimeSeconds: 0,
        averageSessionSeconds: 0,
        todaySessions: 0,
        todayFocusTimeSeconds: 0,
        thisWeekSessions: 0,
        thisWeekFocusTimeSeconds: 0
    )
}
