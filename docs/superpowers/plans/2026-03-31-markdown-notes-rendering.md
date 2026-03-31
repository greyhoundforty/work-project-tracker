# Markdown Notes Rendering Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace limited `AttributedString(markdown:)` display with `MarkdownUI` for full GFM rendering, and add a bold title field to notes (defaulting to the creation date if left blank).

**Architecture:** `MarkdownUI` is already added as an SPM dependency (Task 1 complete). A custom `Theme` extension maps app color tokens to MarkdownUI styling. The `Note` model gains a `title: String` field (SwiftData lightweight migration via default value). `NotesTabView` and `NoteRowView` are updated to show a title input and bold title display.

**Tech Stack:** Swift, SwiftUI, SwiftData, MarkdownUI 2.x

---

## File Map

| Action | Path | Responsibility |
|---|---|---|
| ✅ Done | `EngagementTracker.xcodeproj` | MarkdownUI SPM dependency added |
| Modify | `EngagementTracker/Models/Note.swift` | Add `title: String` field |
| Create | `EngagementTracker/Theme/MarkdownTheme.swift` | Custom Theme matching app palette |
| Modify | `EngagementTracker/Views/Tabs/NotesTabView.swift` | Title input + MarkdownUI display |

---

### Task 1: Add MarkdownUI SPM dependency ✅ COMPLETE

Already done manually via Xcode. `MarkdownUI` is linked to the `EngagementTracker` target.

---

### Task 2: Add title field to Note model

**Files:**
- Modify: `EngagementTracker/Models/Note.swift`

- [ ] **Step 1: Add `title` property to Note**

Open `EngagementTracker/Models/Note.swift`. The full updated file:

```swift
import Foundation
import SwiftData

@Model
final class Note {
    var id: UUID
    var title: String
    var content: String
    var createdAt: Date

    var project: Project?

    init(title: String = "", content: String) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.createdAt = Date()
    }
}
```

The default value `""` on `title` tells SwiftData to use an empty string for existing records — no migration schema required.

- [ ] **Step 2: Build to verify no errors**

In Xcode press **⌘B**. Expected: build succeeds. SwiftData compiles the updated model.

- [ ] **Step 3: Commit**

```bash
git add EngagementTracker/Models/Note.swift
git commit -m "feat: add title field to Note model"
```

---

### Task 3: Create custom MarkdownUI theme

**Files:**
- Create: `EngagementTracker/Theme/MarkdownTheme.swift`

- [ ] **Step 1: Create the theme file**

Create `EngagementTracker/Theme/MarkdownTheme.swift`:

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

- [ ] **Step 2: Build to verify**

In Xcode press **⌘B**. Expected: build succeeds with no errors.

- [ ] **Step 3: Commit**

```bash
git add EngagementTracker/Theme/MarkdownTheme.swift
git commit -m "feat: add engagementTracker MarkdownUI theme"
```

---

### Task 4: Update NotesTabView and NoteRowView

**Files:**
- Modify: `EngagementTracker/Views/Tabs/NotesTabView.swift`

This task updates both the add/edit UI (title input) and the display (bold title + MarkdownUI content).

**Helper used in both save paths:**
```swift
private func defaultTitle(for date: Date) -> String {
    date.formatted(.dateTime.month(.abbreviated).day().year())
}
```

- [ ] **Step 1: Update NotesTabView**

In `NotesTabView`, add a `@State private var newNoteTitle: String = ""` alongside the existing `newNoteContent` state.

Update the `isAddingNote` panel to include a title field above the TextEditor:

```swift
if isAddingNote {
    VStack(alignment: .leading, spacing: 8) {
        TextField("Title (optional)", text: $newNoteTitle)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.themeFg)
            .padding(6)
            .background(Color.themeBg2)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        TextEditor(text: $newNoteContent)
            .font(.system(size: 13))
            .foregroundStyle(Color.themeFg)
            .frame(height: 100)
            .padding(4)
            .background(Color.themeBg2)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        HStack {
            Button("Cancel") {
                newNoteTitle = ""
                newNoteContent = ""
                isAddingNote = false
            }
            Spacer()
            Button("Save Note") {
                saveNote()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.themeAqua)
            .disabled(newNoteContent.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
    .padding()
    .background(Color.themeBg1)
    Divider()
}
```

Update `saveNote()`:

```swift
private func saveNote() {
    let content = newNoteContent.trimmingCharacters(in: .whitespaces)
    guard !content.isEmpty else { return }
    let titleInput = newNoteTitle.trimmingCharacters(in: .whitespaces)
    let note = Note(
        title: titleInput.isEmpty ? defaultTitle(for: Date()) : titleInput,
        content: content
    )
    context.insert(note)
    project.notes.append(note)
    project.updatedAt = Date()
    try? context.save()
    newNoteTitle = ""
    newNoteContent = ""
    isAddingNote = false
}

private func defaultTitle(for date: Date) -> String {
    date.formatted(.dateTime.month(.abbreviated).day().year())
}
```

- [ ] **Step 2: Update NoteRowView**

Replace the entire `NoteRowView` struct. Key changes:
- Add `@State private var editedTitle: String = ""`
- Add title `TextField` in edit mode
- Show `Text(note.title).bold()` above markdown content in display mode
- Replace `Text(attributedContent)` with `Markdown(note.content).markdownTheme(.engagementTracker)`
- Remove `attributedContent` computed property
- Update the edit save action to handle empty title → date fallback
- Add `import MarkdownUI` at top of file

Full updated `NoteRowView`:

```swift
import MarkdownUI

struct NoteRowView: View {
    @Environment(\.modelContext) private var context
    let note: Note
    let onDelete: () -> Void
    @Binding var editingNoteID: UUID?
    @State private var editedTitle: String = ""
    @State private var editedContent: String = ""

    private var isEditing: Bool { editingNoteID == note.id }

    private func defaultTitle(for date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day().year())
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(note.createdAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                .font(.system(size: 10))
                .foregroundStyle(Color.themeFgDim)
                .frame(width: 90, alignment: .leading)
                .padding(.top, 2)

            if isEditing {
                VStack(alignment: .leading, spacing: 6) {
                    TextField("Title (optional)", text: $editedTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.themeFg)
                        .padding(6)
                        .background(Color.themeBg)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.themeAqua, lineWidth: 1.5)
                        )
                    TextEditor(text: $editedContent)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.themeFg)
                        .frame(minHeight: 80)
                        .padding(4)
                        .background(Color.themeBg)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.themeAqua, lineWidth: 1.5)
                        )
                    HStack {
                        Button("Cancel") {
                            editedTitle = note.title
                            editedContent = note.content
                            editingNoteID = nil
                        }
                        Spacer()
                        Button("Save") {
                            let titleInput = editedTitle.trimmingCharacters(in: .whitespaces)
                            note.title = titleInput.isEmpty ? defaultTitle(for: note.createdAt) : titleInput
                            note.content = editedContent
                            note.project?.updatedAt = Date()
                            try? context.save()
                            editingNoteID = nil
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.themeAqua)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.themeFg)
                    Markdown(note.content)
                        .markdownTheme(.engagementTracker)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    editedTitle = note.title
                    editedContent = note.content
                    editingNoteID = note.id
                }
            }

            if !isEditing {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(Color.themeRed)
                }
                .buttonStyle(.plain)
                .opacity(0.6)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}
```

- [ ] **Step 3: Build to verify**

In Xcode press **⌘B**. Expected: build succeeds with no errors or warnings about missing `title` on `Note`.

- [ ] **Step 4: Run the app and verify manually**

Press **⌘R**. Open a project, go to the Notes tab.

**Test A — title provided:**
Click "Add Note", enter title `"Meeting notes"` and content:
```
## Action items

- Follow up with **Sarah** on pricing
- Schedule *technical* demo

> Don't forget to send the recap email
```
Click Save. Expected: note shows bold title "Meeting notes", content renders with heading, list, bold/italic, and styled blockquote.

**Test B — no title:**
Click "Add Note", leave title blank, enter any content, click Save. Expected: note title shows the current date (e.g., `"Mar 31, 2026"`) in bold.

**Test C — existing notes (migration):**
Any notes created before this change should display with a date-based title (their `title` field is `""` — but wait, empty string won't auto-populate to date at display time since we only set it at save time).

> **Note for implementer:** Existing notes will have `title = ""`. In the display, show the creation date as fallback when `note.title.isEmpty`:
> ```swift
> Text(note.title.isEmpty ? defaultTitle(for: note.createdAt) : note.title)
>     .font(.system(size: 13, weight: .bold))
>     .foregroundStyle(Color.themeFg)
> ```

- [ ] **Step 5: Commit**

```bash
git add EngagementTracker/Views/Tabs/NotesTabView.swift
git commit -m "feat: add title field to notes UI, render content with MarkdownUI"
```

---

## Done

After Task 4, the feature is complete. Open a PR against `main` referencing issue #7.
