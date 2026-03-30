import Foundation
import SwiftData

@Model
final class Checkpoint {
    var id: UUID
    var title: String
    var stage: ProjectStage
    var isCompleted: Bool
    var completedAt: Date?
    var sortOrder: Int

    var project: Project?

    init(title: String, stage: ProjectStage, sortOrder: Int) {
        self.id = UUID()
        self.title = title
        self.stage = stage
        self.isCompleted = false
        self.completedAt = nil
        self.sortOrder = sortOrder
    }

    func toggle() {
        isCompleted.toggle()
        completedAt = isCompleted ? Date() : nil
    }
}
