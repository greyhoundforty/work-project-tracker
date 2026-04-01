import Foundation
import SwiftData

@Model
final class Contact {
    var id: UUID
    var name: String
    var title: String?
    var email: String?
    var type: ContactType
    var internalRole: InternalRole?
    var createdAt: Date

    var project: Project?

    init(
        name: String,
        title: String? = nil,
        email: String? = nil,
        type: ContactType,
        internalRole: InternalRole? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.title = title
        self.email = email
        self.type = type
        self.internalRole = internalRole
        self.createdAt = Date()
    }
}
