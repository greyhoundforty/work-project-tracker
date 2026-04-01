# Per-Template Project Creation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the project creation form adapt per template — templates declare custom text fields, creation becomes a two-step flow (template picker → form), and custom field values are stored, editable, and searchable.

**Architecture:** New `ProjectCustomField` SwiftData model stores per-project custom fields. `ProjectTemplate` gains a `customFields: [TemplateCustomField]` array (backward-compatible via custom decoder). `NewProjectSheet` becomes a two-step flow: `TemplatePickerView` (step 1) then the form (step 2), which renders a "Template Fields" section when the selected template has custom fields. Custom fields appear as an editable card in `OverviewTabView` and are included in the existing in-memory search filter.

**Tech Stack:** Swift 5.9, SwiftUI, SwiftData, Swift Testing (`@Suite`/`@Test`/`#expect`)

---

## File Map

| Action | Path |
|--------|------|
| Create | `EngagementTracker/Models/ProjectCustomField.swift` |
| Modify | `EngagementTracker/Models/Project.swift` |
| Modify | `EngagementTracker/Models/ProjectTemplate.swift` |
| Modify | `EngagementTracker/App/AppState.swift` |
| Create | `EngagementTracker/Views/Sheets/TemplatePickerView.swift` |
| Modify | `EngagementTracker/Views/Sheets/NewProjectSheet.swift` |
| Modify | `EngagementTracker/Views/Tabs/OverviewTabView.swift` |
| Modify | `EngagementTracker/Views/Main/ProjectListView.swift` |
| Modify | `EngagementTracker/Views/MenuBar/MenuBarPopoverView.swift` |
| Create | `EngagementTrackerTests/ProjectCustomFieldTests.swift` |
| Modify | `EngagementTrackerTests/SearchFilterTests.swift` |
| Modify | `examples/templates/freelance-client.json` |

---

## Task 1: `ProjectCustomField` model + schema registration

**Files:**
- Create: `EngagementTracker/Models/ProjectCustomField.swift`
- Modify: `EngagementTracker/Models/Project.swift`
- Modify: `EngagementTracker/App/AppState.swift`
- Create: `EngagementTrackerTests/ProjectCustomFieldTests.swift`

- [ ] **Step 1: Write the failing tests**

```swift
// EngagementTrackerTests/ProjectCustomFieldTests.swift
import Testing
@testable import EngagementTracker

@Suite("ProjectCustomField")
struct ProjectCustomFieldTests {

    @Test func initDefaultsValueToEmptyString() {
        let field = ProjectCustomField(label: "Contract Number", sortOrder: 0)
        #expect(field.label == "Contract Number")
        #expect(field.value == "")
        #expect(field.sortOrder == 0)
    }

    @Test func initWithValue() {
        let field = ProjectCustomField(label: "Contract Number", value: "CNT-001", sortOrder: 0)
        #expect(field.value == "CNT-001")
    }

    @Test func projectStartsWithNoCustomFields() {
        let project = Project(name: "Test")
        #expect(project.customFields.isEmpty)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Open Xcode → Product → Test (⌘U). Expected: compile error — `ProjectCustomField` not defined, `project.customFields` not found.

- [ ] **Step 3: Create `ProjectCustomField.swift`**

```swift
// EngagementTracker/Models/ProjectCustomField.swift
import Foundation
import SwiftData

@Model
final class ProjectCustomField {
    var label: String
    var value: String
    var sortOrder: Int
    var project: Project?

    init(label: String, value: String = "", sortOrder: Int) {
        self.label = label
        self.value = value
        self.sortOrder = sortOrder
    }
}
```

- [ ] **Step 4: Add `customFields` relationship to `Project`**

In `EngagementTracker/Models/Project.swift`, add after the `notes` relationship line (line 26):

```swift
    @Relationship(deleteRule: .cascade) var customFields: [ProjectCustomField] = []
```

In the same file's `init`, add after `self.notes = []` (line 60):

```swift
        self.customFields = []
```

- [ ] **Step 5: Register `ProjectCustomField` in the SwiftData schema**

In `EngagementTracker/App/AppState.swift`, update `makeContainer` (lines 48–55):

```swift
    static func makeContainer(cloudSync: Bool) -> ModelContainer {
        let schema = Schema([
            Project.self,
            Contact.self,
            Checkpoint.self,
            ProjectTask.self,
            Engagement.self,
            Note.self,
            ProjectCustomField.self
        ])
```

- [ ] **Step 6: Run tests — all three should pass**

Expected: `ProjectCustomFieldTests` suite passes (3 tests green).

- [ ] **Step 7: Commit**

```bash
git add EngagementTracker/Models/ProjectCustomField.swift \
        EngagementTracker/Models/Project.swift \
        EngagementTracker/App/AppState.swift \
        EngagementTrackerTests/ProjectCustomFieldTests.swift
git commit -m "feat: add ProjectCustomField SwiftData model and schema registration"
```

---

## Task 2: Extend `ProjectTemplate` with `TemplateCustomField`

**Files:**
- Modify: `EngagementTracker/Models/ProjectTemplate.swift`
- Modify: `EngagementTrackerTests/ProjectCustomFieldTests.swift`
- Modify: `examples/templates/freelance-client.json`

- [ ] **Step 1: Add template-decoding tests**

Append to `EngagementTrackerTests/ProjectCustomFieldTests.swift`:

```swift
    // MARK: - TemplateCustomField decoding

    @Test func decodesTemplateWithoutCustomFields() throws {
        let json = """
        {"name":"base","isPOC":false,"tags":[],"stage":"Discovery","taskTitles":[]}
        """.data(using: .utf8)!
        let template = try JSONDecoder().decode(ProjectTemplate.self, from: json)
        #expect(template.customFields.isEmpty)
    }

    @Test func decodesTemplateWithCustomFields() throws {
        let json = """
        {"name":"client","isPOC":false,"tags":[],"stage":"Discovery","taskTitles":[],
         "customFields":[{"label":"Contract Number","placeholder":"CNT-001"}]}
        """.data(using: .utf8)!
        let template = try JSONDecoder().decode(ProjectTemplate.self, from: json)
        #expect(template.customFields.count == 1)
        #expect(template.customFields[0].label == "Contract Number")
        #expect(template.customFields[0].placeholder == "CNT-001")
    }

    @Test func decodesTemplateWithCustomFieldMissingPlaceholder() throws {
        let json = """
        {"name":"client","isPOC":false,"tags":[],"stage":"Discovery","taskTitles":[],
         "customFields":[{"label":"Contract Number"}]}
        """.data(using: .utf8)!
        let template = try JSONDecoder().decode(ProjectTemplate.self, from: json)
        #expect(template.customFields[0].placeholder == nil)
    }
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: compile error — `template.customFields` not found, `ProjectTemplate` has no `customFields` property.

- [ ] **Step 3: Replace `ProjectTemplate.swift` with extended version**

```swift
// EngagementTracker/Models/ProjectTemplate.swift
import Foundation

struct TemplateCustomField: Codable, Hashable {
    let label: String
    let placeholder: String?
}

struct ProjectTemplate: Codable, Identifiable, Hashable {
    var id: String { name }
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
```

- [ ] **Step 4: Run tests — all three new template tests should pass**

Expected: 3 new tests green (existing tests still pass).

- [ ] **Step 5: Update `freelance-client.json` with sample custom fields**

```json
{
  "name": "freelance-client",
  "isPOC": false,
  "tags": ["freelance", "client"],
  "stage": "Discovery",
  "taskTitles": [
    "Proposal sent",
    "Contract signed",
    "Kickoff meeting held",
    "Milestone 1 delivered",
    "Feedback collected",
    "Final deliverable sent",
    "Invoice sent",
    "Sign-off received"
  ],
  "customFields": [
    { "label": "Contract Number", "placeholder": "e.g. CNT-2026-001" },
    { "label": "Client Contact", "placeholder": "Name or email" }
  ]
}
```

- [ ] **Step 6: Commit**

```bash
git add EngagementTracker/Models/ProjectTemplate.swift \
        EngagementTrackerTests/ProjectCustomFieldTests.swift \
        examples/templates/freelance-client.json
git commit -m "feat: extend ProjectTemplate with TemplateCustomField (backward-compatible)"
```

---

## Task 3: `TemplatePickerView` + two-step `NewProjectSheet`

**Files:**
- Create: `EngagementTracker/Views/Sheets/TemplatePickerView.swift`
- Modify: `EngagementTracker/Views/Sheets/NewProjectSheet.swift`

No unit tests for pure SwiftUI views — verify manually by running the app.

- [ ] **Step 1: Create `TemplatePickerView.swift`**

```swift
// EngagementTracker/Views/Sheets/TemplatePickerView.swift
import SwiftUI

struct TemplatePickerView: View {
    let templates: [ProjectTemplate]
    @Binding var selected: ProjectTemplate?
    let onContinue: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("New Project")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.themeFg)
                Spacer()
                Button("Cancel") { onCancel() }
                    .keyboardShortcut(.escape, modifiers: [])
                Button("Continue") { onContinue() }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.themeAqua)
                    .keyboardShortcut(.return, modifiers: .command)
            }
            .padding()
            .background(Color.themeBg1)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("CHOOSE A TEMPLATE")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.themeFgDim)
                        .padding(.bottom, 4)

                    TemplatePickerRow(
                        name: "Blank Project",
                        stage: nil,
                        taskCount: 0,
                        customFieldCount: 0,
                        isSelected: selected == nil,
                        onSelect: { selected = nil }
                    )

                    ForEach(templates) { template in
                        TemplatePickerRow(
                            name: template.name,
                            stage: template.stage,
                            taskCount: template.taskTitles.count,
                            customFieldCount: template.customFields.count,
                            isSelected: selected?.id == template.id,
                            onSelect: { selected = template }
                        )
                    }
                }
                .padding()
            }
        }
        .background(Color.themeBg)
        .frame(width: 480)
    }
}

private struct TemplatePickerRow: View {
    let name: String
    let stage: String?
    let taskCount: Int
    let customFieldCount: Int
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.themeAqua : Color.themeFgDim)
                    .font(.system(size: 16))

                VStack(alignment: .leading, spacing: 3) {
                    Text(name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.themeFg)
                    HStack(spacing: 8) {
                        if let stage {
                            Text(stage)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.themeFgDim)
                        }
                        if taskCount > 0 {
                            Text("\(taskCount) task\(taskCount == 1 ? "" : "s")")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.themeFgDim)
                        }
                        if customFieldCount > 0 {
                            Text("\(customFieldCount) field\(customFieldCount == 1 ? "" : "s")")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.themeFgDim)
                        }
                    }
                }
                Spacer()
            }
            .padding(10)
            .background(isSelected ? Color.themeAqua.opacity(0.12) : Color.themeBg1)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 2: Replace `NewProjectSheet.swift` with the two-step version**

```swift
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

    private var availableTemplates: [ProjectTemplate] {
        guard let url = appState.resolveTemplateFolderURL() else { return [] }
        return ProjectTemplate.load(from: url)
    }

    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
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
```

- [ ] **Step 3: Build in Xcode — verify no compile errors**

Product → Build (⌘B). Fix any errors before continuing.

- [ ] **Step 4: Manual smoke test**

Run the app. Click "New Project":
- If template folder is configured with templates: template picker appears, "Blank Project" is pre-selected, Continue advances to form.
- If template folder is not configured: form appears directly.
- Select `freelance-client` template → Continue → "Template Fields" section shows "Contract Number" and "Client Contact" fields.
- Fill name, click Create → project is created, custom fields are stored.

- [ ] **Step 5: Commit**

```bash
git add EngagementTracker/Views/Sheets/TemplatePickerView.swift \
        EngagementTracker/Views/Sheets/NewProjectSheet.swift
git commit -m "feat: two-step project creation with TemplatePickerView and dynamic custom fields form"
```

---

## Task 4: Custom fields card in `OverviewTabView`

**Files:**
- Modify: `EngagementTracker/Views/Tabs/OverviewTabView.swift`

- [ ] **Step 1: Add `CustomFieldsCard` and `CustomFieldRow` structs to `OverviewTabView.swift`**

Append these structs at the end of `OverviewTabView.swift` (after the `OverviewInfoRow` extension, before the file ends):

```swift
// MARK: - Custom Fields Card

struct CustomFieldsCard: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var context

    private var sortedFields: [ProjectCustomField] {
        project.customFields.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        OverviewCard(title: "Template Fields") {
            ForEach(sortedFields) { field in
                CustomFieldRow(field: field, onSave: { try? context.save() })
            }
        }
    }
}

struct CustomFieldRow: View {
    @Bindable var field: ProjectCustomField
    let onSave: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(field.label)
                .font(.system(size: 12))
                .foregroundStyle(Color.themeFgDim)
                .frame(width: 90, alignment: .leading)
            TextField("", text: $field.value)
                .font(.system(size: 12))
                .foregroundStyle(Color.themeFg)
                .textFieldStyle(.roundedBorder)
                .onSubmit { onSave() }
        }
    }
}
```

- [ ] **Step 2: Insert `CustomFieldsCard` into `OverviewTabView.body`**

In `OverviewTabView.swift`, inside the `VStack` in `body`, add after the `OverviewCard(title: "Project Info")` closing brace (after line 53):

```swift
                if !project.customFields.isEmpty {
                    CustomFieldsCard(project: project)
                }
```

The `VStack` in `OverviewTabView.body` should now read:

```swift
            VStack(alignment: .leading, spacing: 20) {
                OverviewCard(title: "Project Info") {
                    // ... existing content unchanged ...
                }

                if !project.customFields.isEmpty {
                    CustomFieldsCard(project: project)
                }

                EngagementCalendarView(engagements: project.engagements)
            }
```

- [ ] **Step 3: Build in Xcode — verify no compile errors**

Product → Build (⌘B).

- [ ] **Step 4: Manual smoke test**

Create a project with the `freelance-client` template and enter values in custom fields. Open the project → Overview tab → "Template Fields" card shows the labels and values. Edit a value in the card and press Return — value persists after navigating away and back.

- [ ] **Step 5: Commit**

```bash
git add EngagementTracker/Views/Tabs/OverviewTabView.swift
git commit -m "feat: add editable Template Fields card to OverviewTabView"
```

---

## Task 5: Extend search to include custom field values

**Files:**
- Modify: `EngagementTracker/Views/Main/ProjectListView.swift`
- Modify: `EngagementTracker/Views/MenuBar/MenuBarPopoverView.swift`
- Modify: `EngagementTrackerTests/SearchFilterTests.swift`

- [ ] **Step 1: Add custom field search tests**

In `EngagementTrackerTests/SearchFilterTests.swift`, append inside the `SearchFilterTests` struct:

```swift
    @Test func matchesOnCustomFieldValue() {
        let project = Project(name: "Deal 001")
        let field = ProjectCustomField(label: "Contract Number", value: "CNT-2026-001", sortOrder: 0)
        field.project = project
        project.customFields.append(field)
        let q = "cnt-2026"
        let matches = project.customFields.contains { $0.value.lowercased().contains(q) }
        #expect(matches == true)
    }

    @Test func noMatchOnAbsentCustomFieldValue() {
        let project = Project(name: "Deal 001")
        let field = ProjectCustomField(label: "Contract Number", value: "CNT-2026-001", sortOrder: 0)
        field.project = project
        project.customFields.append(field)
        let q = "xyz"
        let matches = project.customFields.contains { $0.value.lowercased().contains(q) }
        #expect(matches == false)
    }

    @Test func emptyCustomFieldValueDoesNotMatch() {
        let project = Project(name: "Deal 001")
        let field = ProjectCustomField(label: "Contract Number", value: "", sortOrder: 0)
        field.project = project
        project.customFields.append(field)
        let q = "contract"
        let matches = project.customFields.contains { $0.value.lowercased().contains(q) }
        #expect(matches == false)
    }
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: compile error — `ProjectCustomField` not found in this test file scope. (It should be resolved since `ProjectCustomField` is in the same module — if the test file already imports `@testable import EngagementTracker`, it should compile. The tests should pass logically but verify the assertions hold.)

- [ ] **Step 3: Run tests to verify they pass**

Expected: all 3 new `SearchFilterTests` custom field tests green.

- [ ] **Step 4: Extend `ProjectListView` filter**

In `EngagementTracker/Views/Main/ProjectListView.swift`, update the `filtered` computed property's search block (lines 25–32). Replace:

```swift
        return byFilter.filter {
            $0.name.lowercased().contains(q) ||
            ($0.accountName?.lowercased().contains(q) ?? false) ||
            ($0.opportunityID?.lowercased().contains(q) ?? false) ||
            $0.tags.contains { $0.lowercased().contains(q) } ||
            $0.notes.contains { $0.content.lowercased().contains(q) } ||
            $0.stage.rawValue.lowercased().contains(q)
        }
```

With:

```swift
        return byFilter.filter {
            $0.name.lowercased().contains(q) ||
            ($0.accountName?.lowercased().contains(q) ?? false) ||
            ($0.opportunityID?.lowercased().contains(q) ?? false) ||
            $0.tags.contains { $0.lowercased().contains(q) } ||
            $0.notes.contains { $0.content.lowercased().contains(q) } ||
            $0.stage.rawValue.lowercased().contains(q) ||
            $0.customFields.contains { $0.value.lowercased().contains(q) }
        }
```

- [ ] **Step 5: Extend `MenuBarPopoverView` filter**

In `EngagementTracker/Views/MenuBar/MenuBarPopoverView.swift`, update the `filtered` computed property (lines 17–22). Replace:

```swift
        return activeProjects.filter {
            $0.name.lowercased().contains(q) ||
            ($0.accountName?.lowercased().contains(q) ?? false) ||
            $0.tags.contains { $0.lowercased().contains(q) } ||
            $0.stage.rawValue.lowercased().contains(q)
        }
```

With:

```swift
        return activeProjects.filter {
            $0.name.lowercased().contains(q) ||
            ($0.accountName?.lowercased().contains(q) ?? false) ||
            $0.tags.contains { $0.lowercased().contains(q) } ||
            $0.stage.rawValue.lowercased().contains(q) ||
            $0.customFields.contains { $0.value.lowercased().contains(q) }
        }
```

- [ ] **Step 6: Build and run all tests**

Product → Test (⌘U). Expected: all existing tests pass, 3 new custom field search tests pass.

- [ ] **Step 7: Commit**

```bash
git add EngagementTracker/Views/Main/ProjectListView.swift \
        EngagementTracker/Views/MenuBar/MenuBarPopoverView.swift \
        EngagementTrackerTests/SearchFilterTests.swift
git commit -m "feat: extend search to include custom field values"
```

---

## Self-Review

**Spec coverage check:**

| Spec requirement | Covered in |
|-----------------|-----------|
| `TemplateCustomField` Codable struct | Task 2 |
| `customFields` on `ProjectTemplate` (backward-compat) | Task 2 |
| `ProjectCustomField` SwiftData model | Task 1 |
| `customFields` relationship on `Project` | Task 1 |
| `ProjectCustomField` in schema | Task 1 |
| Two-step sheet (picker → form) | Task 3 |
| `TemplatePickerView` with Blank + template rows | Task 3 |
| Form skips picker when no templates configured | Task 3 (`!availableTemplates.isEmpty` condition) |
| Template Fields section in form | Task 3 |
| Custom fields inserted on save | Task 3 |
| Editable custom fields in project detail | Task 4 |
| Section hidden when no custom fields | Task 4 (`if !project.customFields.isEmpty`) |
| Search includes custom field values | Task 5 |
| Example template updated | Task 2 |

All spec requirements are covered. ✓
