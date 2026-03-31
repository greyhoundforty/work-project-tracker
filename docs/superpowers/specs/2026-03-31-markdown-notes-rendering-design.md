# Markdown Notes Rendering — Design Spec

**Date:** 2026-03-31
**Issue:** greyhoundforty/work-project-tracker#7
**Branch:** emdash/feat-markdown-notes-section-40p

## Problem

Notes are stored as raw markdown strings. The display path uses `AttributedString(markdown:)` which only renders bold, italic, inline code, and links — it does not render headers, code fences, tables, bullet/numbered lists, or blockquotes. Users writing structured notes with these elements see raw markup instead of formatted output. Additionally, notes have no title, making them hard to scan.

## Chosen Approach

1. Replace the `Text(attributedContent)` display path in `NoteRowView` with `MarkdownUI`'s `Markdown` view, styled with a custom theme matching the app's existing color tokens.
2. Add a `title` field to the `Note` model. Title is always displayed in bold. If the user leaves the title blank on save, it defaults to the note's creation date formatted as `"MMM d, yyyy"`.

## Dependency

- **Package:** `https://github.com/gonzalezreal/swift-markdown-ui`
- **Version:** `2.0.2` or later
- **Added via:** Xcode SPM package manager (already added in Task 1)

## Modified File: `EngagementTracker/Models/Note.swift`

Add `var title: String = ""` to the `Note` model. SwiftData handles lightweight migration automatically for properties with a default value — existing notes get `title = ""`.

## New File: `EngagementTracker/Theme/MarkdownTheme.swift`

A `Theme` extension named `.engagementTracker` using MarkdownUI's styling API:

| Element | Styling |
|---|---|
| Body text | `Color.themeFg`, size 13 |
| Inline code | Monospaced, `Color.themeAqua` fg, `Color.themeBg2` bg |
| Code blocks | Monospaced, `Color.themeAqua` fg, `Color.themeBg2` bg |
| Headings (H1–H3) | `Color.themeFg`, semibold, scaled sizes |
| Blockquotes | Left border `Color.themeYellow`, `Color.themeFgDim` text, italic |
| Links | `Color.themeBlue` |
| Lists | Default MarkdownUI list rendering, `Color.themeFg` |

## Modified File: `EngagementTracker/Views/Tabs/NotesTabView.swift`

**Add/edit UI:**
- Add a `TextField("Title (optional)", text: $titleField)` above the `TextEditor` in both the "add note" panel and the inline edit mode in `NoteRowView`
- On save: if `titleField` is empty, store `note.title = note.createdAt.formatted(.dateTime.month(.abbreviated).day().year())`; otherwise store the user's input

**In `NoteRowView` display mode:**
- Show `Text(note.title).bold()` above the markdown content
- Remove `attributedContent: AttributedString` computed property
- Replace `Text(attributedContent)` with `Markdown(note.content).markdownTheme(.engagementTracker)`
- Add `import MarkdownUI` at top of file

## Out of Scope

- Live preview while typing
- Markdown toolbar/shortcuts in the editor
- Syntax highlighting in the TextEditor
- Export of rendered markdown
