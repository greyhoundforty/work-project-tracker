import SwiftUI
import SwiftData
import Sparkle

@main
struct EngagementTrackerApp: App {
    @State private var appState = AppState()
    @State private var container = AppState.makeContainer(
        cloudSync: UserDefaults.standard.bool(forKey: "cloudSyncEnabled")
    )

    @StateObject private var updaterService = UpdaterService.shared

    var body: some Scene {
        WindowGroup(id: "main") {
            CustomThemeProvider {
                ContentView()
                    .environment(appState)
                    .preferredColorScheme(appState.preferredColorScheme)
            }
        }
        .modelContainer(container)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") {
                    updaterService.checkForUpdates()
                }
            }
        }

        MenuBarExtra("Engagement Tracker", systemImage: "briefcase.fill") {
            MenuBarPopoverView()
                .environment(appState)
        }
        .menuBarExtraStyle(.window)
        .modelContainer(container)

        Settings {
            SettingsView()
                .environment(appState)
                .preferredColorScheme(appState.preferredColorScheme)
        }
        .modelContainer(container)
    }
}
