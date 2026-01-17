import Foundation
import CoreGraphics

enum LayoutSizeClass: Equatable {
    case compact
    case regular

    static let compactHeightThreshold: CGFloat = 400

    static func from(size: CGSize) -> LayoutSizeClass {
        if size.height < compactHeightThreshold {
            return .compact
        }
        return .regular
    }

    var isCompact: Bool {
        self == .compact
    }
}
