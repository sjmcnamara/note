import SwiftUI

@main
struct NOTEApp: App {
    init() {
        // Set the UIWindow background directly so the safe-area regions
        // (status bar, home indicator) never show the system default.
        UIWindow.appearance().backgroundColor = UIColor(named: "noteBg")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
