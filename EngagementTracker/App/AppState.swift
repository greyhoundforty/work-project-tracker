import SwiftUI
import SwiftData

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
