import Foundation
import SwiftData

@Model
final class ProjectTask {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var completedAt: Date?
    var dueDate: Date?
    var createdAt: Date

    var project: Project?

    init(title: String, dueDate: Date? = nil) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.completedAt = nil
        self.dueDate = dueDate
        self.createdAt = Date()
    }

    /// Restores a task from vault disk import with a fixed id.
    init(
        id: UUID,
        title: String,
        isCompleted: Bool,
        completedAt: Date?,
        dueDate: Date?,
        createdAt: Date
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.dueDate = dueDate
        self.createdAt = createdAt
    }

    func toggle() {
        isCompleted.toggle()
        completedAt = isCompleted ? Date() : nil
    }
}
