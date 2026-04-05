import SwiftUI
import SwiftData

struct StagesSidebarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openSettings) private var openSettings
    @Query private var projects: [Project]

    @State private var showImport = false
    @State private var showShare = false
    @State private var showBackup = false
    @State private var showNewFolder = false

    var body: some View {
        VStack(spacing: 0) {
            SidebarList(projects: projects, showNewFolder: $showNewFolder)
                .listStyle(.sidebar)
                .navigationTitle("Charter")

            Divider()

            HStack(spacing: 2) {
                SidebarActionButton(icon: "gearshape", help: "Settings") { openSettings() }
                SidebarActionButton(icon: "square.and.arrow.down", help: "Import Projects") { showImport = true }
                Spacer()
                SidebarActionButton(icon: "folder.badge.plus", help: "New Folder") { showNewFolder = true }
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
        .sheet(isPresented: $showNewFolder) { NewFolderSheet() }
    }
}

// MARK: - Sidebar List

private struct SidebarList: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \ProjectFolder.sortOrder) private var folders: [ProjectFolder]
    let projects: [Project]
    @Binding var showNewFolder: Bool

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

    private var unsortedCount: Int {
        activeProjects.filter { $0.folder == nil }.count
    }

    private var rootFolders: [ProjectFolder] {
        folders.filter { $0.parent == nil }
    }

    private func childFolders(of parent: ProjectFolder) -> [ProjectFolder] {
        folders.filter { $0.parent?.id == parent.id }
    }

    private func projectCount(in folder: ProjectFolder) -> Int {
        activeProjects.filter { $0.folder?.id == folder.id }.count
    }

    var body: some View {
        List {
            allProjectsSection
            stagesSection
            if !allTags.isEmpty { tagsSection }
            if !projectsWithOpenTasks.isEmpty { tasksSection }
        }
    }

    private var allProjectsSection: some View {
        Section {
            SidebarRow(
                label: "All Projects",
                icon: "tray.2",
                badge: activeProjects.count,
                isSelected: appState.selectedStage == nil
                    && appState.selectedTag == nil
                    && appState.selectedLabel == nil
                    && appState.selectedFolder == nil
                    && !appState.selectedFolderIsUnsorted,
                color: .themeFg
            ) {
                appState.selectedStage = nil
                appState.selectedTag = nil
                appState.selectedLabel = nil
                appState.selectedFolder = nil
                appState.selectedFolderIsUnsorted = false
            }

            SidebarRow(
                label: "Unsorted",
                icon: "tray",
                badge: unsortedCount,
                isSelected: appState.selectedFolderIsUnsorted,
                color: .themeFgDim
            ) {
                appState.selectedFolderIsUnsorted = true
                appState.selectedFolder = nil
                appState.selectedStage = nil
                appState.selectedTag = nil
                appState.selectedLabel = nil
            }

            ForEach(rootFolders) { folder in
                SidebarRow(
                    label: folder.name,
                    icon: "folder",
                    badge: projectCount(in: folder),
                    isSelected: appState.selectedFolder?.id == folder.id,
                    color: .themeBlue
                ) {
                    appState.selectedFolder = folder
                    appState.selectedFolderIsUnsorted = false
                    appState.selectedStage = nil
                    appState.selectedTag = nil
                    appState.selectedLabel = nil
                }

                ForEach(childFolders(of: folder)) { child in
                    SidebarRow(
                        label: child.name,
                        icon: "folder",
                        badge: projectCount(in: child),
                        isSelected: appState.selectedFolder?.id == child.id,
                        color: .themeBlue,
                        indented: true
                    ) {
                        appState.selectedFolder = child
                        appState.selectedFolderIsUnsorted = false
                        appState.selectedStage = nil
                        appState.selectedTag = nil
                        appState.selectedLabel = nil
                    }
                }
            }
        } header: {
            HStack {
                Text("All Projects")
                Spacer()
                Button {
                    showNewFolder = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.themeFgDim)
                }
                .buttonStyle(.plain)
                .help("New Folder")
            }
        }
    }

    private var stagesSection: some View {
        Section("Stages") {
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
                    appState.selectedFolder = nil
                    appState.selectedFolderIsUnsorted = false
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
                    appState.selectedFolder = nil
                    appState.selectedFolderIsUnsorted = false
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
                    appState.selectedFolder = nil
                    appState.selectedFolderIsUnsorted = false
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
    var indented: Bool = false
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
            .padding(.leading, indented ? 16 : 0)
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
