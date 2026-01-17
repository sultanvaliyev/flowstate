import SwiftUI

/// The floating timer window content
struct TimerView: View {
    @ObservedObject var timerState: TimerState

    var body: some View {
        HStack(spacing: 12) {
            // Timer display
            Text(timerState.formattedTime)
                .font(.system(size: 28, weight: .medium, design: .monospaced))
                .foregroundColor(timerState.isRunning ? .primary : .secondary)

            // Play/Stop button
            Button(action: {
                timerState.toggleSession()
            }) {
                Image(systemName: timerState.isRunning ? "stop.fill" : "play.fill")
                    .font(.system(size: 18))
                    .foregroundColor(timerState.isRunning ? .red : .green)
            }
            .buttonStyle(.plain)
            .help(timerState.isRunning ? "Stop Session" : "Start Focus Session")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    TimerView(timerState: TimerState())
        .frame(width: 180, height: 80)
}
