// EngagementTrackerTests/ExportModelsTests.swift
import Foundation
import Testing
@testable import Charter

@Suite("ExportModels")
struct ExportModelsTests {
    @Test("ExportBundle round-trips through JSON")
    func roundTripJSON() throws {
        let bundle = ExportBundle(
            exportVersion: "1",
            exportDate: Date(timeIntervalSince1970: 0),
            projects: [
                ExportedProject(
                    name: "Test Opp",
                    accountName: "Acme",
                    opportunityID: "OPP-1",
                    stage: "Discovery",
                    isPOC: false,
                    estimatedValueCents: 50000,
                    targetCloseDate: nil,
                    tags: ["vpc", "powervs"],
                    iscOpportunityLink: "https://isc.example.com",
                    gtmNavAccountLink: "",
                    oneDriveFolderLink: "",
                    contacts: [],
                    tasks: [],
                    notes: [],
                    engagements: [],
                    checkpoints: []
                )
            ]
        )
        let data = try JSONEncoder().encode(bundle)
        let decoded = try JSONDecoder().decode(ExportBundle.self, from: data)
        #expect(decoded.projects.count == 1)
        #expect(decoded.projects[0].name == "Test Opp")
        #expect(decoded.projects[0].tags == ["vpc", "powervs"])
        #expect(decoded.exportVersion == "1")
    }

    @Test("ExportedContact encodes type as string")
    func contactEncoding() throws {
        let c = ExportedContact(name: "Jane", title: "AE", email: "jane@ibm.com",
                                type: "Internal")
        let data = try JSONEncoder().encode(c)
        let decoded = try JSONDecoder().decode(ExportedContact.self, from: data)
        #expect(decoded.type == "Internal")
        #expect(decoded.name == "Jane")
    }

    @Test("ExportedTask round-trips through JSON")
    func exportedTaskRoundTrip() throws {
        let date = Date(timeIntervalSince1970: 0)
        let task = ExportedTask(title: "Send BOM", isCompleted: true,
                                completedAt: date, createdAt: date)
        let data = try JSONEncoder().encode(task)
        let decoded = try JSONDecoder().decode(ExportedTask.self, from: data)
        #expect(decoded.title == "Send BOM")
        #expect(decoded.isCompleted == true)
    }

    @Test("ExportedNote with title round-trips through JSON")
    func exportedNoteWithTitle() throws {
        let date = Date(timeIntervalSince1970: 0)
        let note = ExportedNote(title: "Meeting Summary",
                                content: "Key points discussed", createdAt: date)
        let data = try JSONEncoder().encode(note)
        let decoded = try JSONDecoder().decode(ExportedNote.self, from: data)
        #expect(decoded.title == "Meeting Summary")
        #expect(decoded.content == "Key points discussed")
    }

    @Test("ExportedNote with nil title round-trips through JSON")
    func exportedNoteNilTitle() throws {
        let date = Date(timeIntervalSince1970: 0)
        let note = ExportedNote(title: nil, content: "No title note", createdAt: date)
        let data = try JSONEncoder().encode(note)
        let decoded = try JSONDecoder().decode(ExportedNote.self, from: data)
        #expect(decoded.title == nil)
        #expect(decoded.content == "No title note")
    }

    @Test("ExportedEngagement round-trips through JSON")
    func exportedEngagementRoundTrip() throws {
        let date = Date(timeIntervalSince1970: 0)
        let eng = ExportedEngagement(date: date, summary: "Quarterly review",
                                     contactNames: ["Alice", "Bob"])
        let data = try JSONEncoder().encode(eng)
        let decoded = try JSONDecoder().decode(ExportedEngagement.self, from: data)
        #expect(decoded.summary == "Quarterly review")
        #expect(decoded.contactNames == ["Alice", "Bob"])
    }

    @Test("ExportedCheckpoint round-trips through JSON")
    func exportedCheckpointRoundTrip() throws {
        let cp = ExportedCheckpoint(title: "Proposal drafted", stage: "Proposal",
                                    sortOrder: 0, isCompleted: false, completedAt: nil)
        let data = try JSONEncoder().encode(cp)
        let decoded = try JSONDecoder().decode(ExportedCheckpoint.self, from: data)
        #expect(decoded.title == "Proposal drafted")
        #expect(decoded.stage == "Proposal")
        #expect(decoded.sortOrder == 0)
        #expect(decoded.isCompleted == false)
        #expect(decoded.completedAt == nil)
    }

    @Test("ExportBundle exportVersion is preserved in round-trip")
    func exportBundleVersion() throws {
        let bundle = ExportBundle(exportVersion: "2", exportDate: Date(timeIntervalSince1970: 0),
                                  projects: [])
        let data = try JSONEncoder().encode(bundle)
        let decoded = try JSONDecoder().decode(ExportBundle.self, from: data)
        #expect(decoded.exportVersion == "2")
        #expect(decoded.projects.isEmpty)
    }
}
