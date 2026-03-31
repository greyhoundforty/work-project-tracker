# Quick-Capture Menu Bar Integration — Design Spec

**Date:** 2026-03-31  
**Issue:** greyhoundforty/work-project-tracker#4  
**Branch:** `emdash/feat-quick-capture-menu-bar-tl4`  
**Status:** Approved

---

## Overview

Replace the existing "New Project" / "Log Engagement" button row in the menu bar popover with a fully inline quick-capture UI. Users can log an engagement, add a task, or add a note to any active project without leaving the popover or opening the main app window.

---

## Architecture

### Files Changed

| File | Change |
|------|--------|
| `Views/MenuBar/MenuBarPopoverView.swift` | Remove sheet state + modifiers, replace quick-actions zone with `QuickCaptureView`, move "New Project" to footer |
| `Views/MenuBar/QuickCaptureView.swift` | **New** — self-contained capture component |
| `EngagementTrackerTests/QuickCaptureTests.swift` | **New** — unit tests |

No changes to models, services, app entry point, or other views.

---

## Components

### `QuickCaptureView`

Self-contained `View` struct in `Views/MenuBar/QuickCaptureView.swift`.

**State:**
- `captureType: CaptureType` — `.engagement` (default), `.task`, `.note`
- `selectedProject: Project?` — defaults to `activeProjects.first` on appear
- `showProjectPicker: Bool` — controls inline project picker visibility
- Per-type fields: `summary: String`, `date: Date`, `taskTitle: String`, `dueDate: Date?`, `hasDueDate: Bool`, `noteTitle: String`, `noteContent: String`

**Dependencies:**
- `@Environment(\.modelContext)` — for SwiftData insert
- `@Query(sort: \Project.updatedAt, order: .reverse)` — for active project list

**`save()` method:**
1. Switch on `captureType`, create the appropriate model, insert into `selectedProject`
2. Set `selectedProject.updatedAt = Date()`
3. Call `modelContext.insert()`
4. Reset all field state; retain `captureType` and `selectedProject`

### `MenuBarPopoverView` (modified)

- Remove `showNewProject`, `showLogEngagement` `@State` vars
- Remove `.sheet(isPresented: $showNewProject)` and `.sheet(isPresented: $showLogEngagement)` modifiers
- Replace quick-actions `HStack` with `QuickCaptureView()`
- Add "New Project" button to footer (between "Open App" and gear icon), with its own local `@State var showNewProject` and `.sheet()` modifier

---

## UI Layout

`QuickCaptureView` is a `VStack` with three zones:

### Zone 1 — Type Selector
`Picker("", selection: $captureType)` with `.segmented` style.  
Labels: `Engagement | Task | Note`

### Zone 2 — Form Fields

**Engagement:**
- `TextEditor` for summary (3 lines, required)
- `DatePicker("Date", selection: $date, displayedComponents: .date)` — compact style, defaults to today

**Task:**
- `TextField("Title", text: $taskTitle)` — single line, required
- `Toggle("Add due date", isOn: $hasDueDate)` — when on, shows `DatePicker` with `.date` and `.hourAndMinute` components

**Note:**
- `TextField("Title (optional)", text: $noteTitle)` — single line
- `TextEditor` for content (3 lines, required)

### Zone 3 — Project Row + Save

```
[ ● Acme Corp  Discovery   change ]    [ Save ]
```

- Left: stage-colored dot + project name + stage label + muted "change" button
- "change" toggles `showProjectPicker`; when true, a `Picker(.menu)` listing all active projects by name replaces the row until selection is confirmed
- Right: "Save" button (`.borderedProminent`) — disabled when required fields are empty or `selectedProject == nil`

**Required field rules:**
- Engagement: `!summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty`
- Task: `!taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty`
- Note: `!noteContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty`

---

## Data Flow

1. `save()` runs synchronously on the main actor — no async needed
2. SwiftData autosave handles persistence; no explicit `try modelContext.save()` call
3. `project.updatedAt = Date()` ensures the project surfaces as "last touched" on next open
4. Fields reset after save; `captureType` and `selectedProject` persist for the session

**Error handling:** The only failure mode is no active projects. Save button is disabled when `activeProjects.isEmpty`. No error alerts required — same pattern as existing "Log Engagement" button.

---

## Testing

New file: `EngagementTrackerTests/QuickCaptureTests.swift`  
Uses Swift Testing (`@Test`, `#expect`) with an in-memory `ModelContainer`.

| Test | Assertion |
|------|-----------|
| Engagement save | Creates `Engagement` on correct project with correct date and summary |
| Task save (no due date) | Creates `ProjectTask` with nil `dueDate` |
| Task save (with due date) | Creates `ProjectTask` with correct `dueDate` |
| Note save (no title) | Creates `Note` with nil title and correct content |
| Note save (with title) | Creates `Note` with correct title and content |
| Save disabled — empty summary | Save action is no-op when summary is blank |
| Save disabled — empty task title | Save action is no-op when task title is blank |
| Save disabled — empty note content | Save action is no-op when note content is blank |
| `updatedAt` bumped | `project.updatedAt` advances after any save |
| Project change mid-capture | Save writes to the newly selected project, not the original default |

---

## Out of Scope

- Contact selection on inline engagement capture (use main app for that)
- New project creation inline (remains as sheet, moved to footer)
- Any capture type beyond the three defined above
- Animations or transitions between capture types
