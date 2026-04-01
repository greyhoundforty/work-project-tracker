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
                    .foregroundStyle(Color.themeFg)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
            }
            .padding()
            .background(Color.themeBg1)

            Divider()

            VStack(alignment: .leading, spacing: 20) {
                FormSection(title: "Scope") {
                    LabeledContent("Exporting", value: scopeLabel)
                        .foregroundStyle(Color.themeFg)
                }

                FormSection(title: "Format") {
                    Picker("Format", selection: $format) {
                        ForEach(ExportFormat.allCases) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    .foregroundStyle(Color.themeFg)

                    if format == .json {
                        Text("One JSON file with all project data. Can be re-imported.")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.themeFgDim)
                    } else {
                        Text("One CSV per entity type (projects, contacts, tasks, notes, engagements) bundled as a ZIP. Open individual files in Excel.")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.themeFgDim)
                    }
                }

                if let error = exportError {
                    Text("Export failed: \(error)")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.themeRed)
                }

                Button(action: performExport) {
                    Label("Export…", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.themeAqua)
                .disabled(isExporting)
            }
            .padding()
        }
        .background(Color.themeBg)
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
