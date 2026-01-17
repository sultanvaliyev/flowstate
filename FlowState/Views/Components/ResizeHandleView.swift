import SwiftUI

/// A subtle resize handle indicator for the bottom-right corner of resizable windows
struct ResizeHandleView: View {
    var body: some View {
        // Three diagonal lines indicating resize capability
        ZStack {
            ForEach(0..<3) { index in
                Rectangle()
                    .fill(Color.primary.opacity(0.3))
                    .frame(width: 1, height: CGFloat(4 + index * 4))
                    .offset(x: CGFloat(index * 3), y: CGFloat(-index * 3))
            }
        }
        .frame(width: 12, height: 12)
        .rotationEffect(.degrees(-45))
    }
}

#Preview {
    ResizeHandleView()
        .padding()
        .background(Color.gray.opacity(0.2))
}
