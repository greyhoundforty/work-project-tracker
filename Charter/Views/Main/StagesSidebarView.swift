import SwiftUI
import SwiftData

struct StagesSidebarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openSettings) private var openSettings
    @Query private var projects: [Project]

    @State private var showImport = false
    @State private var showShare = false
    @State private var showBackup = false

    var body: some View {
        VStack(spacing: 0) {
            SidebarList(projects: projects)
                .listStyle(.sidebar)
                .navigationTitle("Engagement Tracker")

            Divider()

            HStack(spacing: 2) {
                SidebarActionButton(icon: "gearshape", help: "Settings") { openSettings() }
                SidebarActionButton(icon: "square.and.arrow.down", help: "Import Projects") { showImport = true }
                Spacer()
                SidebarActionButton(icon: "square.and.arrow.up", help: "Share Project Data") { showShare = true }
                SidebarActionButton(icon: "archivebox", help: "Backup Projects") { showBackup = true }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.themeBg1)
        }
        .frame(minWidth: 160)
        .sheet(isPresented: $showImport) { ImportSheet() }
        .sheet(isPresented: $showShare) { ShareSheet() }
        .sheet(isPresented: $showBackup) { BackupSheet() }
    }
}

// MARK: - Sidebar List

private struct SidebarList: View {
    @Environment(AppState.self) private var appState
    let projects: [Project]

    private var activeProjects: [Project] { projects.filter(\.isActive) }

    private var allTags: [String] {
        Set(activeProjects.flatMap(\.tags).filter { $0.hasPrefix("#") }).sorted()
    }

    private var projectsWithOpenTasks: [(project: Project, count: Int)] {
        activeProjects
            .compactMap { p -> (Project, Int)? in
                let open = p.tasks.filter { !$0.isCompleted }.count
                return open > 0 ? (p, open) : nil
            }
            .sorted { $0.1 > $1.1 }
    }

    var body: some View {
        List {
            allProjectsSection
            pipelineSection
            if !allTags.isEmpty { tagsSection }
            if !projectsWithOpenTasks.isEmpty { tasksSection }
        }
    }

    private var allProjectsSection: some View {
        Section {
            SidebarRow(
                label: "All Projects",
                icon: "folder",
                badge: activeProjects.count,
                isSelected: appState.selectedStage == nil
                    && appState.selectedTag == nil
                    && appState.selectedLabel == nil,
                color: .themeFg
            ) {
                appState.selectedStage = nil
                appState.selectedTag = nil
                appState.selectedLabel = nil
            }
        }
    }

    private var pipelineSection: some View {
        Section("Pipeline") {
            ForEach(ProjectStage.allCases.filter { !$0.isTerminal }) { stage in
                SidebarRow(
                    label: stage.rawValue,
                    icon: stageIcon(stage),
                    badge: count(for: stage),
                    isSelected: appState.selectedStage == stage
                        && appState.selectedTag == nil
                        && appState.selectedLabel == nil,
                    color: Color.themeStageColor(for: stage)
                ) {
                    appState.selectedStage = stage
                    appState.selectedTag = nil
                    appState.selectedLabel = nil
                }
            }
        }
    }

    private var tagsSection: some View {
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

    private var tasksSection: some View {
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

// MARK: - Private components

private struct SidebarActionButton: View {
    let icon: String
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.themeFgDim)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
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
