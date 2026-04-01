# Bundled Templates Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bundle three default project templates into the Manifest app so they are always available without any user configuration, while still allowing users to add their own templates via the Settings folder picker.

**Architecture:** Three JSON files are added to `EngagementTracker/BundledTemplates/` and registered as app bundle resources in `project.yml`. `ProjectTemplate` gains an `isBuiltIn` flag and a `loadBundled()` method. `NewProjectSheet` and `SettingsView` both merge bundled templates with any user-configured templates, with user templates winning on name collisions.

**Tech Stack:** Swift, SwiftUI, XcodeGen (`project.yml`), Swift Testing framework (existing test suite pattern)

---

## File Map

| Action | Path | Purpose |
|--------|------|---------|
| Create | `EngagementTracker/BundledTemplates/base-project.json` | Built-in template |
| Create | `EngagementTracker/BundledTemplates/personal-development.json` | Built-in template |
| Create | `EngagementTracker/BundledTemplates/freelance-client.json` | Built-in template |
| Modify | `project.yml` | Register `BundledTemplates/` folder as app bundle resource |
| Modify | `EngagementTracker/Models/ProjectTemplate.swift` | Add `isBuiltIn`, `loadBundled()` |
| Create | `EngagementTrackerTests/BundledTemplatesTests.swift` | Tests for `loadBundled()` |
| Modify | `EngagementTracker/Views/Sheets/NewProjectSheet.swift` | Always load bundled templates |
| Modify | `EngagementTracker/Views/Settings/SettingsView.swift` | Show built-ins + Built-in badge |

---

## Task 1: Add JSON files and register as bundle resources

**Files:**
- Create: `EngagementTracker/BundledTemplates/base-project.json`
- Create: `EngagementTracker/BundledTemplates/personal-development.json`
- Create: `EngagementTracker/BundledTemplates/freelance-client.json`
- Modify: `project.yml`

- [ ] **Step 1: Create the BundledTemplates directory and JSON files**

```bash
mkdir -p EngagementTracker/BundledTemplates
```

Write `EngagementTracker/BundledTemplates/base-project.json`:
```json
{
  "name": "Base Project",
  "isPOC": false,
  "stage": "Discovery",
  "tags": [],
  "taskTitles": [
    "Define project goals",
    "Identify key stakeholders",
    "Set milestones",
    "Review progress at midpoint",
    "Document outcomes",
    "Close out project"
  ]
}
```

Write `EngagementTracker/BundledTemplates/personal-development.json`:
```json
{
  "name": "Personal Development",
  "isPOC": false,
  "stage": "Discovery",
  "tags": ["personal", "learning"],
  "taskTitles": [
    "Define learning goals",
    "Gather resources and references",
    "Set a practice schedule",
    "Complete core study or coursework",
    "Build a small proof project",
    "Review progress against goals",
    "Share or publish learnings"
  ]
}
```

Write `EngagementTracker/BundledTemplates/freelance-client.json`:
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

- [ ] **Step 2: Register BundledTemplates as a bundle resource in project.yml**

In `project.yml`, find the `Manifest:` target block (which has `sources: - EngagementTracker`). Add a `resources:` key at the same level as `sources:`:

```yaml
targets:
  Manifest:
    type: application
    platform: macOS
    sources:
      - EngagementTracker
    resources:
      - path: EngagementTracker/BundledTemplates
        type: folder
    settings:
      ...
```

The `type: folder` creates a folder reference in Xcode, preserving the `BundledTemplates/` subdirectory path inside the app bundle — required for `Bundle.main.urls(forResourcesWithExtension:subdirectory:)` to work.

- [ ] **Step 3: Regenerate the Xcode project**

```bash
xcodegen generate
```

Expected: `Generating project Manifest` with no errors.

- [ ] **Step 4: Verify the folder appears in the bundle**

```bash
mise run build 2>&1 | tail -3
```

Expected: `BUILD SUCCEEDED`

Then verify the JSON files are in the built app bundle:
```bash
find ~/Library/Developer/Xcode/DerivedData/Manifest-*/Build/Products/Debug/Manifest.app \
  -name "*.json" -path "*/BundledTemplates/*"
```

Expected: three lines showing `base-project.json`, `freelance-client.json`, `personal-development.json` inside `BundledTemplates/` within the bundle.

If the files are at the bundle root (not in a `BundledTemplates/` subdirectory), the folder reference did not work. In that case, open `Manifest.xcodeproj` in Xcode, find the three JSON files in the project navigator, select them, open File Inspector, and verify "Location" shows them inside a blue folder reference. If they're yellow group folders, remove them and re-add `EngagementTracker/BundledTemplates` as a folder reference manually, then commit the updated xcodeproj.

- [ ] **Step 5: Commit**

```bash
git add EngagementTracker/BundledTemplates/ project.yml Manifest.xcodeproj
git commit -m "feat: add BundledTemplates JSON files and register as app resources"
```

---

## Task 2: Add `isBuiltIn` and `loadBundled()` to ProjectTemplate

**Files:**
- Modify: `EngagementTracker/Models/ProjectTemplate.swift`
- Create: `EngagementTrackerTests/BundledTemplatesTests.swift`

- [ ] **Step 1: Write the failing tests first**

Create `EngagementTrackerTests/BundledTemplatesTests.swift`:

```swift
import Testing
@testable import Manifest

struct BundledTemplatesTests {

    @Test("loadBundled returns exactly 3 templates")
    func loadBundledCount() {
        let templates = ProjectTemplate.loadBundled()
        #expect(templates.count == 3)
    }

    @Test("loadBundled templates all have isBuiltIn = true")
    func loadBundledIsBuiltIn() {
        let templates = ProjectTemplate.loadBundled()
        #expect(templates.allSatisfy(\.isBuiltIn))
    }

    @Test("loadBundled templates have expected names")
    func loadBundledNames() {
        let names = Set(ProjectTemplate.loadBundled().map(\.name))
        #expect(names.contains("Base Project"))
        #expect(names.contains("Personal Development"))
        #expect(names.contains("freelance-client"))
    }

    @Test("loadBundled returns templates sorted by name")
    func loadBundledSorted() {
        let names = ProjectTemplate.loadBundled().map(\.name)
        #expect(names == names.sorted())
    }

    @Test("user-loaded templates have isBuiltIn = false")
    func userLoadedIsNotBuiltIn() {
        // load(from:) is the user-folder loader — results must never be flagged as built-in
        // We test this by confirming the default value is false (no URL needed)
        let template = ProjectTemplate.loadBundled().first!
        // Make a copy via encode/decode — simulates what load(from:) does
        let data = try! JSONEncoder().encode(template)
        let decoded = try! JSONDecoder().decode(ProjectTemplate.self, from: data)
        #expect(decoded.isBuiltIn == false)
    }
}
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
mise run test 2>&1 | grep -E "BundledTemplates|FAILED|error:"
```

Expected: compile error — `loadBundled()` does not exist yet, and `isBuiltIn` property does not exist.

- [ ] **Step 3: Add `isBuiltIn` and `loadBundled()` to ProjectTemplate.swift**

Open `EngagementTracker/Models/ProjectTemplate.swift`. The current file ends after the `load(from:)` method. Make two additions:

**Add `isBuiltIn` property** — place it after `var id: String { name }`, before `let name: String`:

```swift
var isBuiltIn: Bool = false
```

This property is intentionally absent from `CodingKeys`, so it is never serialised to or deserialised from JSON. The default is `false`; only `loadBundled()` sets it to `true`.

**Add `loadBundled()` method** — place it after the existing `load(from:)` method:

```swift
static func loadBundled() -> [ProjectTemplate] {
    guard let urls = Bundle.main.urls(
        forResourcesWithExtension: "json",
        subdirectory: "BundledTemplates"
    ) else { return [] }
    return urls.compactMap { url -> ProjectTemplate? in
        guard let data = try? Data(contentsOf: url),
              var template = try? JSONDecoder().decode(ProjectTemplate.self, from: data)
        else { return nil }
        template.isBuiltIn = true
        return template
    }.sorted { $0.name < $1.name }
}
```

The complete updated file should look like:

```swift
// EngagementTracker/Models/ProjectTemplate.swift
import Foundation

struct TemplateCustomField: Codable, Hashable {
    let label: String
    let placeholder: String?
}

struct ProjectTemplate: Codable, Identifiable, Hashable {
    var id: String { name }
    var isBuiltIn: Bool = false      // ← new; not in CodingKeys
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
        // isBuiltIn intentionally excluded — set programmatically, never from JSON
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

    static func loadBundled() -> [ProjectTemplate] {    // ← new
        guard let urls = Bundle.main.urls(
            forResourcesWithExtension: "json",
            subdirectory: "BundledTemplates"
        ) else { return [] }
        return urls.compactMap { url -> ProjectTemplate? in
            guard let data = try? Data(contentsOf: url),
                  var template = try? JSONDecoder().decode(ProjectTemplate.self, from: data)
            else { return nil }
            template.isBuiltIn = true
            return template
        }.sorted { $0.name < $1.name }
    }
}
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
mise run test 2>&1 | grep -E "BundledTemplates|Test Suite|SUCCEEDED|FAILED"
```

Expected: all 5 `BundledTemplatesTests` pass, overall `TEST SUCCEEDED`.

- [ ] **Step 5: Commit**

```bash
git add EngagementTracker/Models/ProjectTemplate.swift \
        EngagementTrackerTests/BundledTemplatesTests.swift
git commit -m "feat: add isBuiltIn property and loadBundled() to ProjectTemplate"
```

---

## Task 3: Update NewProjectSheet to always load bundled templates

**Files:**
- Modify: `EngagementTracker/Views/Sheets/NewProjectSheet.swift`

The current `.onAppear` (around line 44) is:

```swift
.onAppear {
    if let url = appState.resolveTemplateFolderURL() {
        availableTemplates = ProjectTemplate.load(from: url)
    }
}
```

This produces an empty `availableTemplates` when no user folder is configured, which causes `NewProjectSheet` to skip the template picker and go straight to the form.

- [ ] **Step 1: Replace `.onAppear` with a `loadTemplates()` helper**

Find the `.onAppear` block and replace it — and add the private helper below it (or above `var body`):

```swift
// Replace .onAppear:
.onAppear { loadTemplates() }

// Add private helper (place alongside the other private methods in the file):
private func loadTemplates() {
    var templates = ProjectTemplate.loadBundled()
    if let url = appState.resolveTemplateFolderURL() {
        let userTemplates = ProjectTemplate.load(from: url)
        let userNames = Set(userTemplates.map(\.name))
        templates = templates.filter { !userNames.contains($0.name) } + userTemplates
        templates.sort { $0.name < $1.name }
    }
    availableTemplates = templates
}
```

No other changes to `NewProjectSheet` — `availableTemplates` is already wired to `TemplatePickerView`.

- [ ] **Step 2: Build and smoke-test manually**

```bash
mise run run
```

Expected: opening "New Project" now shows the template picker with 3 templates (Base Project, Personal Development, freelance-client) even with no template folder configured in Settings. Selecting one and creating a project should work as before.

- [ ] **Step 3: Run tests**

```bash
mise run test 2>&1 | tail -5
```

Expected: `TEST SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add EngagementTracker/Views/Sheets/NewProjectSheet.swift
git commit -m "feat: always load bundled templates in NewProjectSheet"
```

---

## Task 4: Update SettingsView to show built-ins and add Built-in badge

**Files:**
- Modify: `EngagementTracker/Views/Settings/SettingsView.swift`

The current `loadedTemplates` computed property (around line 12) returns `[]` when no user folder is configured:

```swift
private var loadedTemplates: [ProjectTemplate] {
    guard let url = appState.resolveTemplateFolderURL() else { return [] }
    return ProjectTemplate.load(from: url)
}
```

The current template list section (around line 68) is only shown when `!loadedTemplates.isEmpty`. The `ForEach` rows have four columns: NAME, STAGE, POC, TASKS.

- [ ] **Step 1: Replace `loadedTemplates` with the merging implementation**

```swift
private var loadedTemplates: [ProjectTemplate] {
    var templates = ProjectTemplate.loadBundled()
    if let url = appState.resolveTemplateFolderURL() {
        let userTemplates = ProjectTemplate.load(from: url)
        let userNames = Set(userTemplates.map(\.name))
        templates = templates.filter { !userNames.contains($0.name) } + userTemplates
        templates.sort { $0.name < $1.name }
    }
    return templates
}
```

- [ ] **Step 2: Add a SOURCE column header**

Find the HStack that shows the column headers (NAME, STAGE, POC, TASKS) and add a SOURCE header at the end:

```swift
HStack {
    Text("NAME").frame(maxWidth: .infinity, alignment: .leading)
    Text("STAGE").frame(width: 110, alignment: .leading)
    Text("POC").frame(width: 36, alignment: .center)
    Text("TASKS").frame(width: 44, alignment: .trailing)
    Text("SOURCE").frame(width: 60, alignment: .trailing)   // ← new
}
.font(.system(size: 10, weight: .semibold))
.foregroundStyle(Color.themeFgDim)
.padding(.horizontal, 10)
.padding(.vertical, 5)
```

- [ ] **Step 3: Add the Built-in badge to each template row**

Find the `ForEach(loadedTemplates)` HStack and add the source cell at the end of the row:

```swift
ForEach(loadedTemplates) { template in
    HStack {
        Text(template.name)
            .frame(maxWidth: .infinity, alignment: .leading)
        Text(template.stage)
            .foregroundStyle(.secondary)
            .frame(width: 110, alignment: .leading)
        Image(systemName: template.isPOC ? "checkmark" : "minus")
            .foregroundStyle(template.isPOC ? Color.themeGreen : Color.themeFgDim)
            .frame(width: 36, alignment: .center)
        Text("\(template.taskTitles.count)")
            .foregroundStyle(.secondary)
            .frame(width: 44, alignment: .trailing)
        // ← new source cell:
        Group {
            if template.isBuiltIn {
                Text("Built-in")
                    .foregroundStyle(.secondary)
            } else {
                Text("Custom")
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(width: 60, alignment: .trailing)
    }
    .font(.system(size: 11))
    .foregroundStyle(Color.themeFg)
    .padding(.horizontal, 10)
    .padding(.vertical, 5)
```

- [ ] **Step 4: Build and verify Settings shows templates without a folder configured**

```bash
mise run run
```

Open Settings (⌘,). Under the Templates section, the table should show 3 rows with "Built-in" in the SOURCE column even when "No folder selected" is shown above.

- [ ] **Step 5: Run tests**

```bash
mise run test 2>&1 | tail -5
```

Expected: `TEST SUCCEEDED`

- [ ] **Step 6: Commit**

```bash
git add EngagementTracker/Views/Settings/SettingsView.swift
git commit -m "feat: show built-in templates in Settings with Built-in badge"
```

---

## Self-Review Checklist

After all tasks complete, verify:

- [ ] `mise run build` → BUILD SUCCEEDED
- [ ] `mise run test` → TEST SUCCEEDED (all 5 BundledTemplatesTests pass)
- [ ] New project sheet shows 3 templates with no folder configured
- [ ] New project sheet shows 3 + N templates when a folder with N templates is configured
- [ ] A user template named "Base Project" in a configured folder replaces the built-in of that name
- [ ] Settings template table shows 3 rows with "Built-in" badge when no folder configured
- [ ] Settings template table shows merged list with "Built-in" / "Custom" badges when folder configured
