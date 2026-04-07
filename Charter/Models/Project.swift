import Foundation
import SwiftData

@Model
final class Project {
    var id: UUID
    var name: String
    var summary: String?
    var accountName: String?
    var opportunityID: String?
    var stage: ProjectStage
    var isPOC: Bool
    var estimatedValueCents: Int?           // stored as cents to avoid Decimal SwiftData issues
    var targetCloseDate: Date?
    var tags: [String] = []
    var folder: ProjectFolder?
    var iscOpportunityLink: String?
    var gtmNavAccountLink: String?
    var oneDriveFolderLink: String?
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    /// Stable subfolder name under the on-disk vault root (`notes/`, `tasks/` inside). Assigned when vault I/O first runs.
    var vaultFolderName: String?
    /// Optional short code for routing reminders from a shared inbox (see `RemindersRouting`).
    var remindersCode: String?

    @Relationship(deleteRule: .cascade) var contacts: [Contact]
    @Relationship(deleteRule: .cascade) var checkpoints: [Checkpoint]
    @Relationship(deleteRule: .cascade) var tasks: [ProjectTask]
    @Relationship(deleteRule: .cascade) var engagements: [Engagement]
    @Relationship(deleteRule: .cascade) var notes: [Note]
    @Relationship(deleteRule: .cascade) var customFields: [ProjectCustomField] = []
    @Relationship(deleteRule: .cascade) var links: [ProjectLink] = []

    init(
        name: String,
        accountName: String? = nil,
        opportunityID: String? = nil,
        stage: ProjectStage = .discovery,
        isPOC: Bool = false,
        estimatedValueCents: Int? = nil,
        targetCloseDate: Date? = nil,
        tags: [String] = [],
        iscOpportunityLink: String? = nil,
        gtmNavAccountLink: String? = nil,
        oneDriveFolderLink: String? = nil,
        remindersCode: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.accountName = accountName
        self.opportunityID = opportunityID
        self.stage = stage
        self.isPOC = isPOC
        self.estimatedValueCents = estimatedValueCents
        self.targetCloseDate = targetCloseDate
        self.tags = tags
        self.iscOpportunityLink = iscOpportunityLink
        self.gtmNavAccountLink = gtmNavAccountLink
        self.oneDriveFolderLink = oneDriveFolderLink
        self.remindersCode = remindersCode
        self.isActive = true
        self.createdAt = Date()
        self.updatedAt = Date()
        self.contacts = []
        self.checkpoints = []
        self.tasks = []
        self.engagements = []
        self.notes = []
        self.customFields = []
        self.links = []
    }

    var estimatedValueFormatted: String? {
        guard let cents = estimatedValueCents else { return nil }
        let dollars = Double(cents) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: dollars))
    }
}

