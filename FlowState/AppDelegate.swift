import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private lazy var statusItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var timerPanel: NSPanel?
    private var timerState = TimerState()

    // Focus Mode state and panel controller
    private var focusTimerState = FocusTimerState()
    private var focusPanelController: FocusPanelController?

    // Spotify integration
    private lazy var spotifyManager: SpotifyManager = {
        let spotifyService = AppleScriptSpotifyService()
        return SpotifyManager(service: spotifyService)
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBarItem()
        setupFloatingTimerWindow()
        setupFocusPanelController()
        focusPanelController?.showPanel()
        setupGlobalKeyboardShortcut()
    }

    // MARK: - Focus Panel Setup

    private func setupFocusPanelController() {
        focusPanelController = FocusPanelController(
            focusTimerState: focusTimerState,
            spotifyManager: spotifyManager
        )
    }

    private func setupGlobalKeyboardShortcut() {
        // Register global keyboard shortcut Cmd+Shift+F for Focus Mode
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Check for Cmd+Shift+F
            if event.modifierFlags.contains([.command, .shift]) && event.charactersIgnoringModifiers == "f" {
                self?.toggleFocusPanel()
                return nil // Consume the event
            }
            return event
        }
    }

    // MARK: - Menu Bar Setup

    private func setupMenuBarItem() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "leaf.fill", accessibilityDescription: "FlowState")
        }

        let menu = NSMenu()

        // Focus Mode - Primary feature
        let focusModeItem = NSMenuItem(title: "Focus Mode", action: #selector(toggleFocusPanel), keyEquivalent: "F")
        focusModeItem.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(focusModeItem)

        menu.addItem(NSMenuItem.separator())

        // Quick timer controls
        menu.addItem(NSMenuItem(title: "Show Timer", action: #selector(showTimer), keyEquivalent: "t"))
        menu.addItem(NSMenuItem(title: "Hide Timer", action: #selector(hideTimer), keyEquivalent: "h"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Start Focus Session", action: #selector(startSession), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Stop Session", action: #selector(stopSession), keyEquivalent: "x"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Statistics", action: #selector(showStatistics), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit FlowState", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    // MARK: - Floating Timer Window Setup

    private func setupFloatingTimerWindow() {
        // Create the SwiftUI view with the shared timer state
        let timerView = TimerView(timerState: timerState)
        let hostingView = NSHostingView(rootView: timerView)

        // Define window size and position (top-left corner with padding)
        let windowWidth: CGFloat = 180
        let windowHeight: CGFloat = 80
        let padding: CGFloat = 20

        // Get the main screen's frame
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame

        // Position at top-left
        let windowX = screenFrame.origin.x + padding
        let windowY = screenFrame.origin.y + screenFrame.height - windowHeight - padding

        let windowRect = NSRect(x: windowX, y: windowY, width: windowWidth, height: windowHeight)

        // Create NSPanel for floating behavior
        let panel = NSPanel(
            contentRect: windowRect,
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless, .resizable],
            backing: .buffered,
            defer: false
        )

        // Configure panel for always-on-top floating behavior
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden

        // Hide standard window buttons
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true

        panel.contentView = hostingView

        // Set size constraints for resizing
        panel.minSize = NSSize(width: 120, height: 50)
        panel.maxSize = NSSize(width: 300, height: 120)

        timerPanel = panel
    }

    // MARK: - Menu Actions

    @objc private func showTimer() {
        focusPanelController?.showPanel()
    }

    @objc private func hideTimer() {
        focusPanelController?.hidePanel()
    }

    @objc private func startSession() {
        focusTimerState.start()
        focusPanelController?.showPanel()
    }

    @objc private func stopSession() {
        focusTimerState.cancel()
    }

    @objc private func showStatistics() {
        // Will implement statistics window later
        #if DEBUG
        print("Statistics: \(StatisticsManager.shared.getStatistics())")
        #endif
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Focus Panel Actions

    @objc private func toggleFocusPanel() {
        focusPanelController?.togglePanel()
    }

    @objc private func showFocusPanel() {
        focusPanelController?.bringToFrontOrShow()
    }

    @objc private func hideFocusPanel() {
        focusPanelController?.hidePanel()
    }

    // MARK: - App Lifecycle for Single-Window Behavior

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        focusPanelController?.bringToFrontOrShow()
        return false  // We handled it
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        // Show focus panel if it wasn't explicitly dismissed by user
        guard let controller = focusPanelController else { return }
        if !controller.wasDismissedByUser && !controller.isPanelVisible {
            controller.showPanel()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        focusPanelController?.disposePanel()
    }
}
