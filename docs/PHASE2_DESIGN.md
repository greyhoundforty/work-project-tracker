# UI Polish — Q1 Design Doc

**Branch:** `emdash/feat-work-ui-polish-q1l`
**Date:** 2026-03-30
**Status:** Approved

---

## Overview

Two independent improvements to the Engagement Tracker app:

1. **Bluloco-inspired light theme** — replace the existing Gruvbox light-mode palette with a cleaner, more vivid set of colors. Dark mode (Gruvbox) is unchanged.
2. **Markdown support in Notes** — render note content as formatted markdown in view mode; tap a note row to edit raw markdown in a `TextEditor`.

---

## Feature 1: Light Theme Refresh

### Direction

The current light mode uses warm/earthy Gruvbox cream tones (`#FBF1C7` background). The new palette is inspired by [Bluloco Light](https://github.com/uloco/theme-bluloco-light): clean near-white backgrounds with vivid, saturated accent colors. Dark mode stays 100% unchanged.

### Color Palette

| Role | Old (Gruvbox Light) | New (Bluloco-Inspired) |
|------|--------------------|-----------------------|
| bg   | `#FBF1C7` | `#F9F9F9` |
| bg1  | `#EBDBB2` | `#EFEFEF` |
| bg2  | `#D5C4A1` | `#E2E2E2` |
| bg3  | `#BDAE93` | `#D0D0D0` |
| fg   | `#3C3836` | `#383A42` |
| fg2  | `#504945` | `#696C77` |
| fgDim| `#928374` | `#A0A1A7` |
| red  | `#9D0006` | `#D52753` |
| green| `#79740E` | `#23974A` |
| yellow| `#B57614` | `#C5A332` |
| blue | `#076678` | `#275FE4` |
| purple| `#8F3F71` | `#7A3E9D` |
| aqua | `#427B58` | `#0098DD` |
| orange| `#AF3A03` | `#DF631C` |

### Rename: GruvboxColors → AppColors

To avoid misleading names as the light theme diverges from Gruvbox, rename all color identifiers to theme-neutral names. This is a one-time find-replace while the codebase is small (~3,150 lines).

| Old name | New name |
|----------|----------|
| `gruvBg` | `themeBg` |
| `gruvBg1` | `themeBg1` |
| `gruvBg2` | `themeBg2` |
| `gruvBg3` | `themeBg3` |
| `gruvFg` | `themeFg` |
| `gruvFg2` | `themeFg2` |
| `gruvFgDim` | `themeFgDim` |
| `gruvRed` | `themeRed` |
| `gruvGreen` | `themeGreen` |
| `gruvYellow` | `themeYellow` |
| `gruvBlue` | `themeBlue` |
| `gruvPurple` | `themePurple` |
| `gruvAqua` | `themeAqua` |
| `gruvOrange` | `themeOrange` |
| `gruvStageColor(for:)` | `themeStageColor(for:)` |

**Files affected:** `GruvboxColors.swift` → `AppColors.swift`, all 6 tab views, `ContentView.swift`, `ProjectListView.swift`, `StagesSidebarView.swift`, all sheet views, `MenuBarPopoverView.swift`, `SettingsView.swift`.

### Implementation

- Update the "Any" (light) appearance values in each `.xcassets` color set JSON
- Rename `GruvboxColors.swift` to `AppColors.swift`; rename all `Color.gruvX` extensions to `Color.themeX`
- No logic changes — all color references stay semantic, only values change
- Dark mode appearance values in `.xcassets` are untouched

---

## Feature 2: Markdown Notes

### Interaction Model

**Edit/preview toggle per note row:**

- **View mode (default):** Note content rendered via `AttributedString(markdown:)` inside a `Text` view. Supports bold, italic, inline code, headers, and unordered lists.
- **Edit mode:** Triggered by tapping the note row or the pencil icon. Shows a `TextEditor` with the raw markdown source and a `themeBg` background with a `themeAqua` border. Save/Cancel buttons appear below.
- Opening a second note's editor automatically closes any currently open editor (one editor open at a time).
- The trash/delete button remains in view mode only (hidden while editing).

### Changes to `NotesTabView.swift`

`NoteRowView` gains:
- `@State private var isEditing: Bool = false`
- `@State private var editedContent: String` (local copy, initialized from `note.content`)
- A tap gesture on the view-mode content that sets `isEditing = true`
- Conditional rendering: `isEditing` shows `TextEditor` + action buttons; otherwise shows `Text(attributedContent)`
- A computed `var attributedContent: AttributedString` that parses `note.content` via `try? AttributedString(markdown: note.content)`; falls back to `AttributedString(note.content)` plain text on parse failure
- Save action: writes `editedContent` back to `note.content`, calls `try? context.save()`, sets `isEditing = false`
- Cancel action: resets `editedContent` to `note.content`, sets `isEditing = false`

`NotesTabView` gains:
- `@State private var editingNoteID: UUID? = nil` to coordinate the one-at-a-time constraint
- Passed down to `NoteRowView` as a binding so opening one row closes others

### Markdown Support Scope

Using SwiftUI's built-in `AttributedString(markdown:)` — zero new dependencies.

Supported (natively):
- `**bold**`, `*italic*`, `~~strikethrough~~`
- `` `inline code` ``
- `# H1`, `## H2`, `### H3`
- `- unordered list items`
- `[link text](url)`

Not supported (out of scope for this iteration):
- Tables
- Fenced code blocks with syntax highlighting
- Nested lists beyond one level

### Files Changed

| File | Change |
|------|--------|
| `Views/Tabs/NotesTabView.swift` | Add edit/preview toggle to `NoteRowView`; add `editingNoteID` coordination to `NotesTabView` |

No model changes — `Note.content` remains a plain `String`; markdown is a rendering concern only.

---

## Out of Scope

- Markdown in other tabs (checkpoints, tasks, engagements)
- A third theme or theme protocol abstraction
- Markdown toolbar / formatting shortcuts
- Syntax-highlighted code blocks

---

## Testing Notes

- Build and run app in both Light and Dark mode; verify dark mode colors are unchanged
- Add a note with `**bold**`, `*italic*`, `# header`, and `- list` — confirm rendered output
- Tap a note row, edit content, save — confirm persistence across app relaunch
- Tap a note row, tap a different row — confirm first closes before second opens
- Run existing unit tests; no new test coverage required (UI-only changes)
