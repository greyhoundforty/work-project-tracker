import SwiftUI
import SwiftData
import Sparkle

@main
struct EngagementTrackerApp: App {
    @State private var appState = AppState()
    @State private var container = AppState.makeContainer(
        cloudSync: UserDefaults.standard.bool(forKey: "cloudSyncEnabled")
    )
    @State private var remindersService = RemindersService.shared

    @StateObject private var updaterService = UpdaterService.shared

    init() {
        let savedMode = ThemeMode(rawValue: UserDefaults.standard.string(forKey: "themeMode") ?? "system") ?? .system
        Self.applyAppearance(savedMode)
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            CustomThemeProvider {
                ContentView()
                    .environment(appState)
                    .environment(remindersService)
                    .preferredColorScheme(appState.preferredColorScheme)
            }
            .onChange(of: appState.themeMode) { _, newMode in
                Self.applyAppearance(newMode)
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
                .environment(remindersService)
                .preferredColorScheme(appState.preferredColorScheme)
        }
        .modelContainer(container)
    }

    private static func applyAppearance(_ mode: ThemeMode) {
        switch mode {
        case .system:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }
}
