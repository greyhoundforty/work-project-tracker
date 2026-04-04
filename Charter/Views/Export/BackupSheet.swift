import SwiftUI
import SwiftData

struct BackupSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var isExporting = false
    @State private var exportError: String?
    @State private var didSucceed = false

    private static let filenameFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH-mm-ss"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Backup Projects")
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
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.themeAqua)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Creates a timestamped JSON backup of all active projects, including contacts, tasks, notes, engagements, and checkpoints.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.themeFg)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("The backup file can be re-imported at any time.")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.themeFgDim)
                    }
                }

                if didSucceed {
                    Label("Backup created successfully.", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.themeGreen)
                }

                if let error = exportError {
                    Text("Backup failed: \(error)")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.themeRed)
                }

                Button(action: performBackup) {
                    Label(isExporting ? "Creating Backup…" : "Create Backup…", systemImage: "archivebox")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.themeAqua)
                .disabled(isExporting)
            }
            .padding()
        }
        .background(Color.themeBg)
        .frame(width: 400)
    }

    private func performBackup() {
        isExporting = true
        exportError = nil
        didSucceed = false

        let projects = (try? context.fetch(FetchDescriptor<Project>(
            predicate: #Predicate { $0.isActive }
        ))) ?? []
        let exported = projects.map { ExportService.project(from: $0) }

        do {
            let data = try ExportService.encodeJSON(exported)
            let timestamp = Self.filenameFormatter.string(from: Date())
            let panel = NSSavePanel()
            panel.canCreateDirectories = true
            panel.allowedContentTypes = [.json]
            panel.nameFieldStringValue = "charter-backup-\(timestamp).json"
            if panel.runModal() == .OK, let url = panel.url {
                try data.write(to: url)
                didSucceed = true
            }
        } catch {
            exportError = error.localizedDescription
        }
        isExporting = false
    }
}
