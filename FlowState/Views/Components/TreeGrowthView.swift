import SwiftUI

/// A view that shows tree emoji based on progress with animated transitions
struct TreeGrowthView: View {
    /// Progress value from 0.0 to 1.0
    var progress: Double

    /// Size of the emoji display
    var size: CGFloat = 60

    /// The current tree stage based on progress
    private var treeEmoji: String {
        switch progress {
        case 0..<0.33:
            return "\u{1F331}" // Seedling
        case 0.33..<0.66:
            return "\u{1F33F}" // Herb/Leaves
        case 0.66..<0.90:
            return "\u{1F332}" // Evergreen Tree
        default:
            return "\u{1F333}" // Deciduous Tree
        }
    }

    /// Scale factor for animation effect
    @State private var scale: CGFloat = 1.0

    /// Track the previous emoji to detect changes
    @State private var previousEmoji: String = ""

    var body: some View {
        Text(treeEmoji)
            .font(.system(size: size))
            .scaleEffect(scale)
            .onChange(of: treeEmoji) { oldValue, newValue in
                if oldValue != newValue {
                    animateTransition()
                }
            }
            .onAppear {
                previousEmoji = treeEmoji
            }
    }

    /// Animate a subtle scale bounce when emoji changes
    private func animateTransition() {
        withAnimation(.easeOut(duration: 0.15)) {
            scale = 1.3
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                scale = 1.0
            }
        }
    }
}

#Preview("Seedling - 0%") {
    TreeGrowthView(progress: 0.1)
        .padding()
        .background(Color(red: 0.4, green: 0.65, blue: 0.55))
}

#Preview("Leaves - 50%") {
    TreeGrowthView(progress: 0.5)
        .padding()
        .background(Color(red: 0.4, green: 0.65, blue: 0.55))
}

#Preview("Evergreen - 75%") {
    TreeGrowthView(progress: 0.75)
        .padding()
        .background(Color(red: 0.4, green: 0.65, blue: 0.55))
}

#Preview("Full Tree - 100%") {
    TreeGrowthView(progress: 1.0)
        .padding()
        .background(Color(red: 0.4, green: 0.65, blue: 0.55))
}
