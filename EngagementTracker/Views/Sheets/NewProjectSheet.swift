import SwiftUI
import SwiftData

struct NewProjectSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @State private var name: String = ""
    @State private var accountName: String = ""
    @State private var opportunityID: String = ""
    @State private var isPOC: Bool = false
    @State private var estimatedValueString: String = ""
    @State private var targetCloseDate: Date = Date()
    @State private var hasCloseDate: Bool = false
    @State private var tagsString: String = ""
    @State private var initialStage: ProjectStage = .discovery
    @State private var selectedTemplate: ProjectTemplate? = nil

    private var availableTemplates: [ProjectTemplate] {
        guard let path = appState.templateFolderPath else { return [] }
        return ProjectTemplate.load(from: path)
    }

    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title bar
            HStack {
                Text("New Project")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.gruvFg)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
                Button("Create") { save() }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.gruvAqua)
                    .disabled(!isValid)
                    .keyboardShortcut(.return, modifiers: .command)
            }
            .padding()
            .background(Color.gruvBg1)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !availableTemplates.isEmpty {
                        FormSection(title: "Template") {
                            Picker("Apply Template", selection: $selectedTemplate) {
                                Text("None").tag(Optional<ProjectTemplate>.none)
                                ForEach(availableTemplates) { template in
                                    Text(template.name).tag(Optional(template))
                                }
                            }
                            .onChange(of: selectedTemplate) { _, template in
                                guard let t = template else { return }
                                isPOC = t.isPOC
                                tagsString = t.tags.joined(separator: ", ")
                                initialStage = t.projectStage
                            }
                        }
                    }

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
                            .foregroundStyle(Color.gruvFg)
                        if hasCloseDate {
                            DatePicker("Close Date", selection: $targetCloseDate, displayedComponents: .date)
                                .foregroundStyle(Color.gruvFg)
                        }
                        LabeledField(label: "Tags (comma-separated)") {
                            TextField("Optional", text: $tagsString)
                        }
                    }

                    FormSection(title: "Flags") {
                        Toggle("This is a POC engagement", isOn: $isPOC)
                            .foregroundStyle(Color.gruvFg)
                    }
                }
                .padding()
            }
        }
        .background(Color.gruvBg)
        .frame(width: 480)
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
            tags: tagsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
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
        }
        try? context.save()
        appState.selectedStage = project.stage
        appState.selectedProject = project
        dismiss()
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
                .foregroundStyle(Color.gruvFgDim)
            content
        }
        .padding()
        .background(Color.gruvBg1)
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
                .foregroundStyle(Color.gruvFgDim)
            content
                .textFieldStyle(.roundedBorder)
        }
    }
}
