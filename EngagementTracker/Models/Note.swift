import Foundation
import SwiftData

@Model
final class Note {
    var id: UUID
    var content: String
    var createdAt: Date

    var project: Project?

    init(content: String) {
        self.id = UUID()
        self.content = content
        self.createdAt = Date()
    }
}
