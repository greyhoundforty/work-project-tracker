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
}
