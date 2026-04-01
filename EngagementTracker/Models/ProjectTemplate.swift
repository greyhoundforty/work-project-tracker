// EngagementTracker/Models/ProjectTemplate.swift
import Foundation

struct TemplateCustomField: Codable, Hashable {
    let label: String
    let placeholder: String?
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

    var projectStage: ProjectStage {
        ProjectStage(rawValue: stage) ?? .discovery
    }

    enum CodingKeys: String, CodingKey {
        case name, isPOC, tags, stage, taskTitles, customFields
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name         = try c.decode(String.self,          forKey: .name)
        isPOC        = try c.decode(Bool.self,            forKey: .isPOC)
        tags         = try c.decode([String].self,        forKey: .tags)
        stage        = try c.decode(String.self,          forKey: .stage)
        taskTitles   = try c.decode([String].self,        forKey: .taskTitles)
        customFields = try c.decodeIfPresent([TemplateCustomField].self, forKey: .customFields) ?? []
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
