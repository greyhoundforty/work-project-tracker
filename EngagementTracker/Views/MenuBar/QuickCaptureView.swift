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

// MARK: - QuickCaptureView (stub — implemented in Task 3)

struct QuickCaptureView: View {
    var body: some View { EmptyView() }
}
