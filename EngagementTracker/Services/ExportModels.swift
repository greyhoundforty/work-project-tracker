// EngagementTracker/Services/ExportModels.swift
import Foundation

struct ExportBundle: Codable {
    let exportVersion: String
    let exportDate: Date
    let projects: [ExportedProject]
}

struct ExportedProject: Codable {
    var name: String
    var accountName: String?
    var opportunityID: String?
    var stage: String                // raw value of ProjectStage
    var isPOC: Bool
    var estimatedValueCents: Int?
    var targetCloseDate: Date?
    var tags: [String]
    var iscOpportunityLink: String
    var gtmNavAccountLink: String
    var oneDriveFolderLink: String
    var contacts: [ExportedContact]
    var tasks: [ExportedTask]
    var notes: [ExportedNote]
    var engagements: [ExportedEngagement]
    var checkpoints: [ExportedCheckpoint]
}

struct ExportedContact: Codable {
    var name: String
    var title: String?
    var email: String?
    var type: String                 // raw value of ContactType
    var internalRole: String?        // raw value of InternalRole, nil for non-IBM
}

struct ExportedTask: Codable {
    var title: String
    var isCompleted: Bool
    var completedAt: Date?
    var createdAt: Date
}

struct ExportedNote: Codable {
    var content: String
    var createdAt: Date
}

struct ExportedEngagement: Codable {
    var date: Date
    var summary: String
    var contactNames: [String]       // resolved at export time from contactIDs
}

struct ExportedCheckpoint: Codable {
    var title: String
    var stage: String
    var sortOrder: Int
    var isCompleted: Bool
    var completedAt: Date?
}
