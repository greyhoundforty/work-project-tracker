// EngagementTracker/Views/Sheets/NewProjectSheet.swift
import SwiftUI
import SwiftData

struct NewProjectSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Query(sort: \ProjectFolder.sortOrder) private var folders: [ProjectFolder]

    @State private var name: String = ""
    @State private var summary: String = ""
    @State private var tagsString: String = ""
    @State private var selectedTemplate: ProjectTemplate? = nil
    @State private var customFieldValues: [String] = []
    @State private var availableTemplates: [ProjectTemplate] = []
    @State private var selectedFolderForNew: ProjectFolder? = nil

    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("New Project")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.themeFg)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
                Button("Create") { save() }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.themeAqua)
                    .disabled(!isValid)
                    .keyboardShortcut(.return, modifiers: .command)
            }
            .padding()
            .background(Color.themeBg1)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Always-visible top zone
                    FormSection(title: "Project") {
                        LabeledField(label: "Name *") {
                            TextField("Required", text: $name)
                        }
                        LabeledField(label: "Short Description") {
                            TextField("Optional", text: $summary)
                        }
                        LabeledField(label: "Tags (resource types, comma-separated)") {
                            TextField("e.g. vpc, iks, powervs", text: $tagsString)
                        }
                        LabeledField(label: "Folder") {
                            Picker("", selection: $selectedFolderForNew) {
                                Text("Unsorted").tag(Optional<ProjectFolder>.none)
                                ForEach(folders) { folder in
                                    Text(folder.name).tag(Optional(folder))
                                }
                            }
                            .labelsHidden()
                        }
                        LabeledField(label: "Template") {
                            Picker("", selection: $selectedTemplate) {
                                Text("Choose a template…").tag(Optional<ProjectTemplate>.none)
                                ForEach(availableTemplates) { template in
                                    Text(template.name).tag(Optional(template))
                                }
                            }
                            .labelsHidden()
                        }
                    }

                    // Template-driven lower zone
                    if let template = selectedTemplate, !template.customFields.isEmpty {
                        FormSection(title: template.name) {
                            ForEach(Array(template.customFields.enumerated()), id: \.offset) { index, field in
                                TemplateFieldRow(
                                    field: field,
                                    value: Binding(
                                        get: { index < customFieldValues.count ? customFieldValues[index] : "" },
                                        set: { if index < customFieldValues.count { customFieldValues[index] = $0 } }
                                    )
                                )
                            }
                        }
                    } else if selectedTemplate == nil {
                        HStack {
                            Spacer()
                            Text("Select a template to see its fields")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.themeFgDim)
                                .padding(.vertical, 24)
                            Spacer()
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color.themeBg)
        .frame(width: 480)
        .onAppear {
            loadTemplates()
            selectedFolderForNew = appState.selectedFolder
        }
        .onChange(of: selectedTemplate) { _, newTemplate in
            customFieldValues = Array(
                repeating: "",
                count: newTemplate?.customFields.count ?? 0
            )
        }
    }

    private func save() {
        var projectStage: ProjectStage = .discovery
        var isPOC = false
        var accountName: String? = nil
        var opportunityID: String? = nil
        var iscLink: String? = nil
        var gtmLink: String? = nil
        var oneDriveLink: String? = nil
        var estimatedValueCents: Int? = nil
        var targetCloseDate: Date? = nil
        var customFieldEntries: [(TemplateCustomField, String, Int)] = []

        if let template = selectedTemplate {
            // Seed template-level defaults
            isPOC = template.isPOC
            projectStage = template.projectStage

            for (index, fieldDef) in template.customFields.enumerated() {
                let value = index < customFieldValues.count ? customFieldValues[index] : ""
                switch fieldDef.key {
                case "accountName":
                    accountName = value.isEmpty ? nil : value
                case "opportunityID":
                    opportunityID = value.isEmpty ? nil : value
                case "iscOpportunityLink":
                    iscLink = value.isEmpty ? nil : value
                case "gtmNavAccountLink":
                    gtmLink = value.isEmpty ? nil : value
                case "oneDriveFolderLink":
                    oneDriveLink = value.isEmpty ? nil : value
                case "stage":
                    projectStage = ProjectStage(rawValue: value) ?? projectStage
                case "estimatedValue":
                    estimatedValueCents = parseCents(value)
                case "targetCloseDate":
                    targetCloseDate = parseDate(value)
                case "isPOC":
                    isPOC = value == "true"
                default:
                    customFieldEntries.append((fieldDef, value, index))
                }
            }
        }

        let tags = tagsString.split(separator: ",")
            .map { "#\($0.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "#")))" }
            .filter { $0 != "#" }

        let project = Project(
            name: name.trimmingCharacters(in: .whitespaces),
            accountName: accountName,
            opportunityID: opportunityID,
            stage: projectStage,
            isPOC: isPOC,
            estimatedValueCents: estimatedValueCents,
            targetCloseDate: targetCloseDate,
            tags: tags,
            iscOpportunityLink: iscLink,
            gtmNavAccountLink: gtmLink,
            oneDriveFolderLink: oneDriveLink
        )
        project.summary = summary.isEmpty ? nil : summary
        project.folder = selectedFolderForNew
        context.insert(project)

        if let template = selectedTemplate, !template.checkpoints.isEmpty {
            // Use template-defined checkpoints, tracking sort order per stage
            var sortOrders: [ProjectStage: Int] = [:]
            template.checkpoints.forEach { cp in
                let stage = cp.projectStage
                let order = sortOrders[stage, default: 0]
                let checkpoint = Checkpoint(title: cp.title, stage: stage, sortOrder: order)
                sortOrders[stage] = order + 1
                project.checkpoints.append(checkpoint)
                context.insert(checkpoint)
            }
        } else {
            CheckpointSeeder.makeAllCheckpoints().forEach { cp in
                project.checkpoints.append(cp)
                context.insert(cp)
            }
        }

        if let template = selectedTemplate {
            template.taskTitles.forEach { title in
                let task = ProjectTask(title: title)
                project.tasks.append(task)
                context.insert(task)
            }
        }

        for (fieldDef, value, sortOrder) in customFieldEntries {
            let field = ProjectCustomField(label: fieldDef.label, value: value, sortOrder: sortOrder)
            field.project = project
            project.customFields.append(field)
            context.insert(field)
        }

        do {
            try context.save()
            appState.selectedStage = project.stage
            appState.selectedProject = project
            dismiss()
        } catch {
            print("[NewProjectSheet] context.save() failed: \(error)")
        }
    }

    private func loadTemplates() {
        var templates = ProjectTemplate.loadBundled()
        if let url = appState.resolveTemplateFolderURL() {
            let userTemplates = ProjectTemplate.load(from: url)
            let userNames = Set(userTemplates.map(\.name))
            templates = templates.filter { !userNames.contains($0.name) } + userTemplates
        }
        templates.sort { $0.name < $1.name }
        availableTemplates = templates
    }

    private func parseCents(_ string: String) -> Int? {
        let digits = string.filter { $0.isNumber || $0 == "." }
        guard let value = Double(digits) else { return nil }
        return Int(value * 100)
    }

    private func parseDate(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: string)
    }
}

// MARK: - Template Field Row

private struct TemplateFieldRow: View {
    let field: TemplateCustomField
    @Binding var value: String

    var body: some View {
        switch field.type {
        case .text:
            LabeledField(label: field.label) {
                TextField(field.placeholder ?? "", text: $value)
            }
        case .url:
            LabeledField(label: field.label) {
                TextField(field.placeholder ?? "https://", text: $value)
                    .textContentType(.URL)
            }
        case .toggle:
            Toggle(field.label, isOn: Binding(
                get: { value == "true" },
                set: { value = $0 ? "true" : "false" }
            ))
            .foregroundStyle(Color.themeFg)
        case .stagePicker:
            LabeledField(label: field.label) {
                Picker("", selection: $value) {
                    if value.isEmpty {
                        Text("Choose…").tag("")
                    }
                    ForEach(field.options ?? [], id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .labelsHidden()
                .onAppear {
                    if value.isEmpty, let first = field.options?.first {
                        value = first
                    }
                }
            }
        case .date:
            LabeledField(label: field.label) {
                DatePicker(
                    "",
                    selection: Binding(
                        get: { parseISO(value) ?? Date() },
                        set: { value = formatISO($0) }
                    ),
                    displayedComponents: .date
                )
                .labelsHidden()
            }
        }
    }

    private func parseISO(_ string: String) -> Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f.date(from: string)
    }

    private func formatISO(_ date: Date) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f.string(from: date)
    }
}

// MARK: - Shared form components

struct FormSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.themeFgDim)
            content
        }
        .padding()
        .background(Color.themeBg1)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct LabeledField<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.themeFgDim)
            content
                .textFieldStyle(.roundedBorder)
        }
    }
}
