# Bundled Templates Design

**Date:** 2026-04-01
**Status:** Approved

---

## Overview

Bundle the three existing example templates (`Base Project`, `Personal Development`, `freelance-client`) directly into the app so they are always available without any user configuration. Users can extend the built-in set by pointing the app at their own template folder in Settings.

---

## Goals

- Templates work on first launch with zero setup
- User-configured templates augment (not replace) the built-ins
- User templates with the same name as a built-in silently win (override)
- Settings shows all available templates; built-ins are visually distinguished with a "Built-in" badge
- No new UI surfaces or user-facing decisions required

## Out of Scope

- Editing or deleting built-in templates from within the app
- Adding new built-in templates (done by shipping new app versions)
- Any first-launch onboarding flow

---

## File Changes

| Action | Path |
|--------|------|
| Create | `EngagementTracker/BundledTemplates/base-project.json` |
| Create | `EngagementTracker/BundledTemplates/personal-development.json` |
| Create | `EngagementTracker/BundledTemplates/freelance-client.json` |
| Modify | `project.yml` — add `BundledTemplates` resource folder to Manifest target |
| Modify | `EngagementTracker/Models/ProjectTemplate.swift` — add `isBuiltIn` property + `loadBundled()` |
| Modify | `EngagementTracker/Views/Sheets/NewProjectSheet.swift` — merge bundled + user templates on appear |
| Modify | `EngagementTracker/Views/Settings/SettingsView.swift` — show built-ins, add "Built-in" badge |

The files in `examples/templates/` are left in place (they serve as documentation and import examples).

---

## 1. Bundle Resources

Three JSON files are copied into `EngagementTracker/BundledTemplates/` with content identical to the existing `examples/templates/` files.

`project.yml` gains a `resources` entry on the Manifest target:

```yaml
targets:
  Manifest:
    ...
    sources:
      - EngagementTracker
    resources:
      - path: EngagementTracker/BundledTemplates
        type: folder
```

XcodeGen will include the folder's contents in the app bundle under `BundledTemplates/`.

---

## 2. ProjectTemplate Model

Two additions to `ProjectTemplate.swift`:

**`isBuiltIn` property** — non-Codable, defaults to `false`. Not listed in `CodingKeys`, so it is never read from or written to JSON. Set to `true` only by `loadBundled()`.

```swift
var isBuiltIn: Bool = false
```

**`loadBundled()` static method** — reads all `.json` files from `Bundle.main` at the `BundledTemplates` subdirectory, decodes each as `ProjectTemplate`, sets `isBuiltIn = true`, returns sorted by name.

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

---

## 3. NewProjectSheet — Template Merging

The existing `.onAppear` block currently loads templates only when `templateFolderURL` is set. Replace with a `loadTemplates()` helper that always runs:

```swift
private func loadTemplates() {
    var templates = ProjectTemplate.loadBundled()
    if let url = appState.templateFolderURL {
        let userTemplates = ProjectTemplate.load(from: url)
        // User templates override built-ins with the same name
        let userNames = Set(userTemplates.map(\.name))
        templates = templates.filter { !userNames.contains($0.name) } + userTemplates
        templates.sort { $0.name < $1.name }
    }
    availableTemplates = templates
}
```

Called from `.onAppear { loadTemplates() }`.

The `TemplatePickerView` and the rest of the sheet are unchanged — they already consume `availableTemplates`.

---

## 4. SettingsView — Template List

`loadedTemplates` currently returns an empty array when no folder is configured. Replace the computed property with one that always includes built-ins:

```swift
private var loadedTemplates: [ProjectTemplate] {
    var templates = ProjectTemplate.loadBundled()
    if let url = appState.templateFolderURL {
        let userTemplates = ProjectTemplate.load(from: url)
        let userNames = Set(userTemplates.map(\.name))
        templates = templates.filter { !userNames.contains($0.name) } + userTemplates
        templates.sort { $0.name < $1.name }
    }
    return templates
}
```

In the template table `ForEach`, add a "Built-in" badge for built-in entries:

```swift
ForEach(loadedTemplates) { template in
    TableRow(template) {
        // ... existing columns ...
        TableColumn("Source") { t in
            if t.isBuiltIn {
                Text("Built-in")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
```

The exact TableColumn implementation depends on the existing table structure — the badge text and style follow the app's existing secondary-text conventions.

---

## Data Flow

```
App launch
  └── NewProjectSheet.onAppear
        ├── loadBundled()  →  reads BundledTemplates/ from Bundle.main
        └── load(from:)    →  reads user folder (if configured)
              └── merge (user wins on name collision)
                    └── availableTemplates → TemplatePickerView

Settings
  └── loadedTemplates (computed)
        ├── loadBundled()
        └── load(from:) (if configured)
              └── merge → ForEach with Built-in badge
```

---

## Testing

- `ProjectTemplate.loadBundled()` returns exactly 3 templates on a clean install
- `isBuiltIn` is `true` for all 3 bundled templates and `false` for user-loaded templates
- If user folder contains a template named "Base Project", it replaces the built-in in both `NewProjectSheet` and `SettingsView`
- App with no template folder configured shows 3 templates in new-project picker
- App with a template folder configured shows bundled + user templates merged
