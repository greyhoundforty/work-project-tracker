# Template Choice Interface Design

**Date:** 2026-04-02
**Branch:** emdash/feat-template-choice-interface-4h8
**Status:** Approved

## Summary

Replace the current two-step new-project flow (template picker screen → form screen) with a single sheet. The template picker moves inline — directly below the project name — and the lower portion of the form is blank until a template is selected, at which point the template's typed fields appear.

## Goals

- Single-screen new project creation
- Template choice is made inline, not as a separate step
- Fields below the top section are entirely driven by the selected template
- Different templates can define completely different field sets, including custom stage options

## Always-Visible Fields (top zone)

Shown for every template, including Blank:

- **Name** (required, String)
- **Short Description** (optional, String — new field on `Project`)
- **Tags** (optional, comma-separated String)
- **Template** (Picker/dropdown — replaces the separate TemplatePickerView step)

## Template-Driven Fields (lower zone)

Empty until a template is selected. Rendered dynamically from the template's `customFields` array. Each field has a `type` that controls which SwiftUI control is rendered.

Blank template → nothing shown below.

## Data Model Changes

### `TemplateCustomField` (in `ProjectTemplate.swift`)

Add `type: FieldType` (defaults to `.text` if absent in JSON) and `options: [String]?` (used by `stage-picker`):

```swift
struct TemplateCustomField: Codable, Hashable {
    let label: String
    let placeholder: String?
    let type: FieldType
    let options: [String]?

    enum FieldType: String, Codable {
        case text
        case url
        case toggle
        case stagePicker = "stage-picker"
        case date
    }

    // CodingKeys + init(from:) to default type to .text when absent
}
```

### `Project` (in `Project.swift`)

- Add `var summary: String?` (the short description field)
- Remove named fields that move to template customFields: `opportunityID`, `iscOpportunityLink`, `gtmNavAccountLink`, `oneDriveFolderLink`
- SwiftData handles the migration automatically (all optional fields)

### `ProjectCustomField` — unchanged

Template field values continue to be stored here. No schema change needed.

## Template JSON Changes

### `base-project.json` — no change
No `customFields`. When selected, lower zone is empty. Pre-seeds tasks only.

### `personal-development.json` — add stage picker
```json
"customFields": [
  { "label": "Stage", "type": "stage-picker", "options": ["Planning", "In Progress", "On Hold", "Done"] }
]
```

### `freelance-client.json` — add explicit types
Existing fields get `"type": "text"` added. No behavior change.

### `work-tracking.json` — new file
Captures all IBM/work-tracking-specific fields previously hardcoded in the form:
```json
{
  "name": "Work Tracking",
  "isPOC": false,
  "stage": "Discovery",
  "tags": [],
  "taskTitles": ["Define project goals", "Identify key stakeholders", "Set milestones", "Review progress at midpoint", "Document outcomes", "Close out project"],
  "customFields": [
    { "label": "Account / Company", "type": "text", "placeholder": "Optional" },
    { "label": "Opportunity ID", "type": "text", "placeholder": "Optional" },
    { "label": "ISC Opportunity Link", "type": "url", "placeholder": "https://…" },
    { "label": "GTM Nav Account Link", "type": "url", "placeholder": "https://…" },
    { "label": "Initial Stage", "type": "stage-picker", "options": ["Discovery", "Initial Delivery", "Refine", "Proposal", "Won", "Lost"] },
    { "label": "Estimated Value", "type": "text", "placeholder": "e.g. 240000" },
    { "label": "Target Close Date", "type": "date" },
    { "label": "POC Engagement", "type": "toggle" }
  ]
}
```

## View Changes

### `NewProjectSheet.swift`

- Remove `Step` enum, `step: Step` state, and `if step == .templatePicker` branch
- Remove `applyTemplateAndAdvance()`
- Remove hardcoded `@State` fields: `accountName`, `opportunityID`, `estimatedValueString`, `hasCloseDate`, `targetCloseDate`, `isPOC`, `initialStage` — all values live in `customFieldValues: [String]`
- Add `@State private var description: String = ""`
- Add `.onChange(of: selectedTemplate)` to reset `customFieldValues` when template changes
- Restructure `formView` into two `FormSection` blocks:
  1. Top zone: Name, Description, Tags, Template picker
  2. Lower zone: `ForEach` over `selectedTemplate?.customFields` using `TemplateFieldRow`
- Add empty-state placeholder when no template is selected

**New private view `TemplateFieldRow`** (in same file):
Renders the appropriate control based on `field.type`:
- `.text` → `TextField`
- `.url` → `TextField` with URL keyboard type
- `.toggle` → `Toggle` (value stored as "true"/"false" string)
- `.stagePicker` → `Picker` over `field.options`
- `.date` → `DatePicker` (value stored as ISO8601 string)

### `save()` changes
- Write `summary` from `description` field
- Remove writes to `accountName`, `opportunityID`, `iscOpportunityLink` etc. as named properties
- All template field values written as `ProjectCustomField` entries (already the case for custom fields)
- Note: `isPOC` is no longer a named toggle — if a template includes a POC toggle field, its value is stored as a custom field string. The `Project.isPOC` Bool property may be removed or kept as `false` default.

### `TemplatePickerView.swift` — deleted
No longer called from anywhere.

## Out of Scope

- Editing existing projects to change their template
- Custom user-defined stage options beyond what's in template JSON
- Migration of existing project data from named fields to custom fields
