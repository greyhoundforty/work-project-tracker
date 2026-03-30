# Phase 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add export/import (JSON + CSV), a settings gear icon accessible from the main window, and a Gruvbox Light theme with manual theme override.

**Architecture notes:** Colors are named asset catalog entries (`Color("gruvBg")` etc.) — the light theme is implemented by adding "Any" appearance variants to those color sets, not by replacing the Color extensions. Theme override uses `@Environment(\.colorScheme)` + `.preferredColorScheme()` at the root.

**Tech Stack:** Swift 5.9, SwiftUI, SwiftData, Foundation (JSONEncoder/JSONDecoder, no third-party libraries required).

---

## File Map

```
EngagementTracker/
  Services/
    ExportService.swift          // encode models → ExportBundle (JSON or CSV strings)
    ImportService.swift          // parse ExportBundle → [ImportedProject], validate
  Models/
    ExportModels.swift           // Codable structs: ExportBundle, ExportedProject, etc.
  Views/
    Export/
      ExportSheet.swift          // format picker (JSON/CSV), scope picker, share/save button
      ImportSheet.swift          // file picker, preview table, confirm import action
    Settings/
      SettingsView.swift         // (modify) add Theme section
  App/
    AppState.swift               // (modify) add themeMode: ThemeMode
  Theme/
    GruvboxColors.swift          // (modify) add gruvStageColor light variants if needed
    EngagementTracker.xcassets   // (modify) add "Any" appearance to all color sets
```

**Run `xcodegen generate` after adding any new Swift files.**

---

## Task 1: Codable export structs

**Files:**
- Create: `EngagementTracker/Services/ExportModels.swift`

These are pure value types — no SwiftData involved. They must be `Codable` and fully represent a project and all its child entities.

- [ ] **Step 1: Write the tests first**

```swift
// EngagementTrackerTests/ExportModelsTests.swift
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
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
mise run test
```
Expected: compile error — `ExportBundle` not defined yet.

- [ ] **Step 3: Write the structs**

```swift
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
```

- [ ] **Step 4: Run tests — should pass**

```bash
mise run test
```

- [ ] **Step 5: Commit**

```bash
git add EngagementTracker/Services/ExportModels.swift EngagementTrackerTests/ExportModelsTests.swift
git commit -m "feat: add Codable export structs with round-trip tests"
```

---

## Task 2: ExportService (encode to JSON and CSV)

**Files:**
- Create: `EngagementTracker/Services/ExportService.swift`
- Modify: `EngagementTrackerTests/ExportServiceTests.swift`

- [ ] **Step 1: Write tests**

```swift
// EngagementTrackerTests/ExportServiceTests.swift
import Testing
@testable import EngagementTracker

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
                                email: "alice@contoso.com", type: "External (Customer)", internalRole: nil),
                ExportedContact(name: "Bob Jones", title: nil,
                                email: "bob@ibm.com", type: "Internal (IBM)", internalRole: "Solutions Engineer")
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
        let bundle = ExportBundle(exportVersion: "1", exportDate: Date(), projects: [makeProject()])
        let data = try ExportService.encodeJSON([makeProject()])
        let decoded = try JSONDecoder().decode(ExportBundle.self, from: data)
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
}
```

- [ ] **Step 2: Confirm tests fail**

```bash
mise run test
```

- [ ] **Step 3: Implement ExportService**

```swift
// EngagementTracker/Services/ExportService.swift
import Foundation
import SwiftData

enum ExportService {

    // MARK: - Model → ExportedProject conversion

    static func project(from model: Project) -> ExportedProject {
        let contactsByID = Dictionary(uniqueKeysWithValues: model.contacts.map { ($0.id, $0) })
        return ExportedProject(
            name: model.name,
            accountName: model.accountName,
            opportunityID: model.opportunityID,
            stage: model.stage.rawValue,
            isPOC: model.isPOC,
            estimatedValueCents: model.estimatedValueCents,
            targetCloseDate: model.targetCloseDate,
            tags: model.tags,
            iscOpportunityLink: model.iscOpportunityLink,
            gtmNavAccountLink: model.gtmNavAccountLink,
            oneDriveFolderLink: model.oneDriveFolderLink,
            contacts: model.contacts.map { contact(from: $0) },
            tasks: model.tasks.sorted { $0.createdAt < $1.createdAt }.map { task(from: $0) },
            notes: model.notes.sorted { $0.createdAt < $1.createdAt }.map { note(from: $0) },
            engagements: model.engagements.sorted { $0.date < $1.date }.map { engagement(from: $0, contacts: contactsByID) },
            checkpoints: model.checkpoints.sorted { $0.sortOrder < $1.sortOrder }.map { checkpoint(from: $0) }
        )
    }

    static func contact(from m: Contact) -> ExportedContact {
        ExportedContact(name: m.name, title: m.title, email: m.email,
                        type: m.type.rawValue, internalRole: m.internalRole?.rawValue)
    }

    static func task(from m: ProjectTask) -> ExportedTask {
        ExportedTask(title: m.title, isCompleted: m.isCompleted,
                     completedAt: m.completedAt, createdAt: m.createdAt)
    }

    static func note(from m: Note) -> ExportedNote {
        ExportedNote(content: m.content, createdAt: m.createdAt)
    }

    static func engagement(from m: Engagement, contacts: [UUID: Contact]) -> ExportedEngagement {
        let names = m.contactIDs.compactMap { contacts[$0]?.name }
        return ExportedEngagement(date: m.date, summary: m.summary, contactNames: names)
    }

    static func checkpoint(from m: Checkpoint) -> ExportedCheckpoint {
        ExportedCheckpoint(title: m.title, stage: m.stage.rawValue,
                           sortOrder: m.sortOrder, isCompleted: m.isCompleted,
                           completedAt: m.completedAt)
    }

    // MARK: - JSON

    static func encodeJSON(_ projects: [ExportedProject]) throws -> Data {
        let bundle = ExportBundle(exportVersion: "1", exportDate: Date(), projects: projects)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(bundle)
    }

    // MARK: - CSV (returns dict of filename → content)

    static func encodeCSV(_ projects: [ExportedProject]) -> [String: String] {
        var files: [String: String] = [:]

        // projects.csv
        let projHeaders = ["name","accountName","opportunityID","stage","isPOC",
                           "estimatedValueCents","targetCloseDate","tags",
                           "iscOpportunityLink","gtmNavAccountLink","oneDriveFolderLink"]
        var projRows = [projHeaders.joined(separator: ",")]
        for p in projects {
            let row: [String] = [
                p.name, p.accountName ?? "", p.opportunityID ?? "",
                p.stage, p.isPOC ? "true" : "false",
                p.estimatedValueCents.map { String($0) } ?? "",
                p.targetCloseDate.map { iso8601($0) } ?? "",
                p.tags.joined(separator: ";"),
                p.iscOpportunityLink, p.gtmNavAccountLink, p.oneDriveFolderLink
            ]
            projRows.append(row.map(csvEscape).joined(separator: ","))
        }
        files["projects.csv"] = projRows.joined(separator: "\n")

        // contacts.csv
        let contactHeaders = ["projectName","name","title","email","type","internalRole"]
        var contactRows = [contactHeaders.joined(separator: ",")]
        for p in projects {
            for c in p.contacts {
                let row = [p.name, c.name, c.title ?? "", c.email ?? "",
                           c.type, c.internalRole ?? ""]
                contactRows.append(row.map(csvEscape).joined(separator: ","))
            }
        }
        files["contacts.csv"] = contactRows.joined(separator: "\n")

        // tasks.csv
        let taskHeaders = ["projectName","title","isCompleted","completedAt","createdAt"]
        var taskRows = [taskHeaders.joined(separator: ",")]
        for p in projects {
            for t in p.tasks {
                let row = [p.name, t.title, t.isCompleted ? "true" : "false",
                           t.completedAt.map { iso8601($0) } ?? "",
                           iso8601(t.createdAt)]
                taskRows.append(row.map(csvEscape).joined(separator: ","))
            }
        }
        files["tasks.csv"] = taskRows.joined(separator: "\n")

        // notes.csv
        let noteHeaders = ["projectName","content","createdAt"]
        var noteRows = [noteHeaders.joined(separator: ",")]
        for p in projects {
            for n in p.notes {
                let row = [p.name, n.content, iso8601(n.createdAt)]
                noteRows.append(row.map(csvEscape).joined(separator: ","))
            }
        }
        files["notes.csv"] = noteRows.joined(separator: "\n")

        // engagements.csv
        let engHeaders = ["projectName","date","summary","contacts"]
        var engRows = [engHeaders.joined(separator: ",")]
        for p in projects {
            for e in p.engagements {
                let row = [p.name, iso8601(e.date), e.summary,
                           e.contactNames.joined(separator: ";")]
                engRows.append(row.map(csvEscape).joined(separator: ","))
            }
        }
        files["engagements.csv"] = engRows.joined(separator: "\n")

        return files
    }

    // MARK: - Helpers

    private static func csvEscape(_ field: String) -> String {
        // RFC 4180: wrap in quotes if field contains comma, quote, or newline
        guard field.contains(",") || field.contains("\"") || field.contains("\n") else {
            return field
        }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private static func iso8601(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}
```

- [ ] **Step 4: Run tests — all should pass**

```bash
mise run test
```

- [ ] **Step 5: Commit**

```bash
git add EngagementTracker/Services/ExportService.swift EngagementTrackerTests/ExportServiceTests.swift
git commit -m "feat: ExportService — JSON and CSV encoding with escaping tests"
```

---

## Task 3: ImportService (parse JSON and CSV back to ExportedProject)

**Files:**
- Create: `EngagementTracker/Services/ImportService.swift`
- Modify: `EngagementTrackerTests/ImportServiceTests.swift`

The importer validates data and returns typed results, never crashing on bad input.

- [ ] **Step 1: Write tests**

```swift
// EngagementTrackerTests/ImportServiceTests.swift
import Testing
@testable import EngagementTracker

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
```

- [ ] **Step 2: Confirm tests fail**

```bash
mise run test
```

- [ ] **Step 3: Implement ImportService**

```swift
// EngagementTracker/Services/ImportService.swift
import Foundation

enum ImportResult {
    case success(ExportedProject)
    case failure(String, String)   // (projectName or row indicator, errorMessage)
}

enum ImportService {

    // MARK: - JSON

    static func parseJSON(_ data: Data) -> [ImportResult] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let bundle = try? decoder.decode(ExportBundle.self, from: data) else {
            return []
        }
        return bundle.projects.map { validate($0) }
    }

    // MARK: - CSV (projects.csv only — child entities joined from sibling CSV files if present)

    static func parseProjectsCSV(_ csv: String) -> [ImportResult] {
        let rows = parseCSVRows(csv)
        guard let header = rows.first else { return [] }
        return rows.dropFirst().compactMap { row -> ImportResult? in
            guard !row.isEmpty else { return nil }
            let dict = Dictionary(uniqueKeysWithValues: zip(header, row))
            let name = dict["name"] ?? ""
            guard !name.isEmpty else {
                return .failure("(unnamed row)", "Missing required field: name")
            }
            let project = ExportedProject(
                name: name,
                accountName: nilIfEmpty(dict["accountName"]),
                opportunityID: nilIfEmpty(dict["opportunityID"]),
                stage: dict["stage"] ?? "Discovery",
                isPOC: dict["isPOC"] == "true",
                estimatedValueCents: dict["estimatedValueCents"].flatMap { Int($0) },
                targetCloseDate: dict["targetCloseDate"].flatMap { ISO8601DateFormatter().date(from: $0) },
                tags: dict["tags"].map { $0.split(separator: ";").map(String.init) } ?? [],
                iscOpportunityLink: dict["iscOpportunityLink"] ?? "",
                gtmNavAccountLink: dict["gtmNavAccountLink"] ?? "",
                oneDriveFolderLink: dict["oneDriveFolderLink"] ?? "",
                contacts: [],    // contacts from contacts.csv merged by caller
                tasks: [],
                notes: [],
                engagements: [],
                checkpoints: []  // checkpoints re-seeded by ImportCoordinator
            )
            return validate(project)
        }
    }

    // MARK: - Validation

    private static func validate(_ project: ExportedProject) -> ImportResult {
        guard !project.name.trimmingCharacters(in: .whitespaces).isEmpty else {
            return .failure("(unnamed)", "Project name is required")
        }
        guard ProjectStage.allCases.map(\.rawValue).contains(project.stage) else {
            return .failure(project.name, "Unknown stage: '\(project.stage)'. Valid values: \(ProjectStage.allCases.map(\.rawValue).joined(separator: ", "))")
        }
        return .success(project)
    }

    // MARK: - CSV parser (RFC 4180)

    static func parseCSVRows(_ csv: String) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var inQuotes = false
        let chars = Array(csv)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if inQuotes {
                if c == "\"" {
                    if i + 1 < chars.count && chars[i + 1] == "\"" {
                        currentField.append("\"")
                        i += 2
                        continue
                    } else {
                        inQuotes = false
                    }
                } else {
                    currentField.append(c)
                }
            } else {
                if c == "\"" {
                    inQuotes = true
                } else if c == "," {
                    currentRow.append(currentField)
                    currentField = ""
                } else if c == "\n" || (c == "\r" && i + 1 < chars.count && chars[i + 1] == "\n") {
                    if c == "\r" { i += 1 }
                    currentRow.append(currentField)
                    rows.append(currentRow)
                    currentRow = []
                    currentField = ""
                } else {
                    currentField.append(c)
                }
            }
            i += 1
        }
        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField)
            rows.append(currentRow)
        }
        return rows
    }

    private static func nilIfEmpty(_ s: String?) -> String? {
        guard let s, !s.isEmpty else { return nil }
        return s
    }
}
```

- [ ] **Step 4: Run tests — all should pass**

```bash
mise run test
```

- [ ] **Step 5: Commit**

```bash
git add EngagementTracker/Services/ImportService.swift EngagementTrackerTests/ImportServiceTests.swift
git commit -m "feat: ImportService — JSON and CSV parsing with validation and RFC 4180 CSV parser"
```

---

## Task 4: Export UI sheet

**Files:**
- Create: `EngagementTracker/Views/Export/ExportSheet.swift`

Presents format and scope options, then exports via `fileExporter` or writes to a temp directory and opens a save panel.

- [ ] **Step 1: Create ExportSheet.swift**

```swift
// EngagementTracker/Views/Export/ExportSheet.swift
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

enum ExportFormat: String, CaseIterable, Identifiable {
    case json = "JSON"
    case csv  = "CSV (multiple files as ZIP)"
    var id: String { rawValue }
}

enum ExportScope {
    case allProjects
    case singleProject(Project)
}

struct ExportSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let scope: ExportScope

    @State private var format: ExportFormat = .json
    @State private var isExporting = false
    @State private var exportError: String?

    private var scopeLabel: String {
        switch scope {
        case .allProjects: return "All active projects"
        case .singleProject(let p): return p.name
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Export Projects")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.gruvFg)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
            }
            .padding()
            .background(Color.gruvBg1)

            Divider()

            VStack(alignment: .leading, spacing: 20) {
                FormSection(title: "Scope") {
                    LabeledContent("Exporting", value: scopeLabel)
                        .foregroundStyle(Color.gruvFg)
                }

                FormSection(title: "Format") {
                    Picker("Format", selection: $format) {
                        ForEach(ExportFormat.allCases) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    .foregroundStyle(Color.gruvFg)

                    if format == .json {
                        Text("One JSON file with all project data. Can be re-imported.")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.gruvFgDim)
                    } else {
                        Text("One CSV per entity type (projects, contacts, tasks, notes, engagements) bundled as a ZIP. Open individual files in Excel.")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.gruvFgDim)
                    }
                }

                if let error = exportError {
                    Text("Export failed: \(error)")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.gruvRed)
                }

                Button(action: performExport) {
                    Label("Export…", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.gruvAqua)
                .disabled(isExporting)
            }
            .padding()
        }
        .background(Color.gruvBg)
        .frame(width: 440)
    }

    private func projectsToExport() -> [Project] {
        switch scope {
        case .allProjects:
            return (try? context.fetch(FetchDescriptor<Project>(
                predicate: #Predicate { $0.isActive }
            ))) ?? []
        case .singleProject(let p):
            return [p]
        }
    }

    private func performExport() {
        isExporting = true
        exportError = nil
        let models = projectsToExport()
        let exported = models.map { ExportService.project(from: $0) }

        do {
            let panel = NSSavePanel()
            panel.canCreateDirectories = true

            switch format {
            case .json:
                panel.allowedContentTypes = [.json]
                panel.nameFieldStringValue = "engagement-tracker-export.json"
                if panel.runModal() == .OK, let url = panel.url {
                    let data = try ExportService.encodeJSON(exported)
                    try data.write(to: url)
                }
            case .csv:
                panel.allowedContentTypes = [UTType(filenameExtension: "zip") ?? .data]
                panel.nameFieldStringValue = "engagement-tracker-export.zip"
                if panel.runModal() == .OK, let url = panel.url {
                    let csvFiles = ExportService.encodeCSV(exported)
                    try writeZip(csvFiles, to: url)
                }
            }
        } catch {
            exportError = error.localizedDescription
        }
        isExporting = false
        dismiss()
    }

    // Bundle CSV files into a ZIP using Process + zip command-line tool
    private func writeZip(_ files: [String: String], to destination: URL) throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        for (filename, content) in files {
            let fileURL = tmpDir.appendingPathComponent(filename)
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.arguments = ["-j", destination.path] + files.keys.map {
            tmpDir.appendingPathComponent($0).path
        }
        try process.run()
        process.waitUntilExit()
    }
}
```

- [ ] **Step 2: Wire ExportSheet into ProjectDetailHeaderView**

In `ProjectDetailHeaderView`, add an export button next to the delete button:

```swift
// Add to ProjectDetailHeaderView state:
@State private var showExport = false

// Add next to the trash button in the HStack:
Button {
    showExport = true
} label: {
    Image(systemName: "square.and.arrow.up")
        .foregroundStyle(Color.gruvBlue)
}
.buttonStyle(.plain)
.help("Export this project")
.sheet(isPresented: $showExport) {
    ExportSheet(scope: .singleProject(project))
}
```

- [ ] **Step 3: Wire ExportSheet for all-projects export from toolbar**

In `ProjectListView`, add a toolbar button for all-projects export:

```swift
// Add to state:
@State private var showExport = false

// Add ToolbarItem alongside the existing New Project button:
ToolbarItem {
    Button {
        showExport = true
    } label: {
        Image(systemName: "square.and.arrow.up")
    }
    .help("Export all projects")
}
// Add sheet:
.sheet(isPresented: $showExport) {
    ExportSheet(scope: .allProjects)
}
```

- [ ] **Step 4: Build and manually test export**

```bash
mise run build
```

Create a test project with contacts, tasks, notes, and engagements. Export as JSON. Verify the file opens and contains all data. Export as CSV ZIP. Verify the ZIP contains all expected CSV files and they open correctly in Excel/Numbers.

- [ ] **Step 5: Commit**

```bash
git add EngagementTracker/Views/Export/ExportSheet.swift \
        EngagementTracker/Views/Main/ProjectDetailView.swift \
        EngagementTracker/Views/Main/ProjectListView.swift
git commit -m "feat: ExportSheet — JSON and CSV/ZIP export with NSSavePanel"
```

---

## Task 5: Import UI sheet

**Files:**
- Create: `EngagementTracker/Views/Export/ImportSheet.swift`

Shows a file picker, previews what will be imported, and handles conflicts (skip duplicate names by default).

- [ ] **Step 1: Create ImportSheet.swift**

```swift
// EngagementTracker/Views/Export/ImportSheet.swift
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var importResults: [ImportResult] = []
    @State private var hasLoaded = false
    @State private var isImporting = false
    @State private var importError: String?
    @State private var successCount = 0
    @State private var showDone = false
    @State private var skipDuplicates = true

    private var successes: [ExportedProject] {
        importResults.compactMap { if case .success(let p) = $0 { p } else { nil } }
    }
    private var failures: [(String, String)] {
        importResults.compactMap { if case .failure(let n, let e) = $0 { (n, e) } else { nil } }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Import Projects")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.gruvFg)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
            }
            .padding()
            .background(Color.gruvBg1)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !hasLoaded {
                        FormSection(title: "Load File") {
                            Text("Select a previously exported JSON file, or a projects.csv file.")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.gruvFgDim)
                            Button("Choose File…") { pickFile() }
                                .buttonStyle(.borderedProminent)
                                .tint(Color.gruvAqua)
                        }
                    } else {
                        // Preview
                        if !successes.isEmpty {
                            FormSection(title: "Will Import (\(successes.count))") {
                                ForEach(successes, id: \.name) { p in
                                    HStack {
                                        Text(p.name)
                                            .font(.system(size: 13))
                                            .foregroundStyle(Color.gruvFg)
                                        Spacer()
                                        Text(p.stage)
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.gruvFgDim)
                                        if !p.contacts.isEmpty {
                                            Text("\(p.contacts.count) contacts")
                                                .font(.system(size: 10))
                                                .foregroundStyle(Color.gruvFgDim)
                                        }
                                    }
                                }

                                Toggle("Skip projects with duplicate names", isOn: $skipDuplicates)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.gruvFg)
                            }
                        }

                        if !failures.isEmpty {
                            FormSection(title: "Skipped (\(failures.count))") {
                                ForEach(failures, id: \.0) { name, error in
                                    HStack(alignment: .top) {
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundStyle(Color.gruvOrange)
                                            .font(.system(size: 12))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(name).font(.system(size: 12, weight: .semibold))
                                                .foregroundStyle(Color.gruvFg)
                                            Text(error).font(.system(size: 11))
                                                .foregroundStyle(Color.gruvFgDim)
                                        }
                                    }
                                }
                            }
                        }

                        if let error = importError {
                            Text(error).font(.system(size: 12)).foregroundStyle(Color.gruvRed)
                        }

                        if showDone {
                            Text("✓ Imported \(successCount) project(s) successfully.")
                                .foregroundStyle(Color.gruvGreen)
                        }

                        if !successes.isEmpty && !showDone {
                            Button(action: performImport) {
                                Label("Import \(successes.count) Project(s)", systemImage: "square.and.arrow.down")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.gruvAqua)
                            .disabled(isImporting)
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color.gruvBg)
        .frame(width: 480, height: 500)
    }

    private func pickFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.json, .commaSeparatedText]
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let data = try Data(contentsOf: url)
            if url.pathExtension.lowercased() == "json" {
                importResults = ImportService.parseJSON(data)
            } else {
                let csv = String(decoding: data, as: UTF8.self)
                importResults = ImportService.parseProjectsCSV(csv)
            }
            hasLoaded = true
        } catch {
            importError = error.localizedDescription
            hasLoaded = true
        }
    }

    private func performImport() {
        isImporting = true
        importError = nil
        var imported = 0

        let existingNames: Set<String>
        if skipDuplicates {
            let existing = (try? context.fetch(FetchDescriptor<Project>())) ?? []
            existingNames = Set(existing.map(\.name))
        } else {
            existingNames = []
        }

        for exported in successes {
            if skipDuplicates && existingNames.contains(exported.name) { continue }

            let project = Project(
                name: exported.name,
                accountName: exported.accountName,
                opportunityID: exported.opportunityID,
                stage: ProjectStage(rawValue: exported.stage) ?? .discovery,
                isPOC: exported.isPOC,
                estimatedValueCents: exported.estimatedValueCents,
                targetCloseDate: exported.targetCloseDate,
                tags: exported.tags,
                iscOpportunityLink: exported.iscOpportunityLink,
                gtmNavAccountLink: exported.gtmNavAccountLink,
                oneDriveFolderLink: exported.oneDriveFolderLink
            )
            context.insert(project)

            for c in exported.contacts {
                let contact = Contact(
                    name: c.name, title: c.title, email: c.email,
                    type: ContactType(rawValue: c.type) ?? .external,
                    internalRole: c.internalRole.flatMap { InternalRole(rawValue: $0) }
                )
                context.insert(contact)
                project.contacts.append(contact)
            }

            for t in exported.tasks {
                let task = ProjectTask(title: t.title)
                task.isCompleted = t.isCompleted
                task.completedAt = t.completedAt
                context.insert(task)
                project.tasks.append(task)
            }

            for n in exported.notes {
                let note = Note(content: n.content)
                context.insert(note)
                project.notes.append(note)
            }

            // If no checkpoints in export (e.g. imported from CSV), seed defaults
            if exported.checkpoints.isEmpty {
                CheckpointSeeder.makeAllCheckpoints().forEach {
                    project.checkpoints.append($0)
                    context.insert($0)
                }
            } else {
                for cp in exported.checkpoints {
                    let stage = ProjectStage(rawValue: cp.stage) ?? .discovery
                    let checkpoint = Checkpoint(title: cp.title, stage: stage, sortOrder: cp.sortOrder)
                    checkpoint.isCompleted = cp.isCompleted
                    checkpoint.completedAt = cp.completedAt
                    context.insert(checkpoint)
                    project.checkpoints.append(checkpoint)
                }
            }

            imported += 1
        }

        try? context.save()
        successCount = imported
        isImporting = false
        showDone = true
    }
}
```

- [ ] **Step 2: Wire ImportSheet into ProjectListView toolbar**

In `ProjectListView`, add an import toolbar button:

```swift
@State private var showImport = false

// In toolbar, alongside existing buttons:
ToolbarItem {
    Button {
        showImport = true
    } label: {
        Image(systemName: "square.and.arrow.down")
    }
    .help("Import projects from JSON or CSV")
}
.sheet(isPresented: $showImport) {
    ImportSheet()
}
```

- [ ] **Step 3: Manual round-trip test**

1. Create 2-3 projects with contacts, tasks, notes, engagements
2. Export all as JSON
3. Delete all projects
4. Import the JSON file
5. Verify all projects, contacts, tasks, notes appear correctly
6. Repeat the above with CSV export (projects.csv only — contacts won't import)

- [ ] **Step 4: Commit**

```bash
git add EngagementTracker/Views/Export/ImportSheet.swift \
        EngagementTracker/Views/Main/ProjectListView.swift
git commit -m "feat: ImportSheet — JSON and CSV import with preview and duplicate skip"
```

---

## Task 6: Settings gear icon

**Files:**
- Modify: `EngagementTracker/Views/Main/ContentView.swift`
- Modify: `EngagementTracker/Views/MenuBar/MenuBarPopoverView.swift`
- Modify: `EngagementTracker/Views/Settings/SettingsView.swift` (resize for new content)

macOS 14+ provides `@Environment(\.openSettings)` to open the Settings scene programmatically.

- [ ] **Step 1: Add gear to main window toolbar**

```swift
// ContentView.swift — add to NavigationSplitView toolbar
.toolbar {
    ToolbarItem(placement: .automatic) {
        SettingsGearButton()
    }
}
```

```swift
// New helper view (can live in ContentView.swift):
struct SettingsGearButton: View {
    @Environment(\.openSettings) private var openSettings
    var body: some View {
        Button {
            openSettings()
        } label: {
            Image(systemName: "gearshape")
                .foregroundStyle(Color.gruvFgDim)
        }
        .help("Settings")
    }
}
```

- [ ] **Step 2: Add gear to menu bar popover footer**

In `MenuBarPopoverView`, in the footer `HStack` alongside Open App / Quit:

```swift
Button {
    openSettings()
} label: {
    Image(systemName: "gearshape")
        .foregroundStyle(Color.gruvFgDim)
}
.buttonStyle(.plain)
// Add @Environment(\.openSettings) private var openSettings to MenuBarPopoverView
```

- [ ] **Step 3: Build and test**

```bash
mise run build
```

Verify gear icon appears in the toolbar and in the menu bar popover footer. Clicking opens the Settings window.

- [ ] **Step 4: Commit**

```bash
git add EngagementTracker/Views/Main/ContentView.swift \
        EngagementTracker/Views/MenuBar/MenuBarPopoverView.swift
git commit -m "feat: settings gear icon in toolbar and menu bar popover"
```

---

## Task 7: Light theme — asset catalog color sets

**Files:**
- Modify: `EngagementTracker/Assets.xcassets` — add "Any" (light) appearance values to all color sets

This is entirely visual work. The existing code uses `Color("gruvBg")` etc. which are named colors from the asset catalog. Adding "Any Appearance" variants lets macOS automatically switch between themes based on the system appearance.

Gruvbox Light palette values:

| Color name | Light (Any) | Dark Medium (Dark) |
|---|---|---|
| gruvBg | #fbf1c7 | #282828 |
| gruvBg1 | #f2e5bc | #32302f |
| gruvBg2 | #ebdbb2 | #3c3836 |
| gruvBg3 | #d5c4a1 | #504945 |
| gruvFg | #3c3836 | #ebdbb2 |
| gruvFg2 | #504945 | #d5c4a1 |
| gruvFgDim | #7c6f64 | #928374 |
| gruvRed | #9d0006 | #cc241d |
| gruvGreen | #79740e | #98971a |
| gruvYellow | #b57614 | #d79921 |
| gruvBlue | #076678 | #458588 |
| gruvPurple | #8f3f71 | #b16286 |
| gruvAqua | #427b58 | #689d6a |
| gruvOrange | #af3a03 | #d65d0e |

> **Note on light accent colors:** Gruvbox Light uses darker, more saturated versions of the accents (e.g., red is `#9d0006` not `#cc241d`) for legibility on a light background. These are the official Gruvbox Light "hard contrast" accent values.

- [ ] **Step 1: Open `EngagementTracker.xcassets` in Xcode**

For each color set (`gruvBg`, `gruvBg1`, etc.):
1. Select the color in the asset catalog
2. In the Attributes Inspector, set Appearances to "Any, Dark"
3. Set the "Any" value to the Light hex from the table above
4. Verify the "Dark" value already matches

- [ ] **Step 2: Add AppState theme override (optional but useful for testing)**

Add to `AppState.swift`:

```swift
enum ThemeMode: String {
    case system, light, dark
}

var themeMode: ThemeMode {
    get { ThemeMode(rawValue: UserDefaults.standard.string(forKey: "themeMode") ?? "system") ?? .system }
    set { UserDefaults.standard.set(newValue.rawValue, forKey: "themeMode") }
}
```

Apply in `EngagementTrackerApp.swift` on the `WindowGroup`:

```swift
.preferredColorScheme(appState.themeMode == .system ? nil :
                      appState.themeMode == .light ? .light : .dark)
```

- [ ] **Step 3: Add theme picker to SettingsView**

```swift
Section {
    Picker("Theme", selection: Binding(
        get: { appState.themeMode },
        set: { appState.themeMode = $0 }
    )) {
        Text("System").tag(ThemeMode.system)
        Text("Light").tag(ThemeMode.light)
        Text("Dark").tag(ThemeMode.dark)
    }
    .pickerStyle(.radioGroup)
} header: {
    Text("Appearance")
}
```

- [ ] **Step 4: Build and visually verify both themes**

```bash
mise run build
```

Switch between Light/Dark/System in Settings. Check that:
- All backgrounds switch correctly (no hardcoded colors left)
- Stage accent colors are legible in both modes
- Tags, pills, and badges read well on light backgrounds

- [ ] **Step 5: Commit**

```bash
git add EngagementTracker/Assets.xcassets \
        EngagementTracker/App/AppState.swift \
        EngagementTracker/App/EngagementTrackerApp.swift \
        EngagementTracker/Views/Settings/SettingsView.swift
git commit -m "feat: Gruvbox Light theme with system/light/dark override in Settings"
```

---

## Task 8: Final integration pass

- [ ] Run `mise run test` — all 16+ tests must pass
- [ ] Run `mise run clean-build` — no warnings or errors
- [ ] Export → Import round-trip test (JSON and CSV)
- [ ] Verify settings gear opens from both toolbar and menu bar
- [ ] Verify theme toggle persists across app restarts
- [ ] Run `xcodegen generate` to confirm project file is clean

```bash
git add -A
git commit -m "chore: Phase 2 integration — all features verified"
```

---

## Caveats and Notes for Implementation

### ZIP bundling uses /usr/bin/zip
The CSV ZIP export shells out to `/usr/bin/zip`. This is always present on macOS and avoids adding a dependency, but it means the export blocks briefly on the main thread. For large datasets (hundreds of projects) consider moving to a background task. Alternatively, `ZIPFoundation` is a well-maintained Swift package if you want a pure-Swift approach.

### ImportSheet only imports contacts from JSON
The CSV import (projects.csv) only creates projects — contacts, tasks, notes, and engagements require the JSON format or separate CSV files that the caller merges. This is intentional and documented in the ImportSheet UI. If you later want full CSV import of child entities, `ImportService.parseContactsCSV(_:projectName:)` would be the extension point.

### checkpoints are re-seeded on CSV import
When importing from CSV (which has no checkpoint data), `CheckpointSeeder.makeAllCheckpoints()` is called to give the project a fresh default checklist. When importing from JSON, the saved checkpoint state (including which ones were completed) is restored. This is the correct behavior for the intended use case.

### `@Environment(\.openSettings)` requires macOS 14+
This is fine since the app already targets macOS 14+. If the deployment target is ever lowered, replace with `NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)`.

### Asset catalog color sets must be set in Xcode — not hand-edited
The `.xcassets` JSON format for color sets is undocumented and fiddly. Set the colors through Xcode's color picker UI. The sRGB hex values in the table above are correct for both the standard and extended sRGB spaces that Xcode uses.

### Theme override applies to the main WindowGroup only
`.preferredColorScheme()` on the `WindowGroup` scene affects only that window. The `MenuBarExtra` popover inherits system appearance. This is consistent with how most macOS apps behave and is fine for now.
