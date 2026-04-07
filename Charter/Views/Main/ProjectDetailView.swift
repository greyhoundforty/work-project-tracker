import SwiftUI

struct ProjectDetailView: View {
    let project: Project
    @Environment(AppState.self) private var appState
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
        .background(Color.themeBg)
        .onAppear { applyPendingDetailTabIfNeeded() }
        .onChange(of: appState.pendingProjectDetailTab) { _, _ in
            applyPendingDetailTabIfNeeded()
        }
    }

    private func applyPendingDetailTabIfNeeded() {
        guard let tab = appState.pendingProjectDetailTab else { return }
        selectedTab = tab
        appState.pendingProjectDetailTab = nil
    }
}

struct ProjectDetailHeaderView: View {
    let project: Project
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState

    @State private var showStagePicker = false
    @State private var showDeleteConfirm = false
    @State private var showExport = false
    @State private var showTagEditor = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(project.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.themeFg)
                Spacer()
                Button {
                    showExport = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(Color.themeBlue)
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
                        .foregroundStyle(Color.themeRed)
                }
                .buttonStyle(.plain)
                .help("Delete project")

                if !project.stage.isTerminal, let next = project.stage.next {
                    Button("Advance to \(next.rawValue)") {
                        setStage(next)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.themeStageColor(for: next))
                }
            }
            HStack(spacing: 8) {
                // Clickable stage pill opens a stage picker popover
                Button {
                    showStagePicker = true
                } label: {
                    Text("● \(project.stage.rawValue)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.themeStageColor(for: project.stage))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.themeBg2)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.themeBg3.opacity(0.5), lineWidth: 1)
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
                    TagPill(label: "POC", color: .themePurple)
                }
                if let value = project.estimatedValueFormatted {
                    TagPill(label: value, color: .themeGreen)
                }
                if let account = project.accountName {
                    TagPill(label: account.replacingOccurrences(of: " ", with: "-"), color: .themeBlue)
                }
                if let closeDate = project.targetCloseDate {
                    TagPill(label: "Close: \(closeDate.formatted(date: .abbreviated, time: .omitted))", color: .themeFgDim)
                }
                let projectTags = project.tags.filter { $0.hasPrefix("#") }
                if !projectTags.isEmpty {
                    Text("|")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.themeFgDim)
                    ForEach(projectTags, id: \.self) { tag in
                        TagPill(label: String(tag.dropFirst()), color: .themeYellow)
                    }
                }
                Button {
                    showTagEditor = true
                } label: {
                    Image(systemName: "tag")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.themeFgDim)
                }
                .buttonStyle(.plain)
                .help("Edit tags")
                .popover(isPresented: $showTagEditor, arrowEdge: .bottom) {
                    TagsEditorPopover(project: project)
                }
            }
        }
        .padding()
        .background(Color.themeBg1)
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
        appState.pendingProjectDetailTab = nil
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
                .foregroundStyle(Color.themeFgDim)
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
                            .foregroundStyle(Color.themeStageColor(for: stage))
                        Spacer()
                        if stage == current {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.themeFgDim)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(stage == current ? Color.themeBg2 : Color.clear)
            }

            Spacer(minLength: 6)
        }
        .frame(width: 180)
        .background(Color.themeBg1)
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
            .background(Color.themeBg2)
            .clipShape(Capsule())
    }
}

struct TagsEditorPopover: View {
    let project: Project
    @Environment(\.modelContext) private var context
    @State private var newTag: String = ""

    private var tags: [String] { project.tags.filter { $0.hasPrefix("#") } }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Edit Tags")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.themeFgDim)
                .padding(.horizontal, 12)
                .padding(.top, 10)

            Divider()

            if tags.isEmpty {
                Text("No tags yet")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.themeFgDim)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
            } else {
                ForEach(tags, id: \.self) { tag in
                    HStack {
                        Text(String(tag.dropFirst()))
                            .font(.system(size: 13))
                            .foregroundStyle(Color.themeYellow)
                        Spacer()
                        Button {
                            removeTag(tag)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.themeFgDim)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                }
            }

            Divider()

            HStack(spacing: 6) {
                TextField("Add tag", text: $newTag)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
                    .onSubmit { addTag() }
                Button("Add") { addTag() }
                    .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 200)
        .background(Color.themeBg1)
    }

    private func addTag() {
        let raw = newTag.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard !raw.isEmpty else { return }
        let tag = "#\(raw)"
        guard !project.tags.contains(tag) else { newTag = ""; return }
        project.tags.append(tag)
        project.updatedAt = Date()
        try? context.save()
        newTag = ""
    }

    private func removeTag(_ tag: String) {
        project.tags.removeAll { $0 == tag }
        project.updatedAt = Date()
        try? context.save()
    }
}
