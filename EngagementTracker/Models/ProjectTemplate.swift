import Foundation

struct ProjectTemplate: Codable, Identifiable, Hashable {
    var id: String { name }
    let name: String
    let isPOC: Bool
    let tags: [String]
    let stage: String
    let taskTitles: [String]

    var projectStage: ProjectStage {
        ProjectStage(rawValue: stage) ?? .discovery
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
