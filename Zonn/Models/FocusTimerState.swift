import Foundation
import Combine

/// Observable state for the countdown focus timer
@MainActor
class FocusTimerState: ObservableObject {

    // MARK: - Constants

    /// Maximum allowed duration: 120 minutes (7200 seconds)
    static let maxDurationSeconds: Int = 7200

    // MARK: - Published Properties

    /// Target duration for the focus session in seconds
    @Published var targetDurationSeconds: Int = 1500 // Default 25 minutes

    /// Remaining seconds in the current session
    @Published var remainingSeconds: Int = 1500

    /// Optional label for the current session
    @Published var sessionLabel: String = ""

    /// Current phase of the timer
    @Published var timerPhase: TimerPhase = .idle

    // MARK: - Private Properties

    private var timerCancellable: AnyCancellable?
    private var sessionStartTime: Date?
    private let statisticsManager = StatisticsManager.shared

    // MARK: - Computed Properties

    /// Progress from 0.0 (just started) to 1.0 (completed)
    var progress: Double {
        // Explicit completion state - guarantees 1.0 when timer is done
        if timerPhase == .completed || remainingSeconds <= 0 {
            return 1.0
        }

        guard targetDurationSeconds > 0 else { return 0.0 }

        let elapsed = targetDurationSeconds - remainingSeconds
        return min(1.0, max(0.0, Double(elapsed) / Double(targetDurationSeconds)))
    }

    /// Formatted remaining time as MM:SS
    var formattedRemaining: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Tree emoji based on progress
    var treeEmoji: String {
        switch progress {
        case 0.0..<0.33:
            return "\u{1F331}" // seedling
        case 0.33..<0.66:
            return "\u{1F33F}" // herb
        case 0.66..<0.9:
            return "\u{1F332}" // evergreen tree
        default:
            return "\u{1F333}" // deciduous tree
        }
    }

    /// Motivational text based on current phase and progress
    var motivationalText: String {
        MotivationalTextProvider.message(for: timerPhase, progress: progress)
    }

    // MARK: - Timer Control Methods

    /// Starts a new focus session with the current target duration
    func start() {
        guard timerPhase.canStart else { return }
        guard targetDurationSeconds > 0 && targetDurationSeconds <= Self.maxDurationSeconds else { return }

        remainingSeconds = targetDurationSeconds
        sessionStartTime = Date()
        timerPhase = .running
        startTimer()
    }

    /// Pauses the current session
    func pause() {
        guard timerPhase == .running else { return }

        timerCancellable?.cancel()
        timerCancellable = nil
        timerPhase = .paused
    }

    /// Resumes a paused session
    func resume() {
        guard timerPhase == .paused else { return }

        timerPhase = .running
        startTimer()
    }

    /// Cancels the current session
    func cancel() {
        guard timerPhase.canCancel else { return }

        timerCancellable?.cancel()
        timerCancellable = nil
        timerPhase = .cancelled

        // Record partial session if any time elapsed
        recordSession()
        resetAfterEnd()

        // Reset display to 00:00 after cancellation
        remainingSeconds = 0
    }

    /// Marks the session as completed (called when timer reaches zero)
    func complete() {
        guard timerPhase == .running || timerPhase == .paused else { return }

        timerCancellable?.cancel()
        timerCancellable = nil
        remainingSeconds = 0
        timerPhase = .completed

        // Record the completed session
        recordSession()

        // Show system notification for session completion
        NotificationManager.shared.showSessionCompletionNotification(
            duration: targetDurationSeconds,
            label: sessionLabel.isEmpty ? "Focus" : sessionLabel,
            wasCompleted: true
        )

        // Play completion sound
        SoundManager.shared.playCompletionSound()
    }

    // MARK: - Private Methods

    private func startTimer() {
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func tick() {
        guard timerPhase == .running else { return }

        if remainingSeconds > 0 {
            remainingSeconds -= 1
        }

        if remainingSeconds == 0 {
            complete()
        }
    }

    private func recordSession() {
        guard let startTime = sessionStartTime else { return }

        let elapsed = targetDurationSeconds - remainingSeconds
        guard elapsed > 0 else { return }

        let session = FocusSession(
            id: UUID(),
            startTime: startTime,
            endTime: Date(),
            durationSeconds: elapsed,
            targetDurationSeconds: targetDurationSeconds,
            label: sessionLabel.isEmpty ? "Focus" : sessionLabel
        )
        statisticsManager.recordSession(session)
    }

    private func resetAfterEnd() {
        sessionStartTime = nil
        // Keep remainingSeconds at current value for display until next start
    }

    /// Resets the timer to idle state (for starting a fresh session)
    func reset() {
        timerCancellable?.cancel()
        timerCancellable = nil
        remainingSeconds = targetDurationSeconds
        sessionStartTime = nil
        timerPhase = .idle
    }

    /// Sets a new target duration and resets the timer
    func setDuration(_ seconds: Int) {
        let clampedDuration = min(max(0, seconds), Self.maxDurationSeconds)
        targetDurationSeconds = clampedDuration
        if timerPhase == .idle {
            remainingSeconds = clampedDuration
        }
    }
}
