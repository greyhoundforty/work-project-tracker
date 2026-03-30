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

    func toggle() {
        isCompleted.toggle()
        completedAt = isCompleted ? Date() : nil
    }
}
