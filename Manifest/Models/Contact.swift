import Foundation
import SwiftData

@Model
final class Contact {
    var id: UUID
    var name: String
    var role: String?
    var title: String?
    var email: String?
    var notes: String?
    var type: ContactType
    var createdAt: Date

    var project: Project?

    init(
        name: String,
        role: String? = nil,
        title: String? = nil,
        email: String? = nil,
        notes: String? = nil,
        type: ContactType
    ) {
        self.id = UUID()
        self.name = name
        self.role = role
        self.title = title
        self.email = email
        self.notes = notes
        self.type = type
        self.createdAt = Date()
    }
}
