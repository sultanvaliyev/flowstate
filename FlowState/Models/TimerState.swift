import Foundation
import Combine

/// Observable state for the focus timer
class TimerState: ObservableObject {
    @Published var isRunning: Bool = false
    @Published var elapsedSeconds: Int = 0
    @Published var sessionStartTime: Date?

    private var timer: Timer?
    private let statisticsManager = StatisticsManager.shared

    var formattedTime: String {
        let hours = elapsedSeconds / 3600
        let minutes = (elapsedSeconds % 3600) / 60
        let seconds = elapsedSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    func startSession() {
        guard !isRunning else { return }

        isRunning = true
        elapsedSeconds = 0
        sessionStartTime = Date()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.elapsedSeconds += 1
            }
        }

        // Ensure timer runs even when menu is open
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stopSession() {
        guard isRunning else { return }

        timer?.invalidate()
        timer = nil
        isRunning = false

        // Record the completed session
        if let startTime = sessionStartTime {
            let session = FocusSession(
                id: UUID(),
                startTime: startTime,
                endTime: Date(),
                durationSeconds: elapsedSeconds
            )
            statisticsManager.recordSession(session)
        }

        sessionStartTime = nil
    }

    func toggleSession() {
        if isRunning {
            stopSession()
        } else {
            startSession()
        }
    }
}
