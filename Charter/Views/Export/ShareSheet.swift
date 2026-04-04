import SwiftUI
import SwiftData
import UniformTypeIdentifiers

enum ShareTab: String, CaseIterable, Identifiable {
    case engagements = "Engagements"
    case contacts    = "Contacts"
    case tasks       = "Tasks"
    case notes       = "Notes"
    case checkpoints = "Checkpoints"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .engagements: return "calendar"
        case .contacts:    return "person.2"
        case .tasks:       return "checklist"
        case .notes:       return "note.text"
        case .checkpoints: return "flag"
        }
    }
}

enum ShareFormat: String, CaseIterable, Identifiable {
    case json = "JSON"
    case csv  = "CSV (Excel-compatible)"
    var id: String { rawValue }
}

struct ShareSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Project.name) private var allProjects: [Project]

    @State private var selectedProject: Project?
    @State private var selectedTabs: Set<ShareTab> = Set(ShareTab.allCases)
    @State private var format: ShareFormat = .json
    @State private var isExporting = false
    @State private var exportError: String?

    private var activeProjects: [Project] { allProjects.filter(\.isActive) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Share Project Data")
                    .font(.title3.bold())
                    .foregroundStyle(Color.themeFg)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
            }
            .padding()
            .background(Color.themeBg1)

            Divider()

            VStack(alignment: .leading, spacing: 20) {
                FormSection(title: "Project") {
                    Picker("Project", selection: $selectedProject) {
                        Text("Select a project…").tag(Optional<Project>.none)
                        ForEach(activeProjects) { project in
                            Text(project.name).tag(Optional(project))
                        }
                    }
                    .foregroundStyle(Color.themeFg)
                }

                FormSection(title: "Include") {
                    HStack(spacing: 6) {
                        ForEach(ShareTab.allCases) { tab in
                            ShareTabToggle(
                                tab: tab,
                                isSelected: selectedTabs.contains(tab)
                            ) {
                                if selectedTabs.contains(tab) {
                                    selectedTabs.remove(tab)
                                } else {
                                    selectedTabs.insert(tab)
                                }
                            }
                        }
                    }
                    if selectedTabs.isEmpty {
                        Text("Select at least one section to export.")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.themeRed)
                    }
                }

                FormSection(title: "Format") {
                    Picker("Format", selection: $format) {
                        ForEach(ShareFormat.allCases) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    .foregroundStyle(Color.themeFg)
                    Text(format == .json
                         ? "Single JSON file. Can be re-imported into Charter."
                         : "One CSV per section, bundled as a ZIP. Open in Excel.")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.themeFgDim)
                }

                if let error = exportError {
                    Text("Export failed: \(error)")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.themeRed)
                }

                Button(action: performExport) {
                    Label("Share…", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.themeAqua)
                .disabled(isExporting || selectedProject == nil || selectedTabs.isEmpty)
            }
            .padding()
        }
        .background(Color.themeBg)
        .frame(width: 500)
        .onAppear { selectedProject = activeProjects.first }
    }

    private func performExport() {
        guard let project = selectedProject else { return }
        isExporting = true
        exportError = nil

        var exported = ExportService.project(from: project)
        if !selectedTabs.contains(.contacts)    { exported.contacts    = [] }
        if !selectedTabs.contains(.tasks)        { exported.tasks       = [] }
        if !selectedTabs.contains(.notes)        { exported.notes       = [] }
        if !selectedTabs.contains(.engagements)  { exported.engagements = [] }
        if !selectedTabs.contains(.checkpoints)  { exported.checkpoints = [] }

        let safeName = project.name.replacingOccurrences(of: "/", with: "-")
        let panel = NSSavePanel()
        panel.canCreateDirectories = true

        do {
            switch format {
            case .json:
                panel.allowedContentTypes = [.json]
                panel.nameFieldStringValue = "\(safeName)-export.json"
                if panel.runModal() == .OK, let url = panel.url {
                    let data = try ExportService.encodeJSON([exported])
                    try data.write(to: url)
                }
            case .csv:
                panel.allowedContentTypes = [UTType(filenameExtension: "zip") ?? .data]
                panel.nameFieldStringValue = "\(safeName)-export.zip"
                if panel.runModal() == .OK, let url = panel.url {
                    var csvFiles = ExportService.encodeCSV([exported])
                    // Remove files for unselected tabs
                    let tabFileMap: [ShareTab: String] = [
                        .contacts:    "contacts.csv",
                        .tasks:       "tasks.csv",
                        .notes:       "notes.csv",
                        .engagements: "engagements.csv"
                    ]
                    for (tab, filename) in tabFileMap where !selectedTabs.contains(tab) {
                        csvFiles.removeValue(forKey: filename)
                    }
                    try writeZip(csvFiles, to: url)
                }
            }
        } catch {
            exportError = error.localizedDescription
        }
        isExporting = false
        dismiss()
    }

    private func writeZip(_ files: [String: String], to destination: URL) throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        for (filename, content) in files {
            try content.write(to: tmpDir.appendingPathComponent(filename),
                              atomically: true, encoding: .utf8)
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

private struct ShareTabToggle: View {
    let tab: ShareTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(tab.rawValue, systemImage: tab.icon)
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? Color.themeAqua.opacity(0.2) : Color.themeBg2)
                .foregroundStyle(isSelected ? Color.themeAqua : Color.themeFgDim)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
