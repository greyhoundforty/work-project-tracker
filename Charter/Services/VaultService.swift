import Foundation
import SwiftData

/// Reads and writes per-project `notes/*.md` and `tasks/*.txt` under a user-chosen vault root.
enum VaultService {
    enum VaultError: Swift.Error {
        case vaultNotConfigured
        case securityScopeDenied
        case invalidProjectVaultPath
    }

    private static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let iso8601NoFrac: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func isVaultConfigured(_ appState: AppState) -> Bool {
        appState.resolveVaultRootURL() != nil
    }

    static func withVaultRoot<T>(_ appState: AppState, _ body: (URL) throws -> T) throws -> T {
        guard let root = appState.resolveVaultRootURL() else { throw VaultError.vaultNotConfigured }
        let started = root.startAccessingSecurityScopedResource()
        guard started else { throw VaultError.securityScopeDenied }
        defer { root.stopAccessingSecurityScopedResource() }
        return try body(root)
    }

    /// Assigns `project.vaultFolderName` if missing: `slug(name)-<first 8 of id>`.
    static func assignVaultFolderNameIfNeeded(for project: Project) {
        guard project.vaultFolderName == nil else { return }
        let slug = slugify(project.name)
        let suffix = String(project.id.uuidString.prefix(8))
        project.vaultFolderName = "\(slug)-\(suffix)"
    }

    static func ensureProjectDirectories(vaultRoot: URL, project: Project) throws -> URL {
        assignVaultFolderNameIfNeeded(for: project)
        guard let folderName = project.vaultFolderName else { throw VaultError.invalidProjectVaultPath }
        let projectURL = vaultRoot.appendingPathComponent(folderName, isDirectory: true)
        let fm = FileManager.default
        try fm.createDirectory(at: projectURL, withIntermediateDirectories: true)
        try fm.createDirectory(at: projectURL.appendingPathComponent("notes", isDirectory: true), withIntermediateDirectories: true)
        try fm.createDirectory(at: projectURL.appendingPathComponent("tasks", isDirectory: true), withIntermediateDirectories: true)
        return projectURL
    }

    // MARK: - Notes

    static func noteFileURL(projectDir: URL, noteId: UUID) -> URL {
        projectDir.appendingPathComponent("notes", isDirectory: true)
            .appendingPathComponent("\(noteId.uuidString.lowercased()).md", isDirectory: false)
    }

    static func writeNote(_ note: Note, project: Project, appState: AppState) throws {
        try withVaultRoot(appState) { root in
            let projectDir = try ensureProjectDirectories(vaultRoot: root, project: project)
            let url = noteFileURL(projectDir: projectDir, noteId: note.id)
            let markdown = serializeNote(note)
            try markdown.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    static func deleteNoteFile(_ note: Note, project: Project, appState: AppState) throws {
        try withVaultRoot(appState) { root in
            guard let folderName = project.vaultFolderName else { return }
            let projectDir = root.appendingPathComponent(folderName, isDirectory: true)
            let url = noteFileURL(projectDir: projectDir, noteId: note.id)
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
        }
    }

    /// Imports `.md` from disk (disk wins), then removes SwiftData rows with no backing file.
    static func syncNotes(project: Project, context: ModelContext, appState: AppState) throws {
        guard isVaultConfigured(appState) else { return }
        try withVaultRoot(appState) { root in
            let projectDir = try ensureProjectDirectories(vaultRoot: root, project: project)
            let notesDir = projectDir.appendingPathComponent("notes", isDirectory: true)
            let files = try listMarkdownFiles(under: notesDir)
            var diskIds = Set<UUID>()
            for url in files {
                guard let id = UUID(uuidString: url.deletingPathExtension().lastPathComponent.lowercased()) else { continue }
                diskIds.insert(id)
                let data = try Data(contentsOf: url)
                guard let text = String(data: data, encoding: .utf8) else { continue }
                let parsed = parseNoteFile(text)
                if let existing = project.notes.first(where: { $0.id == id }) {
                    existing.title = parsed.title
                    existing.content = parsed.body
                    existing.createdAt = parsed.createdAt
                } else {
                    let note = Note(id: id, title: parsed.title, content: parsed.body, createdAt: parsed.createdAt)
                    note.project = project
                    context.insert(note)
                    project.notes.append(note)
                }
            }

            if diskIds.isEmpty, !project.notes.isEmpty {
                let projectDir = try ensureProjectDirectories(vaultRoot: root, project: project)
                for note in project.notes {
                    let url = noteFileURL(projectDir: projectDir, noteId: note.id)
                    try serializeNote(note).write(to: url, atomically: true, encoding: .utf8)
                }
                project.updatedAt = Date()
                try context.save()
                return
            }

            let orphans = project.notes.filter { !diskIds.contains($0.id) }
            for note in orphans {
                project.notes.removeAll { $0.id == note.id }
                context.delete(note)
            }
            project.updatedAt = Date()
        }
        try context.save()
    }

    // MARK: - Tasks

    static func taskFileURL(projectDir: URL, taskId: UUID) -> URL {
        projectDir.appendingPathComponent("tasks", isDirectory: true)
            .appendingPathComponent("\(taskId.uuidString.lowercased()).txt", isDirectory: false)
    }

    static func writeTask(_ task: ProjectTask, project: Project, appState: AppState) throws {
        try withVaultRoot(appState) { root in
            let projectDir = try ensureProjectDirectories(vaultRoot: root, project: project)
            let url = taskFileURL(projectDir: projectDir, taskId: task.id)
            let text = serializeTask(task)
            try text.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    static func deleteTaskFile(_ task: ProjectTask, project: Project, appState: AppState) throws {
        try withVaultRoot(appState) { root in
            guard let folderName = project.vaultFolderName else { return }
            let projectDir = root.appendingPathComponent(folderName, isDirectory: true)
            let url = taskFileURL(projectDir: projectDir, taskId: task.id)
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
        }
    }

    static func syncTasks(project: Project, context: ModelContext, appState: AppState) throws {
        guard isVaultConfigured(appState) else { return }
        try withVaultRoot(appState) { root in
            let projectDir = try ensureProjectDirectories(vaultRoot: root, project: project)
            let tasksDir = projectDir.appendingPathComponent("tasks", isDirectory: true)
            let files = try listTextFiles(under: tasksDir)
            var diskIds = Set<UUID>()
            for url in files {
                guard let id = UUID(uuidString: url.deletingPathExtension().lastPathComponent.lowercased()) else { continue }
                diskIds.insert(id)
                let data = try Data(contentsOf: url)
                guard let text = String(data: data, encoding: .utf8) else { continue }
                let parsed = parseTaskFile(text)
                if let existing = project.tasks.first(where: { $0.id == id }) {
                    existing.title = parsed.title
                    existing.isCompleted = parsed.isCompleted
                    existing.completedAt = parsed.completedAt
                    existing.dueDate = parsed.dueDate
                    existing.createdAt = parsed.createdAt
                } else {
                    let task = ProjectTask(
                        id: id,
                        title: parsed.title,
                        isCompleted: parsed.isCompleted,
                        completedAt: parsed.completedAt,
                        dueDate: parsed.dueDate,
                        createdAt: parsed.createdAt
                    )
                    task.project = project
                    context.insert(task)
                    project.tasks.append(task)
                }
            }

            if diskIds.isEmpty, !project.tasks.isEmpty {
                let projectDir = try ensureProjectDirectories(vaultRoot: root, project: project)
                for task in project.tasks {
                    let url = taskFileURL(projectDir: projectDir, taskId: task.id)
                    try serializeTask(task).write(to: url, atomically: true, encoding: .utf8)
                }
                project.updatedAt = Date()
                try context.save()
                return
            }

            let orphans = project.tasks.filter { !diskIds.contains($0.id) }
            for task in orphans {
                project.tasks.removeAll { $0.id == task.id }
                context.delete(task)
            }
            project.updatedAt = Date()
        }
        try context.save()
    }

    /// Writes every task to disk (e.g. after Reminders import).
    static func mirrorAllTasksToVault(project: Project, appState: AppState) throws {
        guard isVaultConfigured(appState) else { return }
        for task in project.tasks {
            try writeTask(task, project: project, appState: appState)
        }
    }

    static func mirrorAllNotesToVault(project: Project, appState: AppState) throws {
        guard isVaultConfigured(appState) else { return }
        for note in project.notes {
            try writeNote(note, project: project, appState: appState)
        }
    }

    /// Call when creating a project if a vault is configured so the folder exists immediately.
    static func prepareProjectDirectoryIfVaultEnabled(project: Project, appState: AppState) {
        guard isVaultConfigured(appState) else { return }
        try? withVaultRoot(appState) { root in
            _ = try ensureProjectDirectories(vaultRoot: root, project: project)
        }
    }

    // MARK: - Serialization

    private struct ParsedNote {
        var title: String?
        var body: String
        var createdAt: Date
    }

    private static func parseNoteFile(_ text: String) -> ParsedNote {
        let (header, body) = splitFrontmatter(text)
        var title: String?
        var createdAt = Date()
        if !header.isEmpty {
            for line in header.split(separator: "\n", omittingEmptySubsequences: false) {
                let s = String(line)
                if s.hasPrefix("title:") {
                    title = s.dropFirst(6).trimmingCharacters(in: .whitespaces)
                    if title == "" { title = nil }
                } else if s.hasPrefix("created:") {
                    let raw = s.dropFirst(8).trimmingCharacters(in: .whitespaces)
                    createdAt = parseISO8601(raw) ?? createdAt
                }
            }
        }
        return ParsedNote(title: title, body: body, createdAt: createdAt)
    }

    private static func serializeNote(_ note: Note) -> String {
        let created = iso8601.string(from: note.createdAt)
        let titleLine: String
        if let t = note.title, !t.isEmpty {
            titleLine = "title: \(t)\n"
        } else {
            titleLine = ""
        }
        return """
        ---
        id: \(note.id.uuidString)
        \(titleLine)created: \(created)
        ---

        \(note.content)
        """
    }

    private struct ParsedTask {
        var title: String
        var isCompleted: Bool
        var completedAt: Date?
        var dueDate: Date?
        var createdAt: Date
    }

    private static func parseTaskFile(_ text: String) -> ParsedTask {
        let (header, _) = splitFrontmatter(text)
        var title = ""
        var isCompleted = false
        var completedAt: Date?
        var dueDate: Date?
        var createdAt = Date()
        for line in header.split(separator: "\n", omittingEmptySubsequences: false) {
            let s = String(line)
            if s.hasPrefix("title:") {
                title = String(s.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            } else if s.hasPrefix("completed:") {
                let v = s.dropFirst(10).trimmingCharacters(in: .whitespaces).lowercased()
                isCompleted = (v == "true" || v == "1" || v == "yes")
            } else if s.hasPrefix("completedAt:") {
                let raw = s.dropFirst(12).trimmingCharacters(in: .whitespaces)
                completedAt = raw.isEmpty ? nil : parseISO8601(raw)
            } else if s.hasPrefix("due:") {
                let raw = s.dropFirst(4).trimmingCharacters(in: .whitespaces)
                dueDate = raw.isEmpty ? nil : parseISO8601(raw)
            } else if s.hasPrefix("created:") {
                let raw = s.dropFirst(8).trimmingCharacters(in: .whitespaces)
                createdAt = parseISO8601(raw) ?? createdAt
            }
        }
        return ParsedTask(
            title: title.isEmpty ? "Task" : title,
            isCompleted: isCompleted,
            completedAt: completedAt,
            dueDate: dueDate,
            createdAt: createdAt
        )
    }

    private static func serializeTask(_ task: ProjectTask) -> String {
        let completedStr = task.isCompleted ? "true" : "false"
        let completedAtStr = task.completedAt.map { iso8601.string(from: $0) } ?? ""
        let dueStr = task.dueDate.map { iso8601.string(from: $0) } ?? ""
        let createdStr = iso8601.string(from: task.createdAt)
        return """
        ---
        id: \(task.id.uuidString)
        title: \(task.title)
        completed: \(completedStr)
        completedAt: \(completedAtStr)
        due: \(dueStr)
        created: \(createdStr)
        ---

        """
    }

    private static func splitFrontmatter(_ text: String) -> (header: String, body: String) {
        guard text.hasPrefix("---\n") else { return ("", text) }
        let rest = text.dropFirst(4)
        guard let range = rest.range(of: "\n---\n") else { return ("", text) }
        let header = String(rest[..<range.lowerBound])
        let body = String(rest[range.upperBound...])
        return (header, body)
    }

    private static func parseISO8601(_ raw: String) -> Date? {
        iso8601.date(from: raw) ?? iso8601NoFrac.date(from: raw)
    }

    private static func listMarkdownFiles(under dir: URL) throws -> [URL] {
        try listFiles(under: dir, extensions: Set(["md"]))
    }

    private static func listTextFiles(under dir: URL) throws -> [URL] {
        try listFiles(under: dir, extensions: Set(["txt"]))
    }

    private static func listFiles(under dir: URL, extensions: Set<String>) throws -> [URL] {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: dir.path, isDirectory: &isDir), isDir.boolValue else { return [] }
        guard let enumerator = FileManager.default.enumerator(
            at: dir,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }
        var urls: [URL] = []
        for case let fileURL as URL in enumerator {
            if extensions.contains(fileURL.pathExtension.lowercased()) {
                urls.append(fileURL)
            }
        }
        return urls
    }

    private static func slugify(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "project" }
        let folded = trimmed.folding(options: .diacriticInsensitive, locale: .current)
        var out = ""
        var lastWasHyphen = false
        for ch in folded.lowercased() {
            if ch.isLetter || ch.isNumber {
                out.append(ch)
                lastWasHyphen = false
            } else if ch == " " || ch == "-" || ch == "_" {
                if !out.isEmpty, !lastWasHyphen {
                    out.append("-")
                    lastWasHyphen = true
                }
            }
        }
        while out.hasSuffix("-") { out.removeLast() }
        if out.isEmpty { return "project" }
        return String(out.prefix(48))
    }
}
