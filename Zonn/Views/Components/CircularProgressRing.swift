import SwiftUI

/// A circular progress ring with smooth animation and gradient styling
struct CircularProgressRing: View {
    /// Progress value from 0.0 to 1.0
    var progress: Double

    /// Primary color for the ring (used in gradient)
    var ringColor: Color = Color(red: 0.2, green: 0.7, blue: 0.4)

    /// Width of the ring stroke
    var lineWidth: CGFloat = 12

    /// Overall size of the ring
    var size: CGFloat = 200

    /// Gradient for the progress ring
    private var ringGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [
                ringColor.opacity(0.8),
                ringColor,
                Color(red: 0.3, green: 0.8, blue: 0.5)
            ]),
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }

    /// Lighter color for the background track
    private var trackColor: Color {
        ringColor.opacity(0.2)
    }

    /// Clamped progress value ensuring clean 0.0 and 1.0 boundaries
    private var clampedProgress: Double {
        if progress >= 0.999 { return 1.0 }
        if progress <= 0.001 { return 0.0 }
        return progress
    }

    var body: some View {
        ZStack {
            // Background track circle
            Circle()
                .stroke(
                    trackColor,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )

            // Progress ring - use full circle when complete to avoid gap from round lineCap
            if clampedProgress >= 1.0 {
                Circle()
                    .stroke(
                        ringGradient,
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            lineCap: .round
                        )
                    )
            } else {
                Circle()
                    .trim(from: 0, to: CGFloat(clampedProgress))
                    .stroke(
                        ringGradient,
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: clampedProgress)
            }

            // Inner shadow effect for depth
            Circle()
                .stroke(
                    Color.black.opacity(0.1),
                    style: StrokeStyle(
                        lineWidth: lineWidth / 2,
                        lineCap: .round
                    )
                )
                .blur(radius: 4)
                .offset(x: 2, y: 2)
                .mask(
                    Circle()
                        .stroke(
                            Color.white,
                            style: StrokeStyle(
                                lineWidth: lineWidth,
                                lineCap: .round
                            )
                        )
                )
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Focus progress")
        .accessibilityValue("\(Int(progress * 100)) percent complete")
    }
}

// MARK: - Previews

#Preview("All Progress States") {
    let backgroundColor = Color(red: 0.4, green: 0.65, blue: 0.55)

    ScrollView {
        VStack(spacing: 24) {
            Text("Progress Ring States")
                .font(.headline)
                .foregroundStyle(.white)

            // First row: 0%, 25%, 50%
            HStack(spacing: 20) {
                ProgressPreviewItem(progress: 0.0, label: "0%\n(Empty)")
                ProgressPreviewItem(progress: 0.25, label: "25%")
                ProgressPreviewItem(progress: 0.5, label: "50%")
            }

            // Second row: 75%, 99.9%, 100%
            HStack(spacing: 20) {
                ProgressPreviewItem(progress: 0.75, label: "75%")
                ProgressPreviewItem(progress: 0.999, label: "99.9%\n(Edge)")
                ProgressPreviewItem(progress: 1.0, label: "100%\n(Full)")
            }
        }
        .padding()
    }
    .frame(width: 400, height: 450)
    .background(backgroundColor)
}

#Preview("Individual - Empty (0%)") {
    CircularProgressRing(progress: 0.0)
        .padding()
        .background(Color(red: 0.4, green: 0.65, blue: 0.55))
}

#Preview("Individual - Quarter (25%)") {
    CircularProgressRing(progress: 0.25)
        .padding()
        .background(Color(red: 0.4, green: 0.65, blue: 0.55))
}

#Preview("Individual - Half (50%)") {
    CircularProgressRing(progress: 0.5)
        .padding()
        .background(Color(red: 0.4, green: 0.65, blue: 0.55))
}

#Preview("Individual - Three Quarters (75%)") {
    CircularProgressRing(progress: 0.75)
        .padding()
        .background(Color(red: 0.4, green: 0.65, blue: 0.55))
}

#Preview("Individual - Near Complete (99.9%)") {
    CircularProgressRing(progress: 0.999)
        .padding()
        .background(Color(red: 0.4, green: 0.65, blue: 0.55))
}

#Preview("Individual - Complete (100%)") {
    CircularProgressRing(progress: 1.0)
        .padding()
        .background(Color(red: 0.4, green: 0.65, blue: 0.55))
}

// MARK: - Preview Helper

/// Helper view for displaying a progress ring with a label in previews
private struct ProgressPreviewItem: View {
    let progress: Double
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            CircularProgressRing(
                progress: progress,
                lineWidth: 8,
                size: 100
            )

            Text(label)
                .font(.caption)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
    }
}
