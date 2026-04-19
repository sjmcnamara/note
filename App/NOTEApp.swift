import SwiftUI

@main
struct NOTEApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Canvas color fills the entire window — behind safe areas, behind every screen.
                Color.noteBg.ignoresSafeArea(.all, edges: .all)
                ContentView()
            }
        }
    }
}
