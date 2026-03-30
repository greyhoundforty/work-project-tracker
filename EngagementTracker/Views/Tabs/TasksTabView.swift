import SwiftUI
import SwiftData

struct TasksTabView: View {
    @Environment(\.modelContext) private var context
    let project: Project

    @State private var newTaskTitle: String = ""
    @State private var showCompleted: Bool = false

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
                        .foregroundStyle(Color.gruvAqua)
                }
                .disabled(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.gruvBg1)

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
                                    .foregroundStyle(Color.gruvFgDim)
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
    }

    private func addTask() {
        let title = newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        let task = ProjectTask(title: title)
        context.insert(task)
        project.tasks.append(task)
        project.updatedAt = Date()
        newTaskTitle = ""
    }

    private func delete(_ task: ProjectTask) {
        project.tasks.removeAll { $0.id == task.id }
        context.delete(task)
    }
}

struct TaskRowView: View {
    let task: ProjectTask
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button {
                task.toggle()
                task.project?.updatedAt = Date()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isCompleted ? Color.gruvGreen : Color.gruvBg3)
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)

            Text(task.title)
                .font(.system(size: 13))
                .foregroundStyle(task.isCompleted ? Color.gruvFgDim : Color.gruvFg)
                .strikethrough(task.isCompleted, color: Color.gruvFgDim)
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(Color.gruvRed)
            }
            .buttonStyle(.plain)
            .opacity(0.6)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
