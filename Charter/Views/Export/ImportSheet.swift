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
                    .foregroundStyle(Color.themeFg)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
            }
            .padding()
            .background(Color.themeBg1)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !hasLoaded {
                        FormSection(title: "Load File") {
                            Text("Select a previously exported JSON file, or a projects.csv file.")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.themeFgDim)
                            Button("Choose File…") { pickFile() }
                                .buttonStyle(.borderedProminent)
                                .tint(Color.themeAqua)
                        }
                    } else {
                        // Preview
                        if !successes.isEmpty {
                            FormSection(title: "Will Import (\(successes.count))") {
                                ForEach(successes, id: \.name) { p in
                                    HStack {
                                        Text(p.name)
                                            .font(.system(size: 13))
                                            .foregroundStyle(Color.themeFg)
                                        Spacer()
                                        Text(p.stage)
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.themeFgDim)
                                        if !p.contacts.isEmpty {
                                            Text("\(p.contacts.count) contacts")
                                                .font(.system(size: 10))
                                                .foregroundStyle(Color.themeFgDim)
                                        }
                                    }
                                }

                                Toggle("Skip projects with duplicate names", isOn: $skipDuplicates)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.themeFg)
                            }
                        }

                        if !failures.isEmpty {
                            FormSection(title: "Skipped (\(failures.count))") {
                                ForEach(failures, id: \.0) { name, error in
                                    HStack(alignment: .top) {
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundStyle(Color.themeOrange)
                                            .font(.system(size: 12))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(name).font(.system(size: 12, weight: .semibold))
                                                .foregroundStyle(Color.themeFg)
                                            Text(error).font(.system(size: 11))
                                                .foregroundStyle(Color.themeFgDim)
                                        }
                                    }
                                }
                            }
                        }

                        if let error = importError {
                            Text(error).font(.system(size: 12)).foregroundStyle(Color.themeRed)
                        }

                        if showDone {
                            Text("✓ Imported \(successCount) project(s) successfully.")
                                .foregroundStyle(Color.themeGreen)
                        }

                        if !successes.isEmpty && !showDone {
                            Button(action: performImport) {
                                Label("Import \(successes.count) Project(s)", systemImage: "square.and.arrow.down")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.themeAqua)
                            .disabled(isImporting)
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color.themeBg)
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

            var nameToContactID: [String: UUID] = [:]
            for c in exported.contacts {
                let contact = Contact(
                    name: c.name, title: c.title, email: c.email,
                    type: ContactType(rawValue: c.type) ?? .external
                )
                context.insert(contact)
                project.contacts.append(contact)
                nameToContactID[c.name] = contact.id
            }

            for e in exported.engagements {
                let engagement = Engagement(
                    date: e.date,
                    summary: e.summary,
                    contactIDs: e.contactNames.compactMap { nameToContactID[$0] }
                )
                context.insert(engagement)
                project.engagements.append(engagement)
            }

            for t in exported.tasks {
                let task = ProjectTask(title: t.title)
                task.isCompleted = t.isCompleted
                task.completedAt = t.completedAt
                context.insert(task)
                project.tasks.append(task)
            }

            for n in exported.notes {
                let note = Note(title: n.title, content: n.content)
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
