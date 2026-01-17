import Foundation

/// Manages calculation of focus session statistics using SessionStore
@MainActor
class StatisticsManager {
    static let shared = StatisticsManager()

    private let sessionStore = SessionStore.shared

    private init() {}

    // MARK: - Session Recording

    func recordSession(_ session: FocusSession) {
        sessionStore.save(session)
    }

    // MARK: - Session Retrieval

    func getAllSessions() -> [FocusSession] {
        sessionStore.fetchAll()
    }

    func getSessionsForToday() -> [FocusSession] {
        sessionStore.fetchToday()
    }

    func getSessionsForThisWeek() -> [FocusSession] {
        sessionStore.fetchThisWeek()
    }

    func getSessionsByLabel(_ label: String) -> [FocusSession] {
        sessionStore.fetchByLabel(label)
    }

    // MARK: - Statistics Calculation

    func getStatistics() -> SessionStatistics {
        let allSessions = getAllSessions()
        let todaySessions = getSessionsForToday()
        let weekSessions = getSessionsForThisWeek()

        let totalSeconds = allSessions.reduce(0) { $0 + $1.durationSeconds }
        let todaySeconds = todaySessions.reduce(0) { $0 + $1.durationSeconds }
        let weekSeconds = weekSessions.reduce(0) { $0 + $1.durationSeconds }

        let averageSeconds = allSessions.isEmpty ? 0 : totalSeconds / allSessions.count

        // Calculate completed vs cancelled sessions
        let completedSessions = allSessions.filter { $0.wasCompleted }.count
        let cancelledSessions = allSessions.count - completedSessions

        // Calculate label-based statistics
        let labelStats = calculateLabelStatistics(allSessions)

        return SessionStatistics(
            totalSessions: allSessions.count,
            totalFocusTimeSeconds: totalSeconds,
            averageSessionSeconds: averageSeconds,
            todaySessions: todaySessions.count,
            todayFocusTimeSeconds: todaySeconds,
            thisWeekSessions: weekSessions.count,
            thisWeekFocusTimeSeconds: weekSeconds,
            completedSessions: completedSessions,
            cancelledSessions: cancelledSessions,
            labelStatistics: labelStats
        )
    }

    /// Calculate statistics grouped by label
    private func calculateLabelStatistics(_ sessions: [FocusSession]) -> [LabelStatistics] {
        // Group sessions by label
        let grouped = Dictionary(grouping: sessions) { $0.label }

        return grouped.map { label, labelSessions in
            let totalSeconds = labelSessions.reduce(0) { $0 + $1.durationSeconds }
            let completedCount = labelSessions.filter { $0.wasCompleted }.count
            let cancelledCount = labelSessions.count - completedCount

            return LabelStatistics(
                label: label,
                sessionCount: labelSessions.count,
                totalFocusTimeSeconds: totalSeconds,
                completedCount: completedCount,
                cancelledCount: cancelledCount
            )
        }.sorted { $0.sessionCount > $1.sessionCount }
    }

    /// Get statistics for a specific time period
    func getStatisticsForPeriod(from startDate: Date, to endDate: Date) -> SessionStatistics {
        let periodSessions = sessionStore.fetchSessionsInRange(from: startDate, to: endDate)

        let totalSeconds = periodSessions.reduce(0) { $0 + $1.durationSeconds }
        let averageSeconds = periodSessions.isEmpty ? 0 : totalSeconds / periodSessions.count
        let completedSessions = periodSessions.filter { $0.wasCompleted }.count
        let cancelledSessions = periodSessions.count - completedSessions
        let labelStats = calculateLabelStatistics(periodSessions)

        return SessionStatistics(
            totalSessions: periodSessions.count,
            totalFocusTimeSeconds: totalSeconds,
            averageSessionSeconds: averageSeconds,
            todaySessions: 0,
            todayFocusTimeSeconds: 0,
            thisWeekSessions: 0,
            thisWeekFocusTimeSeconds: 0,
            completedSessions: completedSessions,
            cancelledSessions: cancelledSessions,
            labelStatistics: labelStats
        )
    }

    /// Get completion rate for all sessions
    func getCompletionRate() -> Double {
        let allSessions = getAllSessions()
        guard !allSessions.isEmpty else { return 0 }

        let completedCount = allSessions.filter { $0.wasCompleted }.count
        return Double(completedCount) / Double(allSessions.count)
    }

    /// Get all unique session labels
    func getAllLabels() -> [String] {
        sessionStore.fetchAllLabels()
    }

    // MARK: - Data Management

    func clearAllData() {
        sessionStore.deleteAll()
    }

    func deleteSession(_ session: FocusSession) {
        sessionStore.delete(session)
    }

    func deleteSession(id: UUID) {
        sessionStore.delete(id: id)
    }
}
