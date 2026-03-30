import SwiftUI

struct ProjectDetailView: View {
    let project: Project
    @State private var selectedTab: String = "overview"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ProjectDetailHeaderView(project: project)
            Divider()
            TabView(selection: $selectedTab) {
                OverviewTabView(project: project)
                    .tabItem { Label("Overview", systemImage: "square.text.square") }
                    .tag("overview")
                CheckpointsTabView(project: project)
                    .tabItem { Label("Checkpoints", systemImage: "checklist") }
                    .tag("checkpoints")
                TasksTabView(project: project)
                    .tabItem { Label("Tasks", systemImage: "checkmark.square") }
                    .tag("tasks")
                ContactsTabView(project: project)
                    .tabItem { Label("Contacts", systemImage: "person.2") }
                    .tag("contacts")
                EngagementsTabView(project: project)
                    .tabItem { Label("Engagements", systemImage: "bubble.left.and.bubble.right") }
                    .tag("engagements")
                NotesTabView(project: project)
                    .tabItem { Label("Notes", systemImage: "note.text") }
                    .tag("notes")
            }
        }
        .background(Color.gruvBg)
    }
}

struct ProjectDetailHeaderView: View {
    let project: Project
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState

    @State private var showStagePicker = false
    @State private var showDeleteConfirm = false
    @State private var showExport = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(project.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.gruvFg)
                Spacer()
                Button {
                    showExport = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(Color.gruvBlue)
                }
                .buttonStyle(.plain)
                .help("Export this project")
                .sheet(isPresented: $showExport) {
                    ExportSheet(scope: .singleProject(project))
                }
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(Color.gruvRed)
                }
                .buttonStyle(.plain)
                .help("Delete project")

                if !project.stage.isTerminal, let next = project.stage.next {
                    Button("Advance to \(next.rawValue)") {
                        setStage(next)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.gruvStageColor(for: next))
                }
            }
            HStack(spacing: 8) {
                // Clickable stage pill opens a stage picker popover
                Button {
                    showStagePicker = true
                } label: {
                    Text("● \(project.stage.rawValue)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.gruvStageColor(for: project.stage))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.gruvBg2)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.gruvBg3.opacity(0.5), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .help("Change stage")
                .popover(isPresented: $showStagePicker, arrowEdge: .bottom) {
                    StagePickerPopover(current: project.stage) { chosen in
                        setStage(chosen)
                        showStagePicker = false
                    }
                }

                if project.isPOC {
                    TagPill(label: "POC", color: .gruvPurple)
                }
                if let value = project.estimatedValueFormatted {
                    TagPill(label: value, color: .gruvGreen)
                }
                if let account = project.accountName {
                    TagPill(label: account, color: .gruvFgDim)
                }
                if let closeDate = project.targetCloseDate {
                    TagPill(label: "Close: \(closeDate.formatted(date: .abbreviated, time: .omitted))", color: .gruvFgDim)
                }
            }
        }
        .padding()
        .background(Color.gruvBg1)
        .alert("Delete \"\(project.name)\"?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { deleteProject() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the project and all its data.")
        }
    }

    private func setStage(_ stage: ProjectStage) {
        project.stage = stage
        project.updatedAt = Date()
        appState.selectedStage = stage
        try? context.save()
    }

    private func deleteProject() {
        appState.selectedProject = nil
        context.delete(project)
        try? context.save()
    }
}

struct StagePickerPopover: View {
    let current: ProjectStage
    let onSelect: (ProjectStage) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Move to stage")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.gruvFgDim)
                .padding(.horizontal, 12)
                .padding(.top, 10)

            Divider()

            ForEach(ProjectStage.allCases) { stage in
                Button {
                    onSelect(stage)
                } label: {
                    HStack {
                        Text("● \(stage.rawValue)")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.gruvStageColor(for: stage))
                        Spacer()
                        if stage == current {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.gruvFgDim)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(stage == current ? Color.gruvBg2 : Color.clear)
            }

            Spacer(minLength: 6)
        }
        .frame(width: 180)
        .background(Color.gruvBg1)
    }
}

struct TagPill: View {
    let label: String
    let color: Color
    var body: some View {
        Text(label)
            .font(.system(size: 11))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.gruvBg2)
            .clipShape(Capsule())
    }
}
