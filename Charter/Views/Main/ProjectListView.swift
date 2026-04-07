import SwiftUI
import SwiftData
import OSLog
import UniformTypeIdentifiers

private let dragSourceLogger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.greyhoundforty.Charter",
    category: "DragDrop"
)

struct ProjectListView: View {
    @Environment(AppState.self) private var appState
    @Query private var allProjects: [Project]
    @State private var showNewProject = false

    private var filtered: [Project] {
        let base = allProjects.filter(\.isActive)
        let byFilter: [Project]
        if appState.selectedFolderIsUnsorted {
            byFilter = base.filter { $0.folder == nil }
        } else if let folder = appState.selectedFolder {
            byFilter = base.filter { $0.folder?.id == folder.id }
        } else if let label = appState.selectedLabel {
            byFilter = base.filter { $0.accountName == label }
        } else if let tag = appState.selectedTag {
            byFilter = base.filter { $0.tags.contains(tag) }
        } else if let stage = appState.selectedStage {
            byFilter = base.filter { $0.stage == stage }
        } else {
            byFilter = base
        }
        guard !appState.searchQuery.isEmpty else { return byFilter }
        let q = appState.searchQuery.lowercased()
        return byFilter.filter {
            $0.name.lowercased().contains(q) ||
            ($0.accountName?.lowercased().contains(q) ?? false) ||
            ($0.opportunityID?.lowercased().contains(q) ?? false) ||
            $0.tags.contains { $0.lowercased().contains(q) } ||
            $0.notes.contains { $0.content.lowercased().contains(q) } ||
            $0.stage.rawValue.lowercased().contains(q) ||
            $0.customFields.contains { $0.value.lowercased().contains(q) }
        }
    }

    private var navigationTitle: String {
        if appState.selectedFolderIsUnsorted { return "Unsorted" }
        if let folder = appState.selectedFolder { return folder.name }
        if let label = appState.selectedLabel { return label.replacingOccurrences(of: " ", with: "-") }
        if let tag = appState.selectedTag { return String(tag.dropFirst()) }
        return appState.selectedStage?.rawValue ?? "All Projects"
    }

    var body: some View {
        List {
            ForEach(filtered) { project in
                ProjectRowView(project: project, isSelected: appState.selectedProject?.id == project.id)
                    .contentShape(Rectangle())
                    .onDrag {
                        let payload = ProjectDragItem(id: project.id)
                        do {
                            let data = try JSONEncoder().encode(payload)
                            let provider = NSItemProvider()
                            provider.registerDataRepresentation(
                                forTypeIdentifier: UTType.charterProjectDragItem.identifier,
                                visibility: .all
                            ) { completion in
                                completion(data, nil)
                                return nil
                            }
                            dragSourceLogger.debug("Drag payload encoded for project=\(project.name, privacy: .public) id=\(project.id.uuidString, privacy: .public) bytes=\(data.count)")
                            return provider
                        } catch {
                            dragSourceLogger.error("Failed to encode drag payload for project=\(project.name, privacy: .public): \(error.localizedDescription, privacy: .public)")
                            return NSItemProvider(object: project.id.uuidString as NSString)
                        }
                    }
                    .onTapGesture {
                        dragSourceLogger.debug("Project row tapped: \(project.name, privacy: .public)")
                        appState.selectedProject = project
                    }
                    .listRowBackground(
                        appState.selectedProject?.id == project.id
                            ? Color.themeAqua.opacity(0.15)
                            : Color.clear
                    )
                    .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
            }
        }
        .listStyle(.inset)
        .frame(minWidth: 220)
        .navigationTitle(navigationTitle)
        .overlay {
            if filtered.isEmpty {
                ContentUnavailableView(
                    "No Projects",
                    systemImage: "briefcase",
                    description: Text("Create a project to get started.")
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showNewProject = true
                } label: {
                    Label("New Project", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .sheet(isPresented: $showNewProject) {
            NewProjectSheet()
        }
    }
}

struct ProjectRowView: View {
    let project: Project
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(project.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.themeFg)
                if project.isPOC {
                    Text("POC")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.themePurple)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.themeBg2)
                        .clipShape(Capsule())
                }
                Spacer()
                if let value = project.estimatedValueFormatted {
                    Text(value)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.themeGreen)
                }
            }
            HStack(spacing: 6) {
                if let account = project.accountName {
                    Text(account)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.themeFgDim)
                }
                if let folder = project.folder {
                    Label(folder.name, systemImage: "folder")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.themeBlue)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.themeBg2)
                        .clipShape(Capsule())
                }
                Spacer()
                Text(project.stage.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.themeStageColor(for: project.stage))
            }
        }
        .padding(.vertical, 4)
    }
}
