// EngagementTrackerTests/ImportServiceTests.swift
import Foundation
import Testing
@testable import Charter

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

    // MARK: - parseCSVRows edge cases

    @Test("parseCSVRows returns empty array for empty string")
    func parseCSVRowsEmpty() {
        let rows = ImportService.parseCSVRows("")
        #expect(rows.isEmpty)
    }

    @Test("parseCSVRows parses single row without trailing newline")
    func parseCSVRowsSingleRow() {
        let rows = ImportService.parseCSVRows("a,b,c")
        #expect(rows.count == 1)
        #expect(rows[0] == ["a", "b", "c"])
    }

    @Test("parseCSVRows parses two rows separated by newline")
    func parseCSVRowsTwoRows() {
        let rows = ImportService.parseCSVRows("header1,header2\nval1,val2")
        #expect(rows.count == 2)
        #expect(rows[0] == ["header1", "header2"])
        #expect(rows[1] == ["val1", "val2"])
    }

    @Test("parseCSVRows handles CRLF line endings")
    func parseCSVRowsCRLF() {
        let rows = ImportService.parseCSVRows("a,b\r\nc,d")
        #expect(rows.count == 2)
        #expect(rows[0] == ["a", "b"])
        #expect(rows[1] == ["c", "d"])
    }

    @Test("parseCSVRows handles quoted field containing a comma")
    func parseCSVRowsQuotedComma() {
        let rows = ImportService.parseCSVRows("\"hello, world\",b")
        #expect(rows.count == 1)
        #expect(rows[0][0] == "hello, world")
        #expect(rows[0][1] == "b")
    }

    @Test("parseCSVRows handles escaped double-quote inside quoted field")
    func parseCSVRowsEscapedQuote() {
        let rows = ImportService.parseCSVRows("\"say \"\"hi\"\"\",b")
        #expect(rows.count == 1)
        #expect(rows[0][0] == "say \"hi\"")
        #expect(rows[0][1] == "b")
    }

    // MARK: - parseProjectsCSV additional cases

    @Test("CSV with empty name returns failure result")
    func csvMissingName() {
        let csv = "name,accountName,stage,isPOC,estimatedValueCents,targetCloseDate,tags,iscOpportunityLink,gtmNavAccountLink,oneDriveFolderLink,opportunityID\n,Acme,Discovery,false,,,,,,"
        let results = ImportService.parseProjectsCSV(csv)
        #expect(results.count == 1)
        if case .failure(let name, _) = results[0] {
            #expect(name == "(unnamed row)")
        } else {
            Issue.record("Expected failure for missing name")
        }
    }

    @Test("CSV with header only returns empty results")
    func csvHeaderOnly() {
        let csv = "name,accountName,stage"
        let results = ImportService.parseProjectsCSV(csv)
        #expect(results.isEmpty)
    }

    @Test("CSV parses isPOC=true correctly")
    func csvIsPOCTrue() {
        let csv = "name,accountName,stage,isPOC,estimatedValueCents,targetCloseDate,tags,iscOpportunityLink,gtmNavAccountLink,oneDriveFolderLink,opportunityID\nPOC Project,Acme,Discovery,true,,,,,,"
        let results = ImportService.parseProjectsCSV(csv)
        #expect(results.count == 1)
        if case .success(let p) = results[0] {
            #expect(p.isPOC == true)
        } else {
            Issue.record("Expected success")
        }
    }

    @Test("CSV parses estimatedValueCents correctly")
    func csvEstimatedValue() {
        let csv = "name,accountName,stage,isPOC,estimatedValueCents,targetCloseDate,tags,iscOpportunityLink,gtmNavAccountLink,oneDriveFolderLink,opportunityID\nDeal,Acme,Discovery,false,500000,,,,,,"
        let results = ImportService.parseProjectsCSV(csv)
        #expect(results.count == 1)
        if case .success(let p) = results[0] {
            #expect(p.estimatedValueCents == 500000)
        } else {
            Issue.record("Expected success")
        }
    }

    @Test("CSV parses semicolon-delimited tags correctly")
    func csvTagsParsing() {
        let csv = "name,accountName,stage,isPOC,estimatedValueCents,targetCloseDate,tags,iscOpportunityLink,gtmNavAccountLink,oneDriveFolderLink,opportunityID\nDeal,Acme,Discovery,false,,cloud;security;vpc,,,,,"
        let results = ImportService.parseProjectsCSV(csv)
        #expect(results.count == 1)
        if case .success(let p) = results[0] {
            #expect(p.tags == ["cloud", "security", "vpc"])
        } else {
            Issue.record("Expected success")
        }
    }

    @Test("CSV with unknown stage returns failure result")
    func csvUnknownStage() {
        let csv = "name,accountName,stage,isPOC,estimatedValueCents,targetCloseDate,tags,iscOpportunityLink,gtmNavAccountLink,oneDriveFolderLink,opportunityID\nBad Project,Acme,NotAStage,false,,,,,,"
        let results = ImportService.parseProjectsCSV(csv)
        #expect(results.count == 1)
        if case .failure(let name, _) = results[0] {
            #expect(name == "Bad Project")
        } else {
            Issue.record("Expected failure for unknown stage")
        }
    }
}
