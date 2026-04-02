import SwiftUI
import SwiftData

struct StagesSidebarView: View {
    @Environment(AppState.self) private var appState
    @Query private var projects: [Project]

    private var allTags: [String] {
        let active = projects.filter(\.isActive)
        return Set(active.flatMap(\.tags).filter { $0.hasPrefix("#") }).sorted()
    }

    /// Active projects that have at least one open task, sorted by open task count descending.
    private var projectsWithOpenTasks: [(project: Project, count: Int)] {
        projects
            .filter(\.isActive)
            .compactMap { p -> (Project, Int)? in
                let open = p.tasks.filter { !$0.isCompleted }.count
                return open > 0 ? (p, open) : nil
            }
            .sorted { $0.1 > $1.1 }
    }

    var body: some View {
        List {
            Section {
                SidebarRow(
                    label: "All Projects",
                    icon: "folder",
                    badge: projects.filter(\.isActive).count,
                    isSelected: appState.selectedStage == nil && appState.selectedTag == nil && appState.selectedLabel == nil,
                    color: .themeFg
                ) {
                    appState.selectedStage = nil
                    appState.selectedTag = nil
                    appState.selectedLabel = nil
                }
            }

            Section("Pipeline") {
                ForEach(ProjectStage.allCases.filter { !$0.isTerminal }) { stage in
                    SidebarRow(
                        label: stage.rawValue,
                        icon: stageIcon(stage),
                        badge: count(for: stage),
                        isSelected: appState.selectedStage == stage && appState.selectedTag == nil && appState.selectedLabel == nil,
                        color: Color.themeStageColor(for: stage)
                    ) {
                        appState.selectedStage = stage
                        appState.selectedTag = nil
                        appState.selectedLabel = nil
                    }
                }
            }

            if !allTags.isEmpty {
                Section("Tags") {
                    ForEach(allTags, id: \.self) { tag in
                        SidebarRow(
                            label: String(tag.dropFirst()),
                            icon: "number",
                            badge: tagCount(tag),
                            isSelected: appState.selectedTag == tag,
                            color: .themeYellow
                        ) {
                            appState.selectedTag = tag
                            appState.selectedLabel = nil
                            appState.selectedStage = nil
                        }
                    }
                }
            }

            if !projectsWithOpenTasks.isEmpty {
                Section("Tasks") {
                    ForEach(projectsWithOpenTasks, id: \.project.id) { item in
                        SidebarRow(
                            label: item.project.name,
                            icon: "checklist",
                            badge: item.count,
                            isSelected: appState.selectedProject?.id == item.project.id
                                && appState.selectedStage == nil
                                && appState.selectedTag == nil,
                            color: .themeAqua
                        ) {
                            appState.selectedProject = item.project
                            appState.selectedStage = nil
                            appState.selectedTag = nil
                            appState.selectedLabel = nil
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Engagement Tracker")
        .frame(minWidth: 160)
    }

    private func count(for stage: ProjectStage) -> Int {
        projects.filter { $0.stage == stage && $0.isActive }.count
    }

    private func tagCount(_ tag: String) -> Int {
        projects.filter { $0.isActive && $0.tags.contains(tag) }.count
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

private struct SidebarRow: View {
    let label: String
    let icon: String
    let badge: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Label(label, systemImage: icon)
                    .foregroundStyle(color)
                Spacer()
                if badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.themeFgDim)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.themeBg2)
                        .clipShape(Capsule())
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.themeAqua.opacity(0.2) : Color.clear)
        )
    }
}
