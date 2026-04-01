// EngagementTracker/Views/Sheets/NewProjectSheet.swift
import SwiftUI
import SwiftData

struct NewProjectSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    private enum Step { case templatePicker, form }

    @State private var step: Step = .templatePicker
    @State private var selectedTemplate: ProjectTemplate? = nil

    // Form fields
    @State private var name: String = ""
    @State private var accountName: String = ""
    @State private var opportunityID: String = ""
    @State private var isPOC: Bool = false
    @State private var estimatedValueString: String = ""
    @State private var targetCloseDate: Date = Date()
    @State private var hasCloseDate: Bool = false
    @State private var tagsString: String = ""
    @State private var initialStage: ProjectStage = .discovery
    @State private var customFieldValues: [String] = []

    @State private var availableTemplates: [ProjectTemplate] = []

    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        Group {
            if step == .templatePicker, !availableTemplates.isEmpty {
                TemplatePickerView(
                    templates: availableTemplates,
                    selected: $selectedTemplate,
                    onContinue: { applyTemplateAndAdvance() },
                    onCancel: { dismiss() }
                )
            } else {
                formView
            }
        }
        .onAppear { loadTemplates() }
    }

    private var formView: some View {
        VStack(alignment: .leading, spacing: 0) {
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
                VStack(alignment: .leading, spacing: 20) {
                    FormSection(title: "Project") {
                        LabeledField(label: "Name *") {
                            TextField("Required", text: $name)
                        }
                        LabeledField(label: "Account / Company") {
                            TextField("Optional", text: $accountName)
                        }
                        LabeledField(label: "Opportunity ID") {
                            TextField("Optional", text: $opportunityID)
                        }
                        LabeledField(label: "Initial Stage") {
                            Picker("", selection: $initialStage) {
                                ForEach(ProjectStage.allCases) { stage in
                                    Text(stage.rawValue).tag(stage)
                                }
                            }
                            .labelsHidden()
                        }
                    }

                    FormSection(title: "Details") {
                        LabeledField(label: "Estimated Value") {
                            TextField("e.g. 240000", text: $estimatedValueString)
                        }
                        Toggle("Has Target Close Date", isOn: $hasCloseDate)
                            .foregroundStyle(Color.themeFg)
                        if hasCloseDate {
                            DatePicker("Close Date", selection: $targetCloseDate, displayedComponents: .date)
                                .foregroundStyle(Color.themeFg)
                        }
                        LabeledField(label: "Tags (resource types, comma-separated)") {
                            TextField("e.g. vpc, iks, powervs", text: $tagsString)
                        }
                    }

                    FormSection(title: "Flags") {
                        Toggle("This is a POC engagement", isOn: $isPOC)
                            .foregroundStyle(Color.themeFg)
                    }

                    if let template = selectedTemplate, !template.customFields.isEmpty {
                        FormSection(title: "Template Fields") {
                            ForEach(Array(template.customFields.enumerated()), id: \.offset) { index, field in
                                LabeledField(label: field.label) {
                                    TextField(field.placeholder ?? "", text: Binding(
                                        get: { index < customFieldValues.count ? customFieldValues[index] : "" },
                                        set: { if index < customFieldValues.count { customFieldValues[index] = $0 } }
                                    ))
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color.themeBg)
        .frame(width: 480)
    }

    private func applyTemplateAndAdvance() {
        if let t = selectedTemplate {
            isPOC = t.isPOC
            tagsString = t.tags.joined(separator: ", ")
            initialStage = t.projectStage
            customFieldValues = Array(repeating: "", count: t.customFields.count)
        }
        step = .form
    }

    private func save() {
        let project = Project(
            name: name.trimmingCharacters(in: .whitespaces),
            accountName: accountName.isEmpty ? nil : accountName,
            opportunityID: opportunityID.isEmpty ? nil : opportunityID,
            stage: initialStage,
            isPOC: isPOC,
            estimatedValueCents: parseCents(estimatedValueString),
            targetCloseDate: hasCloseDate ? targetCloseDate : nil,
            tags: tagsString.split(separator: ",")
                .map { "#\($0.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "#")))" }
                .filter { $0 != "#" }
        )
        context.insert(project)
        let checkpoints = CheckpointSeeder.makeAllCheckpoints()
        checkpoints.forEach { cp in
            project.checkpoints.append(cp)
            context.insert(cp)
        }
        if let template = selectedTemplate {
            template.taskTitles.forEach { title in
                let task = ProjectTask(title: title)
                project.tasks.append(task)
                context.insert(task)
            }
            template.customFields.enumerated().forEach { index, fieldDef in
                let field = ProjectCustomField(
                    label: fieldDef.label,
                    value: index < customFieldValues.count ? customFieldValues[index] : "",
                    sortOrder: index
                )
                field.project = project
                project.customFields.append(field)
                context.insert(field)
            }
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
}

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
