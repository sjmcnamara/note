import SwiftUI
import SwiftData

// Built once synchronously before any view renders. Avoids the Core Data
// threading hazards that Task.detached creates, and ensures modelContext is
// ready the moment ContentView appears.
private let appContainer: ModelContainer = {
    let appSupport = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
    do {
        return try ModelContainer(for: Note.self)
    } catch {
        fatalError("SwiftData container failed: \(error)")
    }
}()

@main
struct NOTEApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        UIWindow.appearance().backgroundColor = UIColor(named: "noteBg")
        // Touch the container here so its lazy init runs during app init,
        // not on the first frame render.
        _ = appContainer
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(appContainer)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                try? appContainer.mainContext.save()
            }
        }
    }
}
