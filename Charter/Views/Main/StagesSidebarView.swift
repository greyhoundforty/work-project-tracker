import SwiftUI
import SwiftData
import CoreTransferable
import UniformTypeIdentifiers
import OSLog

extension UTType {
    static let charterProjectDragItem = UTType(exportedAs: "com.greyhoundforty.charter.project-drag-item")
}

struct ProjectDragItem: Codable, Transferable {
    let id: UUID

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .charterProjectDragItem)
    }
}

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

private let dragDropLogger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.greyhoundforty.Charter",
    category: "DragDrop"
)

// MARK: - Sidebar List

private struct SidebarList: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ProjectFolder.sortOrder) private var folders: [ProjectFolder]
    let projects: [Project]
    @Binding var showNewFolder: Bool

    @State private var toastMessage = ""
    @State private var showToast = false

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
        ZStack(alignment: .top) {
            List {
                allProjectsSection
                stagesSection
                if !allTags.isEmpty { tagsSection }
                if !projectsWithOpenTasks.isEmpty { tasksSection }
            }

            if showToast {
                VStack {
                    Text(toastMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.themeBlue)
                        .clipShape(Capsule())
                        .shadow(radius: 4)
                        .padding(.top, 8)
                        .transition(.scale.combined(with: .opacity))
                    Spacer()
                }
            }
        }
    }

    private var allProjectsSection: some View {
        Section {
            SidebarRow(
                label: "All Projects",
                icon: "square.grid.2x2",
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
                icon: "tray.and.arrow.down",
                badge: unsortedCount,
                isSelected: appState.selectedFolderIsUnsorted,
                color: .themeFgDim
            ) {
                appState.selectedFolderIsUnsorted = true
                appState.selectedFolder = nil
                appState.selectedStage = nil
                appState.selectedTag = nil
                appState.selectedLabel = nil
            } onDropProjects: { ids in
                moveDroppedProjects(ids, to: nil)
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
                } onDropProjects: { ids in
                    moveDroppedProjects(ids, to: folder)
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
                    } onDropProjects: { ids in
                        moveDroppedProjects(ids, to: child)
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
                    appState.pendingProjectDetailTab = "tasks"
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

    private func moveDroppedProjects(_ ids: [UUID], to folder: ProjectFolder?) -> Bool {
        let uniqueIDs = Array(Set(ids))
        guard !uniqueIDs.isEmpty else {
            dragDropLogger.warning("Drop ignored: no project IDs were received")
            return false
        }

        dragDropLogger.debug("Handling drop for \(uniqueIDs.count) project(s) into folder=\(folder?.name ?? "Unsorted", privacy: .public)")

        let projectsByID = Dictionary(uniqueKeysWithValues: projects.map { ($0.id, $0) })

        var moved = false
        for id in uniqueIDs {
            guard let project = projectsByID[id] else {
                dragDropLogger.error("Drop payload contained unknown project id \(id.uuidString, privacy: .public)")
                continue
            }
            if project.folder?.id == folder?.id {
                dragDropLogger.debug("Project already in target folder: \(project.name, privacy: .public)")
                continue
            }

            project.folder = folder
            project.updatedAt = Date()
            dragDropLogger.debug("Project moved in-memory: \(project.name, privacy: .public)")
            moved = true
        }

        guard moved else {
            dragDropLogger.debug("Drop completed with no changes")
            return true
        }
        do {
            try modelContext.save()
            dragDropLogger.info("Drop persisted successfully for \(uniqueIDs.count) project(s)")
            appState.selectedStage = nil
            appState.selectedTag = nil
            appState.selectedLabel = nil
            appState.selectedFolder = folder
            appState.selectedFolderIsUnsorted = folder == nil

            // Show toast notification
            let count = uniqueIDs.count
            let folderName = folder?.name ?? "Unsorted"
            toastMessage = "Moved \(count) project\(count == 1 ? "" : "s") to \(folderName)"
            showToast = true

            // Auto-dismiss toast after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                showToast = false
            }

            return true
        } catch {
            modelContext.rollback()
            dragDropLogger.error("Drop save failed: \(error.localizedDescription, privacy: .public)")
            return false
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
    var onDropProjects: (([UUID]) -> Bool)? = nil

    @State private var isDropTarget = false

    private func handleDropProviders(_ providers: [NSItemProvider], onDropProjects: @escaping ([UUID]) -> Bool) -> Bool {
        let allTypes = providers.flatMap(\.registeredTypeIdentifiers)
        dragDropLogger.debug("onDrop invoked for row=\(label, privacy: .public), providers=\(providers.count), typeIds=\(allTypes.joined(separator: ","), privacy: .public)")

        var accepted = false
        let group = DispatchGroup()
        let lock = NSLock()
        var droppedIDs: [UUID] = []

        for provider in providers {
            guard provider.hasItemConformingToTypeIdentifier(UTType.charterProjectDragItem.identifier) else {
                continue
            }

            accepted = true
            group.enter()
            provider.loadDataRepresentation(forTypeIdentifier: UTType.charterProjectDragItem.identifier) { data, error in
                defer { group.leave() }

                if let error {
                    dragDropLogger.error("Drop data load failed for row=\(label, privacy: .public): \(error.localizedDescription, privacy: .public)")
                    return
                }

                guard let data else {
                    dragDropLogger.error("Drop data load returned nil for row=\(label, privacy: .public)")
                    return
                }

                if let item = try? JSONDecoder().decode(ProjectDragItem.self, from: data) {
                    lock.lock()
                    droppedIDs.append(item.id)
                    lock.unlock()
                    dragDropLogger.debug("Drop payload decoded id=\(item.id.uuidString, privacy: .public) for row=\(label, privacy: .public)")
                    return
                }

                if let text = String(data: data, encoding: .utf8), let id = UUID(uuidString: text.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    lock.lock()
                    droppedIDs.append(id)
                    lock.unlock()
                    dragDropLogger.debug("Drop payload decoded fallback UUID string id=\(id.uuidString, privacy: .public) for row=\(label, privacy: .public)")
                    return
                }

                dragDropLogger.error("Drop payload decode failed for row=\(label, privacy: .public), bytes=\(data.count)")
            }
        }

        guard accepted else {
            dragDropLogger.warning("Drop rejected for row=\(label, privacy: .public): no providers matched \(UTType.charterProjectDragItem.identifier, privacy: .public)")
            return false
        }

        group.notify(queue: .main) {
            let uniqueIDs = Array(Set(droppedIDs))
            guard !uniqueIDs.isEmpty else {
                dragDropLogger.warning("Drop decode completed for row=\(label, privacy: .public) but no valid UUIDs were found")
                return
            }

            let didMove = onDropProjects(uniqueIDs)
            dragDropLogger.debug("Drop apply result for row=\(label, privacy: .public): \(didMove)")
        }

        return true
    }

    var body: some View {
        let row = HStack {
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
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .contentShape(RoundedRectangle(cornerRadius: 6))
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill((isSelected || isDropTarget) ? Color.themeAqua.opacity(0.2) : Color.clear)
        )
        .onTapGesture(perform: action)

        if let onDropProjects {
            row
                .onDrop(of: [UTType.charterProjectDragItem], isTargeted: $isDropTarget) { providers in
                    handleDropProviders(providers, onDropProjects: onDropProjects)
                }
                .onChange(of: isDropTarget) { _, targeted in
                    dragDropLogger.debug("Drop target state changed for row=\(label, privacy: .public): \(targeted)")
                }
        } else {
            row
        }
    }
}
