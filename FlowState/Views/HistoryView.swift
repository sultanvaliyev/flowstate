import SwiftUI

/// A view displaying the history of completed focus sessions
/// Groups sessions by date: Today, Yesterday, This Week, Earlier
struct HistoryView: View {
    /// Grouped sessions for display
    @State private var groupedSessions: [SessionGroup] = []

    /// Whether the view is loading
    @State private var isLoading: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Content
            if isLoading {
                loadingView
            } else if groupedSessions.isEmpty {
                emptyStateView
            } else {
                sessionListView
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            loadSessions()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text("Session History")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)

            Spacer()

            // Total sessions count
            Text("\(totalSessionCount) sessions")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(0.8)
            Text("Loading...")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.top, 8)
            Spacer()
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "leaf")
                .font(.system(size: 40))
                .foregroundColor(AppColors.forestGreen.opacity(0.5))

            Text("No sessions yet")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)

            Text("Complete a focus session\nto see it here")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }

    // MARK: - Session List

    private var sessionListView: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(groupedSessions) { group in
                    Section {
                        ForEach(group.sessions) { session in
                            SessionRowView(session: session)
                            Divider()
                                .padding(.leading, 48)
                        }
                    } header: {
                        sectionHeader(for: group)
                    }
                }
            }
        }
    }

    private func sectionHeader(for group: SessionGroup) -> some View {
        HStack {
            Text(group.title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            Spacer()

            Text(group.totalDurationFormatted)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.95))
    }

    // MARK: - Computed Properties

    private var totalSessionCount: Int {
        groupedSessions.reduce(0) { $0 + $1.sessions.count }
    }

    // MARK: - Data Loading

    private func loadSessions() {
        isLoading = true

        // Load sessions on background queue to avoid UI blocking
        DispatchQueue.main.async {
            let allSessions = StatisticsManager.shared.getAllSessions()
            self.groupedSessions = Self.groupSessionsByDate(allSessions)
            self.isLoading = false
        }
    }

    /// Groups sessions by relative date
    static func groupSessionsByDate(_ sessions: [FocusSession]) -> [SessionGroup] {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        guard let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday),
              let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return []
        }

        var todaySessions: [FocusSession] = []
        var yesterdaySessions: [FocusSession] = []
        var thisWeekSessions: [FocusSession] = []
        var earlierSessions: [FocusSession] = []

        for session in sessions {
            let sessionDate = session.startTime

            if sessionDate >= startOfToday {
                todaySessions.append(session)
            } else if sessionDate >= startOfYesterday {
                yesterdaySessions.append(session)
            } else if sessionDate >= startOfWeek {
                thisWeekSessions.append(session)
            } else {
                earlierSessions.append(session)
            }
        }

        var groups: [SessionGroup] = []

        if !todaySessions.isEmpty {
            groups.append(SessionGroup(
                id: "today",
                title: "Today",
                sessions: todaySessions.sorted { $0.startTime > $1.startTime }
            ))
        }

        if !yesterdaySessions.isEmpty {
            groups.append(SessionGroup(
                id: "yesterday",
                title: "Yesterday",
                sessions: yesterdaySessions.sorted { $0.startTime > $1.startTime }
            ))
        }

        if !thisWeekSessions.isEmpty {
            groups.append(SessionGroup(
                id: "thisWeek",
                title: "This Week",
                sessions: thisWeekSessions.sorted { $0.startTime > $1.startTime }
            ))
        }

        if !earlierSessions.isEmpty {
            groups.append(SessionGroup(
                id: "earlier",
                title: "Earlier",
                sessions: earlierSessions.sorted { $0.startTime > $1.startTime }
            ))
        }

        return groups
    }
}

// MARK: - Session Group Model

struct SessionGroup: Identifiable {
    let id: String
    let title: String
    let sessions: [FocusSession]

    var totalDurationSeconds: Int {
        sessions.reduce(0) { $0 + $1.durationSeconds }
    }

    var totalDurationFormatted: String {
        let hours = totalDurationSeconds / 3600
        let minutes = (totalDurationSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Session Row View

struct SessionRowView: View {
    let session: FocusSession

    /// Tree emoji based on session completion
    private var treeEmoji: String {
        if session.wasCompleted {
            return "\u{1F333}" // Full tree for completed
        } else {
            // Use progress-based emoji for incomplete sessions
            let progress = session.targetDurationSeconds > 0
                ? Double(session.durationSeconds) / Double(session.targetDurationSeconds)
                : 0.5

            switch progress {
            case 0..<0.33:
                return "\u{1F331}" // Seedling
            case 0.33..<0.66:
                return "\u{1F33F}" // Herb
            default:
                return "\u{1F332}" // Evergreen
            }
        }
    }

    /// Formatted time string (e.g., "2:30 PM")
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: session.startTime)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Tree emoji
            Text(treeEmoji)
                .font(.system(size: 24))
                .frame(width: 32)

            // Session details
            VStack(alignment: .leading, spacing: 2) {
                Text(session.label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(timeString)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Duration
            VStack(alignment: .trailing, spacing: 2) {
                Text(session.formattedDuration)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)

                if session.wasCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.success)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

// MARK: - Previews

#Preview("History View - With Sessions") {
    HistoryView()
        .frame(width: 280, height: 360)
}

#Preview("Session Row - Completed") {
    SessionRowView(session: FocusSession(
        startTime: Date(),
        endTime: Date(),
        durationSeconds: 1500,
        targetDurationSeconds: 1500,
        label: "Deep Work"
    ))
    .frame(width: 280)
}

#Preview("Session Row - Incomplete") {
    SessionRowView(session: FocusSession(
        startTime: Date(),
        endTime: Date(),
        durationSeconds: 600,
        targetDurationSeconds: 1500,
        label: "Study"
    ))
    .frame(width: 280)
}
