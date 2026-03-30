import Foundation
import SwiftData

@Model
final class Engagement {
    var id: UUID
    var date: Date
    var summary: String
    var contactIDs: [UUID]      // IDs of Contact objects on this project
    var createdAt: Date

    var project: Project?

    init(date: Date = Date(), summary: String, contactIDs: [UUID] = []) {
        self.id = UUID()
        self.date = date
        self.summary = summary
        self.contactIDs = contactIDs
        self.createdAt = Date()
    }
}
