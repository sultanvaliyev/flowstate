import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timerPanel: NSPanel!
    private var timerState = TimerState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBarItem()
        setupFloatingTimerWindow()
    }

    // MARK: - Menu Bar Setup

    private func setupMenuBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "FlowState Timer")
        }

        let menu = NSMenu()

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
        timerPanel = NSPanel(
            contentRect: windowRect,
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )

        // Configure panel for always-on-top floating behavior
        timerPanel.level = .floating
        timerPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        timerPanel.isMovableByWindowBackground = true
        timerPanel.backgroundColor = .clear
        timerPanel.isOpaque = false
        timerPanel.hasShadow = true
        timerPanel.titlebarAppearsTransparent = true
        timerPanel.titleVisibility = .hidden

        // Hide standard window buttons
        timerPanel.standardWindowButton(.closeButton)?.isHidden = true
        timerPanel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        timerPanel.standardWindowButton(.zoomButton)?.isHidden = true

        timerPanel.contentView = hostingView

        // Show the panel
        timerPanel.orderFront(nil)
    }

    // MARK: - Menu Actions

    @objc private func showTimer() {
        timerPanel.orderFront(nil)
    }

    @objc private func hideTimer() {
        timerPanel.orderOut(nil)
    }

    @objc private func startSession() {
        timerState.startSession()
    }

    @objc private func stopSession() {
        timerState.stopSession()
    }

    @objc private func showStatistics() {
        // Will implement statistics window later
        print("Statistics: \(StatisticsManager.shared.getStatistics())")
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
