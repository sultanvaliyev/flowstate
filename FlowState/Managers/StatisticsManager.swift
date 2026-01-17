import Foundation

/// Manages persistence and calculation of focus session statistics
class StatisticsManager {
    static let shared = StatisticsManager()

    private let sessionsKey = "com.flowstate.sessions"
    private let userDefaults = UserDefaults.standard

    private init() {}

    // MARK: - Session Recording

    func recordSession(_ session: FocusSession) {
        var sessions = getAllSessions()
        sessions.append(session)
        saveSessions(sessions)
    }

    // MARK: - Session Retrieval

    func getAllSessions() -> [FocusSession] {
        guard let data = userDefaults.data(forKey: sessionsKey),
              let sessions = try? JSONDecoder().decode([FocusSession].self, from: data) else {
            return []
        }
        return sessions
    }

    func getSessionsForToday() -> [FocusSession] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return getAllSessions().filter { session in
            calendar.isDate(session.startTime, inSameDayAs: today)
        }
    }

    func getSessionsForThisWeek() -> [FocusSession] {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else {
            return []
        }

        return getAllSessions().filter { session in
            session.startTime >= weekStart
        }
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

        return SessionStatistics(
            totalSessions: allSessions.count,
            totalFocusTimeSeconds: totalSeconds,
            averageSessionSeconds: averageSeconds,
            todaySessions: todaySessions.count,
            todayFocusTimeSeconds: todaySeconds,
            thisWeekSessions: weekSessions.count,
            thisWeekFocusTimeSeconds: weekSeconds
        )
    }

    // MARK: - Data Management

    func clearAllData() {
        userDefaults.removeObject(forKey: sessionsKey)
    }

    private func saveSessions(_ sessions: [FocusSession]) {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        userDefaults.set(data, forKey: sessionsKey)
    }
}
