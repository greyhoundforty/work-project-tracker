import SwiftUI
import SwiftData

struct TasksTabView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @Environment(RemindersService.self) private var remindersService
    let project: Project

    @State private var newTaskTitle: String = ""
    @State private var showCompleted: Bool = false
    @State private var isImporting: Bool = false
    @State private var lastImportCount: Int? = nil

    private var pendingTasks: [ProjectTask] {
        project.tasks.filter { !$0.isCompleted }.sorted { $0.createdAt < $1.createdAt }
    }
    private var completedTasks: [ProjectTask] {
        project.tasks.filter(\.isCompleted).sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Add task row
            HStack {
                TextField("Add a task…", text: $newTaskTitle)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { addTask() }
                Button(action: addTask) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.themeAqua)
                }
                .disabled(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(.plain)

                if appState.remindersListID != nil {
                    Divider()
                        .frame(height: 16)
                        .padding(.horizontal, 2)
                    Button {
                        importFromReminders()
                    } label: {
                        if isImporting {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Label("Import all into this project", systemImage: "tray.and.arrow.down")
                                .font(.system(size: 12))
                        }
                    }
                    .buttonStyle(.borderless)
                    .disabled(isImporting || !remindersService.isAuthorized)
                    .help("Imports every incomplete reminder from the Settings inbox list into this project only. For routing by project code, use Settings → Import Routed Reminders.")
                }
            }
            .padding()
            .background(Color.themeBg1)

            if let count = lastImportCount {
                HStack {
                    Image(systemName: count > 0 ? "checkmark.circle" : "info.circle")
                        .foregroundStyle(count > 0 ? Color.themeGreen : Color.themeFgDim)
                    Text(count > 0 ? "Imported \(count) task\(count == 1 ? "" : "s") from Reminders" : "No new tasks to import")
                        .font(.system(size: 11))
                        .foregroundStyle(count > 0 ? Color.themeGreen : Color.themeFgDim)
                    Spacer()
                    Button {
                        lastImportCount = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.themeFgDim)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(Color.themeBg2)
            }

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(pendingTasks) { task in
                        TaskRowView(task: task, onDelete: { delete(task) })
                        Divider().padding(.leading, 42)
                    }

                    if !completedTasks.isEmpty {
                        Button {
                            showCompleted.toggle()
                        } label: {
                            HStack {
                                Text(showCompleted ? "Hide Completed" : "Show Completed (\(completedTasks.count))")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.themeFgDim)
                                Spacer()
                            }
                            .padding()
                        }
                        .buttonStyle(.plain)

                        if showCompleted {
                            ForEach(completedTasks) { task in
                                TaskRowView(task: task, onDelete: { delete(task) })
                                Divider().padding(.leading, 42)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            try? VaultService.syncTasks(project: project, context: context, appState: appState)
        }
    }

    private func addTask() {
        let title = newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        let task = ProjectTask(title: title)
        context.insert(task)
        project.tasks.append(task)
        project.updatedAt = Date()
        try? context.save()
        try? VaultService.writeTask(task, project: project, appState: appState)
        newTaskTitle = ""
    }

    private func importFromReminders() {
        guard let listID = appState.remindersListID, !isImporting else { return }
        isImporting = true
        lastImportCount = nil
        Task { @MainActor in
            let count = await remindersService.importPendingReminders(
                fromListWithID: listID,
                into: project,
                context: context,
                markCompleted: appState.remindersMarkCompleted
            )
            isImporting = false
            lastImportCount = count
            if count > 0 {
                try? VaultService.mirrorAllTasksToVault(project: project, appState: appState)
            }
        }
    }

    private func delete(_ task: ProjectTask) {
        try? VaultService.deleteTaskFile(task, project: project, appState: appState)
        project.tasks.removeAll { $0.id == task.id }
        context.delete(task)
        try? context.save()
    }
}

struct TaskRowView: View {
    let task: ProjectTask
    let onDelete: () -> Void
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 10) {
            Button {
                task.toggle()
                task.project?.updatedAt = Date()
                try? context.save()
                if let p = task.project {
                    try? VaultService.writeTask(task, project: p, appState: appState)
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isCompleted ? Color.themeGreen : Color.themeBg3)
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)

            Text(task.title)
                .font(.system(size: 13))
                .foregroundStyle(task.isCompleted ? Color.themeFgDim : Color.themeFg)
                .strikethrough(task.isCompleted, color: Color.themeFgDim)
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(Color.themeRed)
            }
            .buttonStyle(.plain)
            .opacity(0.6)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
