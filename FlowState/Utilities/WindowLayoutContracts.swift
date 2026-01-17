import Foundation
import CoreGraphics

// MARK: - Window Size Constants

enum WindowSizeConstants {
    static let expandedSize = CGSize(width: 420, height: 750)
    static let compactSize = CGSize(width: 280, height: 400)
    static let minimumSize = CGSize(width: 280, height: 360)
    static let maximumSize = CGSize(width: 450, height: 800)
    static let compactRingSize: CGFloat = 180
    static let expandedRingSize: CGFloat = 200
}

// MARK: - Window Layout Mode

enum WindowLayoutMode: String {
    case expanded
    case compact

    var size: CGSize {
        switch self {
        case .expanded: return WindowSizeConstants.expandedSize
        case .compact: return WindowSizeConstants.compactSize
        }
    }

    mutating func toggle() {
        self = (self == .expanded) ? .compact : .expanded
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let windowLayoutModeDidChange = Notification.Name("windowLayoutModeDidChange")
}
