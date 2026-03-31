# Markdown Notes Rendering Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the limited `AttributedString(markdown:)` display path in `NoteRowView` with `MarkdownUI`'s `Markdown` view, giving notes full GitHub Flavored Markdown rendering (headers, code fences, tables, lists, blockquotes).

**Architecture:** Add `MarkdownUI` as an SPM dependency via Xcode, define a custom `Theme` extension that maps the app's existing `Color.themeXxx` tokens to MarkdownUI's styling API, then swap the single display line in `NoteRowView` to use `Markdown(note.content).markdownTheme(.engagementTracker)`.

**Tech Stack:** Swift, SwiftUI, SwiftData, MarkdownUI 2.x (`https://github.com/gonzalezreal/swift-markdown-ui`)

---

## File Map

| Action | Path | Responsibility |
|---|---|---|
| Modify (manual, Xcode) | `EngagementTracker.xcodeproj` | Add MarkdownUI SPM dependency |
| Create | `EngagementTracker/Theme/MarkdownTheme.swift` | Custom `Theme` extension matching app palette |
| Modify | `EngagementTracker/Views/Tabs/NotesTabView.swift` | Swap `Text(attributedContent)` → `Markdown(...)` |

---

### Task 1: Add MarkdownUI via Xcode SPM

> This step is manual — Xcode manages SPM for `.xcodeproj` files via its GUI.

**Files:**
- Modify (via Xcode GUI): `EngagementTracker.xcodeproj`

- [ ] **Step 1: Open the project in Xcode**

```bash
open /Users/ryan/claude-projects/worktrees/feat-markdown-notes-section-40p/EngagementTracker.xcodeproj
```

- [ ] **Step 2: Add the package**

In Xcode: **File → Add Package Dependencies…**

Paste this URL into the search field:
```
https://github.com/gonzalezreal/swift-markdown-ui
```

Select version rule: **Up to Next Major Version**, starting from `2.0.2`.

Click **Add Package**, then check **MarkdownUI** in the product list and click **Add Package** again to link it to the `EngagementTracker` target.

- [ ] **Step 3: Verify the build still compiles**

In Xcode press **⌘B**. Expected: build succeeds with no errors. The package resolves and links; no source changes yet.

- [ ] **Step 4: Commit the updated project file**

```bash
cd /Users/ryan/claude-projects/worktrees/feat-markdown-notes-section-40p
git add EngagementTracker.xcodeproj
git commit -m "chore: add MarkdownUI SPM dependency"
```

---

### Task 2: Create custom MarkdownUI theme

**Files:**
- Create: `EngagementTracker/Theme/MarkdownTheme.swift`

- [ ] **Step 1: Create the theme file**

Create `EngagementTracker/Theme/MarkdownTheme.swift` with this content:

```swift
import SwiftUI
import MarkdownUI

extension Theme {
    static let engagementTracker = Theme()
        .text {
            ForegroundColor(.themeFg)
            FontSize(13)
        }
        .link {
            ForegroundColor(.themeBlue)
        }
        .strong {
            FontWeight(.semibold)
        }
        .emphasis {
            FontStyle(.italic)
        }
        .code {
            FontFamilyVariant(.monospaced)
            FontSize(.em(0.9))
            ForegroundColor(.themeAqua)
            BackgroundColor(.themeBg2)
        }
        .codeBlock { configuration in
            configuration.label
                .markdownTextStyle {
                    FontFamilyVariant(.monospaced)
                    FontSize(.em(0.9))
                    ForegroundColor(.themeAqua)
                }
                .padding(12)
                .background(Color.themeBg2)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .markdownMargin(top: 4, bottom: 4)
        }
        .blockquote { configuration in
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.themeYellow)
                    .frame(width: 3)
                configuration.label
                    .markdownTextStyle {
                        FontStyle(.italic)
                        ForegroundColor(.themeFgDim)
                    }
                    .padding(.leading, 10)
            }
            .markdownMargin(top: 4, bottom: 4)
        }
        .heading1 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontWeight(.bold)
                    FontSize(.em(1.6))
                    ForegroundColor(.themeFg)
                }
                .markdownMargin(top: 12, bottom: 4)
        }
        .heading2 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(1.3))
                    ForegroundColor(.themeFg)
                }
                .markdownMargin(top: 10, bottom: 4)
        }
        .heading3 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(1.1))
                    ForegroundColor(.themeFg)
                }
                .markdownMargin(top: 8, bottom: 4)
        }
        .listItem { configuration in
            configuration.label
                .markdownMargin(top: .em(0.15))
        }
        .paragraph { configuration in
            configuration.label
                .relativeLineSpacing(.em(0.2))
                .markdownMargin(top: 0, bottom: 4)
        }
}
```

- [ ] **Step 2: Build to verify the theme compiles**

In Xcode press **⌘B**. Expected: build succeeds. The theme extension compiles cleanly — no undefined color references, no MarkdownUI API mismatches.

- [ ] **Step 3: Commit**

```bash
git add EngagementTracker/Theme/MarkdownTheme.swift
git commit -m "feat: add engagementTracker MarkdownUI theme"
```

---

### Task 3: Swap display path in NoteRowView

**Files:**
- Modify: `EngagementTracker/Views/Tabs/NotesTabView.swift`

- [ ] **Step 1: Add import and update NoteRowView**

Open `EngagementTracker/Views/Tabs/NotesTabView.swift`.

At the top, add the import:
```swift
import MarkdownUI
```

In `NoteRowView`, **remove** the `attributedContent` computed property (lines 109–111):
```swift
// DELETE this:
private var attributedContent: AttributedString {
    (try? AttributedString(markdown: note.content)) ?? AttributedString(note.content)
}
```

In the `body`, find the display branch (the `else` block in the `if isEditing` check). **Replace**:
```swift
Text(attributedContent)
    .font(.system(size: 13))
    .foregroundStyle(Color.themeFg)
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(Rectangle())
    .onTapGesture {
        editedContent = note.content
        editingNoteID = note.id
    }
```

**With**:
```swift
Markdown(note.content)
    .markdownTheme(.engagementTracker)
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(Rectangle())
    .onTapGesture {
        editedContent = note.content
        editingNoteID = note.id
    }
```

- [ ] **Step 2: Build to verify no errors**

In Xcode press **⌘B**. Expected: build succeeds. No unused `attributedContent` references remain.

- [ ] **Step 3: Run the app and verify manually**

Press **⌘R** to run. In a test project, create a note with the following content and save it:

```markdown
# Heading one

## Heading two

Some **bold** and *italic* text.

- Item one
- Item two
- Item three

> A blockquote note

`inline code` and a block:

```swift
let x = 42
```

[A link](https://example.com)
```

Expected: The saved note displays with rendered headings, bold/italic, bullet list, styled blockquote with yellow left border, aqua-colored code, and a blue link. The TextEditor still shows raw markdown when you tap to edit.

- [ ] **Step 4: Commit**

```bash
git add EngagementTracker/Views/Tabs/NotesTabView.swift
git commit -m "feat: render notes with MarkdownUI, replacing AttributedString display"
```

---

## Done

After Task 3, the feature is complete. Open a PR against `main` referencing issue #7.
