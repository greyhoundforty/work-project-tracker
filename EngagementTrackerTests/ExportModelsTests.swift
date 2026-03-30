// EngagementTrackerTests/ExportModelsTests.swift
import Foundation
import Testing
@testable import EngagementTracker

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

    @Test("ExportedContact encodes internalRole as optional string")
    func contactEncoding() throws {
        let c = ExportedContact(name: "Jane", title: "AE", email: "jane@ibm.com",
                                type: "Internal (IBM)", internalRole: "Account Executive")
        let data = try JSONEncoder().encode(c)
        let decoded = try JSONDecoder().decode(ExportedContact.self, from: data)
        #expect(decoded.internalRole == "Account Executive")
    }
}
