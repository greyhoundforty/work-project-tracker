import Foundation
import SwiftData

@Model
final class ProjectFolder {
    var id: UUID
    var name: String
    var sortOrder: Int
    var parent: ProjectFolder?

    @Relationship(deleteRule: .nullify, inverse: \Project.folder)
    var projects: [Project] = []

    init(name: String, sortOrder: Int = 0, parent: ProjectFolder? = nil) {
        self.id = UUID()
        self.name = name
        self.sortOrder = sortOrder
        self.parent = parent
    }
}
