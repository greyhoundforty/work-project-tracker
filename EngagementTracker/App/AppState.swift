import SwiftUI
import SwiftData

enum ThemeMode: String {
    case system, light, dark
}

@Observable
final class AppState {
    var selectedStage: ProjectStage? = .discovery
    var selectedTag: String? = nil
    var selectedProject: Project?
    var searchQuery: String = ""
    var isCloudSyncEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "cloudSyncEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "cloudSyncEnabled") }
    }
    var themeMode: ThemeMode = ThemeMode(rawValue: UserDefaults.standard.string(forKey: "themeMode") ?? "system") ?? .system {
        didSet { UserDefaults.standard.set(themeMode.rawValue, forKey: "themeMode") }
    }
    var templateFolderPath: String? {
        get { UserDefaults.standard.string(forKey: "templateFolderPath") }
        set { UserDefaults.standard.set(newValue, forKey: "templateFolderPath") }
    }

    static func makeContainer(cloudSync: Bool) -> ModelContainer {
        let schema = Schema([
            Project.self,
            Contact.self,
            Checkpoint.self,
            ProjectTask.self,
            Engagement.self,
            Note.self
        ])
        let config: ModelConfiguration
        if cloudSync {
            config = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
        } else {
            config = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        }
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
