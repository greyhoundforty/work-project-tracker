# Design: Add 'Done' Button to Import Feature

**Issue:** greyhoundforty/charter-app#12  
**Date:** 2026-04-02

## Summary

After a successful import in `ImportSheet`, the user sees a success message but no contextually appropriate way to dismiss the sheet. The only dismiss option is the "Cancel" button in the header, which is semantically wrong post-import. This design adds a "Done" button below the success message.

## Change

**File:** `Charter/Views/Export/ImportSheet.swift`

Extend the existing `showDone` block (lines 100–103) to render a full-width "Done" button beneath the success text:

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

## Rationale

- `showDone`, `successCount`, and `dismiss` are all already in scope — no new state or logic required.
- Button style matches the existing Import button for visual consistency.
- The "Cancel" header button remains as a fallback dismiss path at all stages.

## Out of Scope

- Renaming "Cancel" to "Done" in the header.
- Any changes to `ImportService` or import logic.
