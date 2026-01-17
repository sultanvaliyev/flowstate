import SwiftUI

/// A SwiftUI view that asynchronously loads and displays album artwork
/// with loading, success, and error states.
struct AlbumArtView: View {
    // MARK: - Properties

    let artworkURL: URL?
    var size: CGFloat = 60
    var cornerRadius: CGFloat = 8

    // MARK: - Body

    var body: some View {
        Group {
            if let url = artworkURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        loadingView
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                    case .failure:
                        placeholderView
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                placeholderView
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }

    // MARK: - Subviews

    /// Loading state with spinner on semi-transparent background
    private var loadingView: some View {
        ZStack {
            Color.black.opacity(0.3)
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
        }
    }

    /// Placeholder for error state or missing URL
    private var placeholderView: some View {
        ZStack {
            // Subtle gradient background
            LinearGradient(
                colors: [
                    Color.white.opacity(0.15),
                    Color.white.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Music note icon
            Image(systemName: "music.note")
                .font(.system(size: size * 0.4))
                .foregroundStyle(Color.white.opacity(0.5))
        }
    }
}

// MARK: - Previews

#Preview("With Valid URL") {
    AlbumArtView(
        artworkURL: URL(string: "https://i.scdn.co/image/ab67616d0000b273e8b066f70c206551210d902b")
    )
    .padding()
    .background(AppColors.forestGreen)
}

#Preview("No URL (Placeholder)") {
    AlbumArtView(artworkURL: nil)
        .padding()
        .background(AppColors.forestGreen)
}

#Preview("Small Size (40)") {
    AlbumArtView(
        artworkURL: URL(string: "https://i.scdn.co/image/ab67616d0000b273e8b066f70c206551210d902b"),
        size: 40
    )
    .padding()
    .background(AppColors.forestGreen)
}

#Preview("Large Size (120)") {
    AlbumArtView(
        artworkURL: URL(string: "https://i.scdn.co/image/ab67616d0000b273e8b066f70c206551210d902b"),
        size: 120,
        cornerRadius: 12
    )
    .padding()
    .background(AppColors.forestGreen)
}
