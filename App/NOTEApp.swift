import SwiftUI
import SwiftData

@main
struct NOTEApp: App {
    @State private var container: ModelContainer?
    @Environment(\.scenePhase) private var scenePhase

    init() {
        UIWindow.appearance().backgroundColor = UIColor(named: "noteBg")
    }

    var body: some Scene {
        WindowGroup {
            if let container {
                ContentView()
                    .modelContainer(container)
            } else {
                // Shown while the store is being created on a background thread.
                // Identical to the launch screen background so the transition
                // is invisible. ContentView is never shown until the container
                // is fully ready, so modelContext is always available on tap.
                Color.noteBg
                    .ignoresSafeArea()
                    .task(priority: .userInitiated) {
                        container = await Self.makeContainer()
                    }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                try? container?.mainContext.save()
            }
        }
    }

    // Runs ModelContainer.init() on a background thread so the main actor
    // stays free during the (potentially slow) first-install SQLite setup.
    // NSPersistentContainer.loadPersistentStores is documented thread-safe;
    // mainContext is only ever touched on the main actor via SwiftUI environment.
    private static func makeContainer() async -> ModelContainer {
        await Task.detached(priority: .userInitiated) {
            let appSupport = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)
                .first!
            try? FileManager.default.createDirectory(
                at: appSupport, withIntermediateDirectories: true)
            do {
                return try ModelContainer(for: Note.self)
            } catch {
                fatalError("ModelContainer init failed: \(error)")
            }
        }.value
    }
}
