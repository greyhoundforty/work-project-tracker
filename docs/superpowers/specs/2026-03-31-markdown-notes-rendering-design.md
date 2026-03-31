# Markdown Notes Rendering — Design Spec

**Date:** 2026-03-31
**Issue:** greyhoundforty/work-project-tracker#7
**Branch:** emdash/feat-markdown-notes-section-40p

## Problem

Notes are stored as raw markdown strings. The display path uses `AttributedString(markdown:)` which only renders bold, italic, inline code, and links — it does not render headers, code fences, tables, bullet/numbered lists, or blockquotes. Users writing structured notes with these elements see raw markup instead of formatted output.

## Chosen Approach

Replace the `Text(attributedContent)` display path in `NoteRowView` with `MarkdownUI`'s `Markdown` view, styled with a custom theme that matches the app's existing color tokens.

## Dependency

- **Package:** `https://github.com/gonzalezreal/swift-markdown-ui`
- **Version:** `2.0.2` or later
- **Added via:** Xcode SPM package manager (no `Package.swift` — this is an Xcode project)

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

**In `NoteRowView`:**

- Remove `attributedContent: AttributedString` computed property
- Replace `Text(attributedContent)` with `Markdown(note.content).markdownTheme(.engagementTracker)`
- Edit path (`TextEditor`) is unchanged
- Add `import MarkdownUI` at top of file

No changes to `NotesTabView` (add/save flow), `Note` model, or any other files.

## Out of Scope

- Live preview while typing
- Markdown toolbar/shortcuts in the editor
- Syntax highlighting in the TextEditor
- Export of rendered markdown
