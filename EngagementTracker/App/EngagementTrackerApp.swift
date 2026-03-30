import SwiftUI
import SwiftData

@main
struct EngagementTrackerApp: App {
    @State private var appState = AppState()

    var container: ModelContainer {
        AppState.makeContainer(cloudSync: appState.isCloudSyncEnabled)
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environment(appState)
        }
        .modelContainer(container)

        MenuBarExtra("Engagement Tracker", systemImage: "briefcase.fill") {
            MenuBarPopoverView()
                .environment(appState)
                .modelContainer(container)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(appState)
        }
    }
}
