# Done Button Import Feature Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a "Done" button below the success message in `ImportSheet` so users have a clear, semantically correct way to dismiss the sheet after a successful import.

**Architecture:** The `showDone` state variable already exists and is set to `true` after import completes. We extend the existing `showDone` branch in `ImportSheet.swift` to render a full-width "Done" button beneath the success text. No new state, services, or models are required.

**Tech Stack:** Swift, SwiftUI, SwiftData, XCTest

---

### Task 1: Add "Done" button to ImportSheet

**Files:**
- Modify: `Charter/Views/Export/ImportSheet.swift:100-103`
- Test: `CharterTests/ImportServiceTests.swift`

- [ ] **Step 1: Open `CharterTests/ImportServiceTests.swift` and confirm there is no existing UI test for the Done button (there won't be — this is a SwiftUI view with no snapshot tests). We'll add a logic-level check instead.**

Run:
```bash
grep -n "showDone\|Done\|dismiss" CharterTests/ImportServiceTests.swift
```
Expected: no matches (the file only tests `ImportService` parsing logic).

- [ ] **Step 2: Verify the current `showDone` block in `ImportSheet.swift`**

Open `Charter/Views/Export/ImportSheet.swift` lines 100–113. Confirm the block looks like:

```swift
if showDone {
    Text("✓ Imported \(successCount) project(s) successfully.")
        .foregroundStyle(Color.themeGreen)
}

if !successes.isEmpty && !showDone {
    Button(action: performImport) {
        Label("Import \(successes.count) Project(s)", systemImage: "square.and.arrow.down")
            .frame(maxWidth: .infinity)
    }
    .buttonStyle(.borderedProminent)
    .tint(Color.themeAqua)
    .disabled(isImporting)
}
```

- [ ] **Step 3: Add the "Done" button inside the `showDone` block**

Edit `Charter/Views/Export/ImportSheet.swift`. Replace lines 100–103:

```swift
if showDone {
    Text("✓ Imported \(successCount) project(s) successfully.")
        .foregroundStyle(Color.themeGreen)
}
```

With:

```swift
if showDone {
    Text("✓ Imported \(successCount) project(s) successfully.")
        .foregroundStyle(Color.themeGreen)
    Button("Done") { dismiss() }
        .buttonStyle(.borderedProminent)
        .tint(Color.themeAqua)
        .frame(maxWidth: .infinity)
}
```

- [ ] **Step 4: Build the project to verify no compile errors**

In Xcode: Product → Build (⌘B), or from the command line:

```bash
xcodebuild -scheme Charter -destination 'platform=macOS' build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Manual smoke test**

1. Run the app (⌘R in Xcode).
2. Open the Import sheet (File menu or toolbar).
3. Choose a valid `.json` export file.
4. Click "Import N Project(s)".
5. Verify the success message appears: `✓ Imported N project(s) successfully.`
6. Verify a full-width aqua "Done" button appears below the message.
7. Click "Done" — confirm the sheet dismisses.

- [ ] **Step 6: Run existing tests to confirm nothing is broken**

```bash
xcodebuild test -scheme Charter -destination 'platform=macOS' 2>&1 | tail -30
```

Expected: all tests pass, no regressions.

- [ ] **Step 7: Commit**

```bash
git add Charter/Views/Export/ImportSheet.swift
git commit -m "feat: add Done button to ImportSheet after successful import (#12)"
```
