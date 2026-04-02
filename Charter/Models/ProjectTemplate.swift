// EngagementTracker/Models/ProjectTemplate.swift
import Foundation

struct TemplateCheckpoint: Codable, Hashable {
    let title: String
    let stage: String

    var projectStage: ProjectStage {
        ProjectStage(rawValue: stage) ?? .discovery
    }
}

struct TemplateCustomField: Codable, Hashable {
    let label: String
    let placeholder: String?
    let type: FieldType
    let options: [String]?
    /// Maps this field to a known `Project` property on save.
    /// Fields without a key are stored as `ProjectCustomField` entries.
    let key: String?

    enum FieldType: String, Codable {
        case text
        case url
        case toggle
        case stagePicker = "stage-picker"
        case date
    }

    enum CodingKeys: String, CodingKey {
        case label, placeholder, type, options, key
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        label       = try c.decode(String.self, forKey: .label)
        placeholder = try c.decodeIfPresent(String.self, forKey: .placeholder)
        type        = try c.decodeIfPresent(FieldType.self, forKey: .type) ?? .text
        options     = try c.decodeIfPresent([String].self, forKey: .options)
        key         = try c.decodeIfPresent(String.self, forKey: .key)
    }
}

struct ProjectTemplate: Codable, Identifiable, Hashable {
    var id: String { name }
    var isBuiltIn: Bool = false
    let name: String
    let isPOC: Bool
    let tags: [String]
    let stage: String
    let taskTitles: [String]
    let customFields: [TemplateCustomField]
    let checkpoints: [TemplateCheckpoint]

    var projectStage: ProjectStage {
        ProjectStage(rawValue: stage) ?? .discovery
    }

    enum CodingKeys: String, CodingKey {
        case name, isPOC, tags, stage, taskTitles, customFields, checkpoints
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name         = try c.decode(String.self,               forKey: .name)
        isPOC        = try c.decode(Bool.self,                 forKey: .isPOC)
        tags         = try c.decode([String].self,             forKey: .tags)
        stage        = try c.decode(String.self,               forKey: .stage)
        taskTitles   = try c.decode([String].self,             forKey: .taskTitles)
        customFields = try c.decodeIfPresent([TemplateCustomField].self,  forKey: .customFields)  ?? []
        checkpoints  = try c.decodeIfPresent([TemplateCheckpoint].self,   forKey: .checkpoints)   ?? []
    }

    static func loadBundled() -> [ProjectTemplate] {
        guard let urls = Bundle.main.urls(
            forResourcesWithExtension: "json",
            subdirectory: "BundledTemplates"
        ) else { return [] }
        return urls.compactMap { url -> ProjectTemplate? in
            guard let data = try? Data(contentsOf: url),
                  var template = try? JSONDecoder().decode(ProjectTemplate.self, from: data)
            else { return nil }
            template.isBuiltIn = true
            return template
        }.sorted { $0.name < $1.name }
    }

    static func load(from url: URL) -> [ProjectTemplate] {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url, includingPropertiesForKeys: nil
        ) else { return [] }
        return contents
            .filter { $0.pathExtension == "json" }
            .compactMap { fileURL in
                guard let data = try? Data(contentsOf: fileURL) else { return nil }
                return try? JSONDecoder().decode(ProjectTemplate.self, from: data)
            }
            .sorted { $0.name < $1.name }
    }
}
