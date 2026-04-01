import SwiftUI
import SwiftData

// MARK: - CaptureType

enum CaptureType: String, CaseIterable, Identifiable {
    case engagement = "Engagement"
    case task = "Task"
    case note = "Note"
    var id: String { rawValue }
}

// MARK: - Save helpers (free functions — testable without ModelContext)

/// Creates an Engagement with the given properties and bumps project.updatedAt.
/// Caller is responsible for calling modelContext.insert() on the returned value.
func makeEngagement(summary: String, date: Date, for project: Project) -> Engagement {
    let e = Engagement(date: date, summary: summary)
    project.updatedAt = Date()
    return e
}

/// Creates a ProjectTask with the given properties and bumps project.updatedAt.
/// Caller is responsible for calling modelContext.insert() on the returned value.
func makeProjectTask(title: String, dueDate: Date?, for project: Project) -> ProjectTask {
    let t = ProjectTask(title: title, dueDate: dueDate)
    project.updatedAt = Date()
    return t
}

/// Creates a Note with the given properties and bumps project.updatedAt.
/// Caller is responsible for calling modelContext.insert() on the returned value.
func makeNote(title: String?, content: String, for project: Project) -> Note {
    let n = Note(title: title, content: content)
    project.updatedAt = Date()
    return n
}

// MARK: - QuickCaptureView

struct QuickCaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.updatedAt, order: .reverse) private var allProjects: [Project]

    @State private var captureType: CaptureType = .engagement
    @State private var selectedProject: Project?
    @State private var showProjectPicker = false

    // Engagement fields
    @State private var summary = ""
    @State private var engagementDate = Date()

    // Task fields
    @State private var taskTitle = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()

    // Note fields
    @State private var noteTitle = ""
    @State private var noteContent = ""

    private var activeProjects: [Project] { allProjects.filter(\.isActive) }

    private var canSave: Bool {
        guard selectedProject != nil else { return false }
        switch captureType {
        case .engagement: return !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .task:       return !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .note:       return !noteContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Zone 1: Type selector
            Picker("Capture type", selection: $captureType) {
                ForEach(CaptureType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .padding(.bottom, 8)

            // Zone 2: Form fields
            Group {
                switch captureType {
                case .engagement:
                    VStack(alignment: .leading, spacing: 6) {
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $summary)
                                .font(.system(size: 12))
                                .frame(height: 60)
                                .scrollContentBackground(.hidden)
                                .background(Color.themeBg1)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            if summary.isEmpty {
                                Text("Summary…")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.themeFgDim)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 8)
                                    .allowsHitTesting(false)
                            }
                        }
                        DatePicker("Date", selection: $engagementDate, displayedComponents: .date)
                            .font(.system(size: 12))
                            .datePickerStyle(.compact)
                    }

                case .task:
                    VStack(alignment: .leading, spacing: 6) {
                        TextField("Title", text: $taskTitle)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                            .padding(6)
                            .background(Color.themeBg1)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Toggle("Add due date", isOn: $hasDueDate)
                            .font(.system(size: 12))
                        if hasDueDate {
                            DatePicker("Due", selection: $dueDate,
                                       displayedComponents: [.date, .hourAndMinute])
                                .font(.system(size: 12))
                                .datePickerStyle(.compact)
                        }
                    }

                case .note:
                    VStack(alignment: .leading, spacing: 6) {
                        TextField("Title (optional)", text: $noteTitle)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                            .padding(6)
                            .background(Color.themeBg1)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $noteContent)
                                .font(.system(size: 12))
                                .frame(height: 60)
                                .scrollContentBackground(.hidden)
                                .background(Color.themeBg1)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            if noteContent.isEmpty {
                                Text("Content…")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.themeFgDim)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 8)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 10)

            // Zone 3: Project row + Save
            HStack(spacing: 8) {
                if showProjectPicker {
                    Picker("Project", selection: $selectedProject) {
                        ForEach(activeProjects) { project in
                            Text(project.name).tag(Optional(project))
                        }
                    }
                    .pickerStyle(.menu)
                    .font(.system(size: 12))
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.themeStageColor(for: selectedProject?.stage ?? .discovery))
                            .frame(width: 7, height: 7)
                        Text(selectedProject?.name ?? "No project")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.themeFg)
                            .lineLimit(1)
                        Text(selectedProject?.stage.rawValue ?? "")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.themeFgDim)
                            .lineLimit(1)
                        Button("change") {
                            showProjectPicker = true
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 10))
                        .foregroundStyle(Color.themeBlue)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button("Save") {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.themeAqua)
                .disabled(!canSave)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .onAppear {
            if selectedProject == nil {
                selectedProject = activeProjects.first
            }
        }
        .onChange(of: activeProjects) { _, newValue in
            if selectedProject == nil, let first = newValue.first {
                selectedProject = first
            }
        }
        .onChange(of: selectedProject) { old, new in
            if old != new { showProjectPicker = false }
        }
    }

    private func save() {
        guard let project = selectedProject else { return }
        switch captureType {
        case .engagement:
            let e = makeEngagement(summary: summary.trimmingCharacters(in: .whitespacesAndNewlines), date: engagementDate, for: project)
            modelContext.insert(e)
            project.engagements.append(e)
            try? modelContext.save()
            summary = ""
            engagementDate = Date()
        case .task:
            let t = makeProjectTask(title: taskTitle.trimmingCharacters(in: .whitespacesAndNewlines), dueDate: hasDueDate ? dueDate : nil, for: project)
            modelContext.insert(t)
            project.tasks.append(t)
            try? modelContext.save()
            taskTitle = ""
            hasDueDate = false
            dueDate = Date()
        case .note:
            let trimmedTitle = noteTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            let n = makeNote(
                title: trimmedTitle.isEmpty ? nil : trimmedTitle,
                content: noteContent,
                for: project
            )
            modelContext.insert(n)
            project.notes.append(n)
            try? modelContext.save()
            noteTitle = ""
            noteContent = ""
        }
    }
}
