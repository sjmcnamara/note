import SwiftUI
import SwiftData

@main
struct NOTEApp: App {
    @State private var container: ModelContainer?
    @Environment(\.scenePhase) private var scenePhase

    init() {
        UIWindow.appearance().backgroundColor = UIColor(named: "noteBg")
        // init() must return fast — iOS watchdog kills apps that take > ~5 s
        // before the first frame. Container creation happens in .task below,
        // after the launch window has closed.
    }

    var body: some Scene {
        WindowGroup {
            if let container {
                ContentView()
                    .modelContainer(container)
            } else {
                // Visually identical to the launch screen; hides the delay.
                Color.noteBg
                    .ignoresSafeArea()
                    .task {
                        let appSupport = FileManager.default
                            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                        try? FileManager.default.createDirectory(
                            at: appSupport, withIntermediateDirectories: true)
                        do {
                            container = try ModelContainer(
                                for: Schema([Note.self, TodoItem.self]))
                        } catch {
                            fatalError("SwiftData container failed: \(error)")
                        }
                    }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                try? container?.mainContext.save()
            }
        }
    }
}
