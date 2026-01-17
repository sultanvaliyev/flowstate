import SwiftUI

@main
struct FlowStateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Empty Settings scene - we handle everything via AppDelegate
        Settings {
            EmptyView()
        }
    }
}
