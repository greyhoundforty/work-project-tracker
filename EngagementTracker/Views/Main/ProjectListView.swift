import SwiftUI
import SwiftData

struct ProjectListView: View {
    @Environment(AppState.self) private var appState
    @Query private var allProjects: [Project]
    @State private var showNewProject = false

    private var filtered: [Project] {
        let base = allProjects.filter(\.isActive)
        let byStage: [Project]
        if let stage = appState.selectedStage {
            byStage = base.filter { $0.stage == stage }
        } else {
            byStage = base
        }
        guard !appState.searchQuery.isEmpty else { return byStage }
        let q = appState.searchQuery.lowercased()
        return byStage.filter {
            $0.name.lowercased().contains(q) ||
            ($0.accountName?.lowercased().contains(q) ?? false) ||
            ($0.opportunityID?.lowercased().contains(q) ?? false)
        }
    }

    var body: some View {
        @Bindable var appState = appState
        List(filtered, selection: $appState.selectedProject) { project in
            ProjectRowView(project: project)
                .tag(project)
        }
        .listStyle(.inset)
        .frame(minWidth: 220)
        .navigationTitle(appState.selectedStage?.rawValue ?? "All Projects")
        .overlay {
            if filtered.isEmpty {
                ContentUnavailableView("No Projects", systemImage: "briefcase", description: Text("Create a project to get started."))
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
