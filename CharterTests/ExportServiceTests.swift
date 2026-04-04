// EngagementTrackerTests/ExportServiceTests.swift
import Foundation
import Testing
@testable import Charter

@Suite("ExportService")
struct ExportServiceTests {

    private func makeProject() -> ExportedProject {
        ExportedProject(
            name: "PowerVS POC",
            accountName: "Contoso",
            opportunityID: "OPP-42",
            stage: "Refine",
            isPOC: true,
            estimatedValueCents: 120000,
            targetCloseDate: nil,
            tags: ["powervs", "poc"],
            iscOpportunityLink: "https://isc.example.com",
            gtmNavAccountLink: "",
            oneDriveFolderLink: "https://onedrive.example.com",
            contacts: [
                ExportedContact(name: "Alice Smith", title: "CTO",
                                email: "alice@contoso.com", type: "External"),
                ExportedContact(name: "Bob Jones", title: nil,
                                email: "bob@ibm.com", type: "Internal")
            ],
            tasks: [ExportedTask(title: "Send BOM", isCompleted: false,
                                 completedAt: nil, createdAt: Date())],
            notes: [],
            engagements: [],
            checkpoints: []
        )
    }

    @Test("JSON export produces valid decodable data")
    func jsonExport() throws {
        let data = try ExportService.encodeJSON([makeProject()])
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ExportBundle.self, from: data)
        #expect(decoded.projects[0].name == "PowerVS POC")
        #expect(decoded.projects[0].contacts.count == 2)
    }

    @Test("CSV projects row contains all expected columns")
    func csvProjectsRow() throws {
        let csv = ExportService.encodeCSV([makeProject()])
        #expect(csv["projects.csv"] != nil)
        let lines = csv["projects.csv"]!.components(separatedBy: "\n")
        #expect(lines[0].contains("name"))
        #expect(lines[0].contains("accountName"))
        #expect(lines[0].contains("stage"))
        #expect(lines[1].contains("PowerVS POC"))
        #expect(lines[1].contains("Contoso"))
    }

    @Test("CSV escapes commas and quotes inside field values")
    func csvEscaping() throws {
        var p = makeProject()
        p.name = "Project, \"Special\""
        let csv = ExportService.encodeCSV([p])
        let content = csv["projects.csv"]!
        // RFC 4180: fields containing commas or quotes are wrapped in double-quotes,
        // and embedded double-quotes are doubled.
        #expect(content.contains("\"Project, \"\"Special\"\"\""))
    }

    @Test("CSV contacts file has one row per contact")
    func csvContacts() throws {
        let csv = ExportService.encodeCSV([makeProject()])
        let contacts = csv["contacts.csv"]!
        let lines = contacts.components(separatedBy: "\n").filter { !$0.isEmpty }
        #expect(lines.count == 3) // header + 2 contacts
    }

    @Test("CSV tasks file contains task row with expected columns")
    func csvTasks() {
        let csv = ExportService.encodeCSV([makeProject()])
        let tasks = csv["tasks.csv"]!
        let lines = tasks.components(separatedBy: "\n").filter { !$0.isEmpty }
        #expect(lines.count == 2) // header + 1 task
        #expect(lines[0].contains("projectName"))
        #expect(lines[0].contains("title"))
        #expect(lines[0].contains("isCompleted"))
        #expect(lines[1].contains("Send BOM"))
    }

    @Test("CSV notes file is present with correct headers")
    func csvNotes() {
        let csv = ExportService.encodeCSV([makeProject()])
        let notes = csv["notes.csv"]
        #expect(notes != nil)
        #expect(notes!.contains("projectName"))
        #expect(notes!.contains("content"))
        #expect(notes!.contains("createdAt"))
    }

    @Test("CSV engagements file is present with correct headers")
    func csvEngagements() {
        let csv = ExportService.encodeCSV([makeProject()])
        let engs = csv["engagements.csv"]
        #expect(engs != nil)
        #expect(engs!.contains("projectName"))
        #expect(engs!.contains("summary"))
        #expect(engs!.contains("date"))
    }

    @Test("encodeCSV with empty project list returns all five files with only headers")
    func csvEmptyProjects() {
        let csv = ExportService.encodeCSV([])
        #expect(csv["projects.csv"] != nil)
        #expect(csv["contacts.csv"] != nil)
        #expect(csv["tasks.csv"] != nil)
        #expect(csv["notes.csv"] != nil)
        #expect(csv["engagements.csv"] != nil)
        let projLines = csv["projects.csv"]!.components(separatedBy: "\n").filter { !$0.isEmpty }
        #expect(projLines.count == 1) // header only
    }

    @Test("encodeJSON with empty project list produces valid bundle with no projects")
    func jsonEmptyExport() throws {
        let data = try ExportService.encodeJSON([])
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ExportBundle.self, from: data)
        #expect(decoded.projects.isEmpty)
        #expect(decoded.exportVersion == "1")
    }

    @Test("CSV escapes embedded newlines inside field values")
    func csvEscapingNewline() {
        var p = makeProject()
        p.name = "Project\nWith Newline"
        let csv = ExportService.encodeCSV([p])
        let content = csv["projects.csv"]!
        #expect(content.contains("\"Project\nWith Newline\""))
    }
}
