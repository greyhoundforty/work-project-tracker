import SwiftUI
import SwiftData

enum ThemeMode: String {
    case system, light, dark
}

@Observable
final class AppState {
    var selectedStage: ProjectStage? = .discovery
    var selectedTag: String? = nil
    var selectedLabel: String? = nil
    var selectedFolder: ProjectFolder? = nil
    var selectedFolderIsUnsorted: Bool = false
    var selectedProject: Project?
    var searchQuery: String = ""
    var isCloudSyncEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "cloudSyncEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "cloudSyncEnabled") }
    }
    var themeMode: ThemeMode = ThemeMode(rawValue: UserDefaults.standard.string(forKey: "themeMode") ?? "system") ?? .system {
        didSet { UserDefaults.standard.set(themeMode.rawValue, forKey: "themeMode") }
    }

    var preferredColorScheme: ColorScheme? {
        switch themeMode {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
    var templateFolderPath: String? = UserDefaults.standard.string(forKey: "templateFolderPath") {
        didSet { UserDefaults.standard.set(templateFolderPath, forKey: "templateFolderPath") }
    }
    var templateFolderBookmark: Data? = UserDefaults.standard.data(forKey: "templateFolderBookmark") {
        didSet { UserDefaults.standard.set(templateFolderBookmark, forKey: "templateFolderBookmark") }
    }

    var remindersListID: String? = UserDefaults.standard.string(forKey: "remindersListID") {
        didSet { UserDefaults.standard.set(remindersListID, forKey: "remindersListID") }
    }
    var remindersMarkCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: "remindersMarkCompleted") }
        set { UserDefaults.standard.set(newValue, forKey: "remindersMarkCompleted") }
    }

    func resolveTemplateFolderURL() -> URL? {
        if let bookmarkData = templateFolderBookmark {
            var isStale = false
            if let url = try? URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ) {
                if isStale {
                    templateFolderBookmark = try? url.bookmarkData(options: .withSecurityScope)
                }
                return url
            }
        }
        return templateFolderPath.map { URL(fileURLWithPath: $0) }
    }

    static func makeContainer(cloudSync: Bool) -> ModelContainer {
        let schema = Schema([
            Project.self,
            ProjectFolder.self,
            Contact.self,
            Checkpoint.self,
            ProjectTask.self,
            Engagement.self,
            Note.self,
            ProjectCustomField.self,
            ProjectLink.self
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
