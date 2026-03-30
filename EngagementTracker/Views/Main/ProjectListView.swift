import SwiftUI
import SwiftData

struct ProjectListView: View {
    @Environment(AppState.self) private var appState
    @Query private var allProjects: [Project]
    @State private var showNewProject = false
    @State private var showExport = false
    @State private var showImport = false

    private var filtered: [Project] {
        let base = allProjects.filter(\.isActive)
        let byFilter: [Project]
        if let tag = appState.selectedTag {
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
            ($0.opportunityID?.lowercased().contains(q) ?? false)
        }
    }

    var body: some View {
        List {
            ForEach(filtered) { project in
                ProjectRowView(project: project, isSelected: appState.selectedProject?.id == project.id)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        appState.selectedProject = project
                    }
                    .listRowBackground(
                        appState.selectedProject?.id == project.id
                            ? Color.gruvAqua.opacity(0.15)
                            : Color.clear
                    )
                    .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
            }
        }
        .listStyle(.inset)
        .frame(minWidth: 220)
        .navigationTitle(appState.selectedTag.map { "#\($0)" } ?? appState.selectedStage?.rawValue ?? "All Projects")
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
            ToolbarItem {
                Button {
                    showExport = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .help("Export all projects")
            }
            ToolbarItem {
                Button {
                    showImport = true
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .help("Import projects")
            }
        }
        .sheet(isPresented: $showNewProject) {
            NewProjectSheet()
        }
        .sheet(isPresented: $showExport) {
            ExportSheet(scope: .allProjects)
        }
        .sheet(isPresented: $showImport) {
            ImportSheet()
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
                    .foregroundStyle(Color.gruvFg)
                if project.isPOC {
                    Text("POC")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.gruvPurple)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.gruvBg2)
                        .clipShape(Capsule())
                }
                Spacer()
                if let value = project.estimatedValueFormatted {
                    Text(value)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.gruvGreen)
                }
            }
            HStack(spacing: 6) {
                if let account = project.accountName {
                    Text(account)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.gruvFgDim)
                }
                Spacer()
                Text(project.stage.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.gruvStageColor(for: project.stage))
            }
        }
        .padding(.vertical, 4)
    }
}
