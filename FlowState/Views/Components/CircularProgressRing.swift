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

            // Progress ring
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    ringGradient,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)

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
    }
}

#Preview("Progress Ring - 0%") {
    CircularProgressRing(progress: 0.0)
        .padding()
        .background(Color(red: 0.4, green: 0.65, blue: 0.55))
}

#Preview("Progress Ring - 50%") {
    CircularProgressRing(progress: 0.5)
        .padding()
        .background(Color(red: 0.4, green: 0.65, blue: 0.55))
}

#Preview("Progress Ring - 100%") {
    CircularProgressRing(progress: 1.0)
        .padding()
        .background(Color(red: 0.4, green: 0.65, blue: 0.55))
}
