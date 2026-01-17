import SwiftUI

@main
struct ZonnApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Empty Settings scene - we handle everything via AppDelegate
        Settings {
            EmptyView()
        }
    }
}
