import Foundation

/// Represents a completed focus session
struct FocusSession: Codable, Identifiable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let durationSeconds: Int
    let targetDurationSeconds: Int
    let label: String

    /// Initializer with default values for backward compatibility
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

    /// Whether the session met or exceeded the target duration
    var wasCompleted: Bool {
        targetDurationSeconds > 0 && durationSeconds >= targetDurationSeconds
    }

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

    // MARK: - Codable with default values for migration

    enum CodingKeys: String, CodingKey {
        case id, startTime, endTime, durationSeconds, targetDurationSeconds, label
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        startTime = try container.decode(Date.self, forKey: .startTime)
        endTime = try container.decode(Date.self, forKey: .endTime)
        durationSeconds = try container.decode(Int.self, forKey: .durationSeconds)
        // Provide defaults for new fields when decoding old data
        targetDurationSeconds = try container.decodeIfPresent(Int.self, forKey: .targetDurationSeconds) ?? 0
        label = try container.decodeIfPresent(String.self, forKey: .label) ?? "Focus"
    }
}

/// Statistics for sessions grouped by label
struct LabelStatistics {
    let label: String
    let sessionCount: Int
    let totalFocusTimeSeconds: Int
    let completedCount: Int
    let cancelledCount: Int

    var totalFocusTimeFormatted: String {
        let hours = totalFocusTimeSeconds / 3600
        let minutes = (totalFocusTimeSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var completionRate: Double {
        guard sessionCount > 0 else { return 0 }
        return Double(completedCount) / Double(sessionCount)
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
    let completedSessions: Int
    let cancelledSessions: Int
    let labelStatistics: [LabelStatistics]

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

    var completionRate: Double {
        guard totalSessions > 0 else { return 0 }
        return Double(completedSessions) / Double(totalSessions)
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
        thisWeekFocusTimeSeconds: 0,
        completedSessions: 0,
        cancelledSessions: 0,
        labelStatistics: []
    )
}
