import AppKit
import SwiftUI

/// NSPanel wrapper for the Focus View window
/// Provides a floating, always-on-top panel for the focus timer interface
class FocusPanel: NSPanel {
    /// Default size for the focus panel (maximum size to show all content)
    static let defaultSize = NSSize(width: 400, height: 700)

    /// Create a new focus panel with optional custom position
    /// - Parameters:
    ///   - contentView: The SwiftUI view to display in the panel
    ///   - position: Optional custom position (defaults to center-right of screen)
    convenience init<Content: View>(contentView: Content, position: NSPoint? = nil) {
        // Calculate window position
        // Use main screen, fall back to first available screen, or use a default frame if no screens available
        let screenFrame: NSRect
        if let screen = NSScreen.main ?? NSScreen.screens.first {
            screenFrame = screen.visibleFrame
        } else {
            // Fallback to a reasonable default if no screens are available (extremely rare edge case)
            screenFrame = NSRect(x: 0, y: 0, width: 1920, height: 1080)
        }

        let windowPosition: NSPoint
        if let customPosition = position {
            windowPosition = customPosition
        } else {
            // Default position: center-right of screen with padding
            let padding: CGFloat = 40
            windowPosition = NSPoint(
                x: screenFrame.maxX - Self.defaultSize.width - padding,
                y: screenFrame.midY - Self.defaultSize.height / 2
            )
        }

        let windowRect = NSRect(
            origin: windowPosition,
            size: Self.defaultSize
        )

        self.init(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        configurePanel()

        // Set min/max size constraints for resizing (allows compact mode)
        minSize = NSSize(width: 220, height: 280)
        maxSize = NSSize(width: 400, height: 700)

        // Set the SwiftUI content
        let hostingView = NSHostingView(rootView: contentView)
        self.contentView = hostingView
    }

    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
    }

    /// Configure the panel for floating behavior
    private func configurePanel() {
        // Floating level - stays on top of regular windows
        level = .floating

        // Can appear on all spaces and works with fullscreen apps
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Window behavior
        isMovableByWindowBackground = true
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true

        // Title bar configuration (hidden for borderless look)
        titlebarAppearsTransparent = true
        titleVisibility = .hidden

        // Show standard window buttons (close, minimize)
        // Zoom button hidden since we use min/max size constraints
        standardWindowButton(.zoomButton)?.isHidden = true

        // Allow the panel to become key for keyboard input
        self.becomesKeyOnlyIfNeeded = false
    }

    /// Show the panel with animation
    func showAnimated() {
        alphaValue = 0
        orderFront(nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().alphaValue = 1
        }
    }

    /// Hide the panel with animation
    func hideAnimated(completion: (() -> Void)? = nil) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            animator().alphaValue = 0
        }, completionHandler: {
            self.orderOut(nil)
            self.alphaValue = 1
            completion?()
        })
    }

    /// Toggle visibility with animation
    func toggleVisibility() {
        if isVisible {
            hideAnimated()
        } else {
            showAnimated()
        }
    }

    /// Position the panel at a specific screen location
    func positionAt(_ location: PanelLocation) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let padding: CGFloat = 40

        let newOrigin: NSPoint
        switch location {
        case .topLeft:
            newOrigin = NSPoint(
                x: screenFrame.minX + padding,
                y: screenFrame.maxY - frame.height - padding
            )
        case .topRight:
            newOrigin = NSPoint(
                x: screenFrame.maxX - frame.width - padding,
                y: screenFrame.maxY - frame.height - padding
            )
        case .bottomLeft:
            newOrigin = NSPoint(
                x: screenFrame.minX + padding,
                y: screenFrame.minY + padding
            )
        case .bottomRight:
            newOrigin = NSPoint(
                x: screenFrame.maxX - frame.width - padding,
                y: screenFrame.minY + padding
            )
        case .center:
            newOrigin = NSPoint(
                x: screenFrame.midX - frame.width / 2,
                y: screenFrame.midY - frame.height / 2
            )
        case .centerRight:
            newOrigin = NSPoint(
                x: screenFrame.maxX - frame.width - padding,
                y: screenFrame.midY - frame.height / 2
            )
        case .centerLeft:
            newOrigin = NSPoint(
                x: screenFrame.minX + padding,
                y: screenFrame.midY - frame.height / 2
            )
        }

        setFrameOrigin(newOrigin)
    }

    /// Predefined panel positions
    enum PanelLocation {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
        case center
        case centerRight
        case centerLeft
    }
}

// MARK: - FocusPanelController

/// Controller class to manage the focus panel lifecycle and state
class FocusPanelController: NSObject, NSWindowDelegate {
    private var panel: FocusPanel?
    private let focusTimerState: FocusTimerState
    private let spotifyManager: SpotifyManager
    private var wasClosedByUser: Bool = false

    init(focusTimerState: FocusTimerState, spotifyManager: SpotifyManager) {
        self.focusTimerState = focusTimerState
        self.spotifyManager = spotifyManager
    }

    /// Create and show the focus panel
    func showPanel() {
        if panel == nil {
            createPanel()
        }
        wasClosedByUser = false
        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Hide the focus panel
    func hidePanel() {
        panel?.hideAnimated()
    }

    /// Toggle panel visibility
    func togglePanel() {
        if panel?.isVisible == true {
            hidePanel()
        } else {
            showPanel()
        }
    }

    /// Check if panel is currently visible
    var isPanelVisible: Bool {
        panel?.isVisible ?? false
    }

    /// Create the panel with FocusView content
    private func createPanel() {
        let focusView = FocusView(
            timerState: focusTimerState,
            spotifyManager: spotifyManager
        )

        panel = FocusPanel(contentView: focusView)
        panel?.delegate = self
    }

    /// Dispose of the panel
    func disposePanel() {
        panel?.close()
        panel = nil
    }

    /// Brings existing panel to front or creates one if needed
    func bringToFrontOrShow() {
        if let existingPanel = panel {
            if existingPanel.isVisible {
                existingPanel.makeKeyAndOrderFront(nil)
            } else {
                showPanel()
            }
        } else {
            showPanel()
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    var wasDismissedByUser: Bool {
        wasClosedByUser
    }

    func windowWillClose(_ notification: Notification) {
        wasClosedByUser = true
        // Do NOT dispose the panel, keep instance alive
    }
}
