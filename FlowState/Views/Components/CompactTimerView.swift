import SwiftUI

/// A compact horizontal timer view for use when vertical space is limited.
/// Displays the remaining time and a single control button in a horizontal layout.
struct CompactTimerView: View {
    @ObservedObject var timerState: FocusTimerState

    var body: some View {
        HStack(spacing: 12) {
            // Timer display
            Text(timerState.formattedRemaining)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textOnGreen)
                .monospacedDigit()

            // Control button
            Button(action: handleButtonTap) {
                Image(systemName: buttonIconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textOnGreen)
                    .frame(width: 36, height: 36)
                    .background(AppColors.buttonGreen)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Private Helpers

    /// Determines the appropriate SF Symbol based on timer phase
    private var buttonIconName: String {
        switch timerState.timerPhase {
        case .idle, .completed, .cancelled:
            return "play.fill"
        case .running:
            return "pause.fill"
        case .paused:
            return "play.fill"
        }
    }

    /// Handles the control button tap based on current timer phase
    private func handleButtonTap() {
        switch timerState.timerPhase {
        case .idle, .completed, .cancelled:
            timerState.start()
        case .running:
            timerState.pause()
        case .paused:
            timerState.resume()
        }
    }
}

#Preview {
    ZStack {
        AppColors.forestGreen
            .ignoresSafeArea()

        VStack(spacing: 20) {
            CompactTimerView(timerState: FocusTimerState())
        }
    }
    .frame(width: 200, height: 100)
}
