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
            iscOpportunityLink: model.iscOpportunityLink ?? "",
            gtmNavAccountLink: model.gtmNavAccountLink ?? "",
            oneDriveFolderLink: model.oneDriveFolderLink ?? "",
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
        ExportedNote(title: m.title, content: m.content, createdAt: m.createdAt)
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
                p.iscOpportunityLink ?? "", p.gtmNavAccountLink ?? "", p.oneDriveFolderLink ?? ""
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
        let noteHeaders = ["projectName","title","content","createdAt"]
        var noteRows = [noteHeaders.joined(separator: ",")]
        for p in projects {
            for n in p.notes {
                let row = [p.name, n.title ?? "", n.content, iso8601(n.createdAt)]
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
        guard field.contains(",") || field.contains("\"") || field.contains("\n") else {
            return field
        }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private static func iso8601(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}
