import SwiftUI
import SwiftData

@main
struct NOTEApp: App {
    init() {
        UIWindow.appearance().backgroundColor = UIColor(named: "noteBg")
        // Pre-create Application Support so SwiftData doesn't hit the slow
        // CoreData recovery path on first launch, which triggers a watchdog kill.
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Note.self)
    }
}
