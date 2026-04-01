// EngagementTrackerTests/ImportServiceTests.swift
import Foundation
import Testing
@testable import Manifest

@Suite("ImportService")
struct ImportServiceTests {

    @Test("JSON import round-trips through ExportService")
    func jsonRoundTrip() throws {
        let original = ExportedProject(
            name: "Round Trip", accountName: "ACME", opportunityID: nil,
            stage: "Proposal", isPOC: false, estimatedValueCents: nil,
            targetCloseDate: nil, tags: ["openshift"], iscOpportunityLink: "",
            gtmNavAccountLink: "", oneDriveFolderLink: "",
            contacts: [], tasks: [], notes: [], engagements: [], checkpoints: []
        )
        let data = try ExportService.encodeJSON([original])
        let results = ImportService.parseJSON(data)
        #expect(results.count == 1)
        if case .success(let p) = results[0] {
            #expect(p.name == "Round Trip")
            #expect(p.tags == ["openshift"])
        } else {
            Issue.record("Expected success but got failure")
        }
    }

    @Test("JSON import with unknown stage maps to failure")
    func unknownStage() throws {
        let original = ExportedProject(
            name: "Bad Stage", accountName: nil, opportunityID: nil,
            stage: "NotAStage", isPOC: false, estimatedValueCents: nil,
            targetCloseDate: nil, tags: [], iscOpportunityLink: "",
            gtmNavAccountLink: "", oneDriveFolderLink: "",
            contacts: [], tasks: [], notes: [], engagements: [], checkpoints: []
        )
        let data = try ExportService.encodeJSON([original])
        let results = ImportService.parseJSON(data)
        #expect(results.count == 1)
        if case .failure(let name, _) = results[0] {
            #expect(name == "Bad Stage")
        } else {
            Issue.record("Expected failure for unknown stage")
        }
    }

    @Test("Malformed JSON returns empty results without crashing")
    func malformedJSON() {
        let garbage = Data("not json at all".utf8)
        let results = ImportService.parseJSON(garbage)
        #expect(results.isEmpty)
    }

    @Test("CSV projects.csv parses name and stage")
    func csvProjectsParse() {
        let csv = "name,accountName,stage,isPOC,estimatedValueCents,targetCloseDate,tags,iscOpportunityLink,gtmNavAccountLink,oneDriveFolderLink,opportunityID\nTest Project,Acme,Discovery,false,,,,,,"
        let results = ImportService.parseProjectsCSV(csv)
        #expect(results.count == 1)
        if case .success(let p) = results[0] {
            #expect(p.name == "Test Project")
            #expect(p.stage == "Discovery")
        }
    }

    @Test("CSV row with quoted comma in name parses correctly")
    func csvQuotedField() {
        let csv = "name,accountName,stage,isPOC,estimatedValueCents,targetCloseDate,tags,iscOpportunityLink,gtmNavAccountLink,oneDriveFolderLink,opportunityID\n\"Project, Special\",Acme,Discovery,false,,,,,,"
        let results = ImportService.parseProjectsCSV(csv)
        #expect(results.count == 1)
        if case .success(let p) = results[0] {
            #expect(p.name == "Project, Special")
        }
    }
}
