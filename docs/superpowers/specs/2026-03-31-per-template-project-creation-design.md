# Per-Template Project Creation Flow — Design Spec

**Date:** 2026-03-31
**Issue:** #10 — Support per-template project creation flow
**Branch:** emdash/feat-per-template-project-creation-wr9

---

## Summary

Deepen template integration so that selecting a template shapes the project creation form itself. Templates declare their own custom text fields; the creation flow becomes a two-step sheet (template picker → form); custom field values are stored as queryable SwiftData entities, editable in the project detail view, and included in search.

---

## 1. Data Model

### `TemplateCustomField` (new Codable struct)

Declared inside `ProjectTemplate.swift`. Represents a single field definition in a template JSON.

```swift
struct TemplateCustomField: Codable {
    let label: String
    let placeholder: String?
}
```

### `ProjectTemplate` — extended

Add one new optional property (backward compatible — existing templates without `customFields` default to `[]`):

```swift
var customFields: [TemplateCustomField] = []
```

### Template JSON schema extension

```json
{
  "name": "freelance-client",
  "isPOC": false,
  "tags": ["freelance", "client"],
  "stage": "Discovery",
  "taskTitles": ["Proposal sent", "Contract signed"],
  "customFields": [
    { "label": "Contract Number", "placeholder": "e.g. CNT-2026-001" },
    { "label": "Client Contact Email", "placeholder": "" }
  ]
}
```

### `ProjectCustomField` (new SwiftData `@Model`)

```swift
@Model class ProjectCustomField {
    var label: String
    var value: String
    var sortOrder: Int
    var project: Project?

    init(label: String, value: String, sortOrder: Int) {
        self.label = label
        self.value = value
        self.sortOrder = sortOrder
    }
}
```

### `Project` — extended

Add one new relationship (cascade delete so custom fields are removed with the project):

```swift
@Relationship(deleteRule: .cascade) var customFields: [ProjectCustomField] = []
```

---

## 2. Creation Flow

### Step routing

`NewProjectSheet` manages a `Step` enum:

```swift
enum Step { case templatePicker, form }
```

- If no template folder is configured: skip to `.form` immediately (blank project, same as today).
- If a template folder is configured: open at `.templatePicker`.

### Step 1 — `TemplatePickerView`

A new view rendered inside `NewProjectSheet` when `step == .templatePicker`.

- **"Blank Project"** row at top — no template, goes directly to default form.
- One row per loaded template showing: name, stage badge, task count, custom field count.
- **Continue** button enabled once any selection is made.
- Selecting a template and tapping Continue advances to `.form`.

### Step 2 — `ProjectFormView`

The existing `NewProjectSheet` form fields extracted into a standalone `ProjectFormView` that accepts `selectedTemplate: ProjectTemplate?`.

- Renders all existing fields: name, accountName, opportunityID, stage, estimatedValue, targetCloseDate, tags, isPOC.
- If `selectedTemplate?.customFields` is non-empty: renders a **"Template Fields"** section at the bottom with a `TextField` per declared field (using label as title, placeholder as hint).
- All custom field bindings are `[String]` keyed by `sortOrder`.

### Save action

After standard project/checkpoint/task creation:

```swift
for (index, fieldDef) in template.customFields.enumerated() {
    let field = ProjectCustomField(
        label: fieldDef.label,
        value: customFieldValues[index],
        sortOrder: index
    )
    field.project = project
    context.insert(field)
}
```

Custom fields are inserted even when value is empty — the field definition is preserved so the project detail view knows what to show.

---

## 3. Project Detail View

### `CustomFieldsSectionView` (new reusable view)

Renders a list of `ProjectCustomField` entries as editable label/value rows. Used in two places:

1. **`ProjectFormView`** — during creation (binds to `[String]` staging array).
2. **`ProjectDetailView`** — after creation (binds directly to `ProjectCustomField.value`; changes persist immediately via SwiftData).

The section is hidden when `project.customFields.isEmpty`.

---

## 4. Search Extension

The existing search predicate is extended to match `customFields.value`:

```swift
#Predicate<Project> { project in
    project.name.localizedStandardContains(query) ||
    project.accountName.localizedStandardContains(query) ||
    project.customFields.contains { $0.value.localizedStandardContains(query) }
}
```

This allows users to find projects by any custom field value (e.g., searching a contract number surfaces the matching project).

---

## 5. File Changes Summary

| File | Change |
|------|--------|
| `Models/ProjectTemplate.swift` | Add `TemplateCustomField` struct; add `customFields` property to `ProjectTemplate` |
| `Models/ProjectCustomField.swift` | New file — `@Model` class |
| `Models/Project.swift` | Add `customFields` relationship |
| `Views/Sheets/NewProjectSheet.swift` | Refactor into two-step container with `Step` enum |
| `Views/Sheets/TemplatePickerView.swift` | New file — step 1 view |
| `Views/Sheets/ProjectFormView.swift` | New file — extracted form (step 2), accepts optional template |
| `Views/Shared/CustomFieldsSectionView.swift` | New file — reusable field editor |
| `Views/Tabs/ProjectDetailView.swift` | Add `CustomFieldsSectionView` section |
| `Services/SearchService.swift` (or inline predicate) | Extend predicate to include `customFields.value` |
| `examples/templates/*.json` | Update example templates with sample `customFields` |

---

## 6. Out of Scope

- Non-text field types (number, date, boolean) — deferred to a future iteration.
- Template-driven checkpoint or note population — separate feature.
- Reordering or deleting individual custom fields after project creation — not needed for v1.
- Custom field values appearing in export (CSV/JSON) — separate consideration.
