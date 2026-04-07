import Foundation
import SwiftData

@Model
final class Note {
    var id: UUID
    var title: String?
    var content: String
    var createdAt: Date

    var project: Project?

    init(title: String? = nil, content: String) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.createdAt = Date()
    }

    /// Restores a note from vault disk import with a fixed id.
    init(id: UUID, title: String?, content: String, createdAt: Date) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
    }
}
