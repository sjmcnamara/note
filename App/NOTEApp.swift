import SwiftUI
import SwiftData

@main
struct NOTEApp: App {
    @State private var container: ModelContainer?
    @StateObject private var identityService = IdentityService()
    @StateObject private var lockService = AppLockService.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        #if !targetEnvironment(macCatalyst)
        UIWindow.appearance().backgroundColor = UIColor(named: "noteBg")
        #endif
        // init() must return immediately — the watchdog fires if we block here.
        // All store work happens in .task below, after the launch window closes.
    }

    var body: some Scene {
        WindowGroup {
            if let container, identityService.identity != nil {
                ContentView()
                    .modelContainer(container)
                    .environmentObject(AppSettings.shared)
                    .environmentObject(identityService)
                    .environmentObject(lockService)
            } else {
                Color.noteBg
                    .ignoresSafeArea()
                    .task {
                        if container == nil { container = Self.openStore() }
                        if identityService.identity == nil { await identityService.initialise() }
                    }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { try? container?.mainContext.save() }
        }
    }

    // Synchronous on the main actor — avoids Task.detached round-trips that
    // make things slower. Explicit URL + cloudKitDatabase: .none eliminates
    // two known slow paths:
    //   1. CoreData's directory-discovery security walk (saw 512 / sandbox errors)
    //   2. A CloudKit probe that can time out even without the entitlement
    private static func openStore() -> ModelContainer {
        let appSupport = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)

        let storeURL = appSupport.appendingPathComponent("default.store")
        let schema  = Schema([Note.self, TodoItem.self])
        let config  = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("ModelContainer failed: \(error)")
        }
    }
}
