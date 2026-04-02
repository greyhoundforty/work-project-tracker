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
