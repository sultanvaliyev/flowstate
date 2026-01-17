import SwiftUI

/// A picker for selecting focus session duration with preset options
struct DurationPicker: View {
    /// Binding to the selected duration in minutes
    @Binding var selectedMinutes: Int

    /// Preset duration options in minutes
    static let presetDurations: [Int] = [15, 25, 30, 45, 60, 90, 120]

    /// UserDefaults key for persisting last used duration
    private static let lastDurationKey = "com.zonn.lastDuration"

    /// Text color
    var textColor: Color = .white

    /// Selected pill color
    var selectedColor: Color = Color.white.opacity(0.35)

    /// Unselected pill color
    var unselectedColor: Color = Color.white.opacity(0.15)

    var body: some View {
        VStack(spacing: 8) {
            // Duration label
            Text("Duration")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(textColor.opacity(0.8))

            // Preset buttons in a horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Self.presetDurations, id: \.self) { duration in
                        durationButton(for: duration)
                    }
                }
                .padding(.horizontal, 4)
            }

            // Stepper for fine-tuning
            HStack(spacing: 12) {
                Button(action: decrementDuration) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(textColor.opacity(0.8))
                }
                .buttonStyle(.plain)
                .disabled(selectedMinutes <= 5)

                Text("\(selectedMinutes) min")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(textColor)
                    .frame(minWidth: 70)

                Button(action: incrementDuration) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(textColor.opacity(0.8))
                }
                .buttonStyle(.plain)
                .disabled(selectedMinutes >= 180)
            }
            .padding(.top, 4)
        }
    }

    /// Creates a button for a preset duration
    private func durationButton(for duration: Int) -> some View {
        Button(action: {
            selectDuration(duration)
        }) {
            Text(formatDuration(duration))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(textColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(selectedMinutes == duration ? selectedColor : unselectedColor)
                )
                .overlay(
                    Capsule()
                        .stroke(
                            selectedMinutes == duration ? Color.white.opacity(0.5) : Color.clear,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }

    /// Format duration for display
    private func formatDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(mins)m"
        }
        return "\(minutes)m"
    }

    /// Select a duration and persist it
    private func selectDuration(_ duration: Int) {
        selectedMinutes = duration
        saveDuration(duration)
    }

    /// Increment duration by 5 minutes
    private func incrementDuration() {
        let newDuration = min(selectedMinutes + 5, 180)
        selectedMinutes = newDuration
        saveDuration(newDuration)
    }

    /// Decrement duration by 5 minutes
    private func decrementDuration() {
        let newDuration = max(selectedMinutes - 5, 5)
        selectedMinutes = newDuration
        saveDuration(newDuration)
    }

    /// Save duration to UserDefaults
    private func saveDuration(_ duration: Int) {
        UserDefaults.standard.set(duration, forKey: Self.lastDurationKey)
    }

    /// Load saved duration from UserDefaults
    static func loadSavedDuration() -> Int {
        let saved = UserDefaults.standard.integer(forKey: lastDurationKey)
        return saved > 0 ? saved : 25 // Default to 25 minutes (Pomodoro)
    }
}

#Preview("Duration Picker") {
    DurationPicker(selectedMinutes: .constant(25))
        .padding()
        .background(Color(red: 0.4, green: 0.65, blue: 0.55))
}

#Preview("Duration Picker - Long") {
    DurationPicker(selectedMinutes: .constant(90))
        .padding()
        .background(Color(red: 0.4, green: 0.65, blue: 0.55))
}
