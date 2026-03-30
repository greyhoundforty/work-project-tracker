import SwiftUI
import SwiftData

struct StagesSidebarView: View {
    @Environment(AppState.self) private var appState
    @Query private var projects: [Project]

    var body: some View {
        @Bindable var appState = appState
        List(selection: $appState.selectedStage) {
            Section {
                Label("All Projects", systemImage: "folder")
                    .tag(Optional<ProjectStage>.none)
                    .badge(projects.filter(\.isActive).count)
            }

            Section("Pipeline") {
                ForEach(ProjectStage.allCases.filter { !$0.isTerminal }) { stage in
                    Label(stage.rawValue, systemImage: stageIcon(stage))
                        .tag(Optional(stage))
                        .badge(count(for: stage))
                        .foregroundStyle(Color.gruvStageColor(for: stage))
                }
            }

            Section("Closed") {
                Label(ProjectStage.won.rawValue, systemImage: "checkmark.seal.fill")
                    .tag(Optional(ProjectStage.won))
                    .badge(count(for: .won))
                    .foregroundStyle(Color.gruvGreen)

                Label(ProjectStage.lost.rawValue, systemImage: "xmark.seal.fill")
                    .tag(Optional(ProjectStage.lost))
                    .badge(count(for: .lost))
                    .foregroundStyle(Color.gruvRed)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Engagement Tracker")
        .frame(minWidth: 160)
    }

    private func count(for stage: ProjectStage) -> Int {
        projects.filter { $0.stage == stage && $0.isActive }.count
    }

    private func stageIcon(_ stage: ProjectStage) -> String {
        switch stage {
        case .discovery:       return "magnifyingglass"
        case .initialDelivery: return "doc.text"
        case .refine:          return "pencil.and.list.clipboard"
        case .proposal:        return "envelope.open"
        case .won:             return "checkmark.seal.fill"
        case .lost:            return "xmark.seal.fill"
        }
    }
}
