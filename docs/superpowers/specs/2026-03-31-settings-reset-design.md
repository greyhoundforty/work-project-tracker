# Settings Reset Button Design

**Date:** 2026-03-31

## Summary

Add two destructive reset buttons to `SettingsView` in a "Danger Zone" section: one that wipes all project data, and one that wipes data plus all app settings. Intended for testing the full export → reset → import lifecycle.

## UI

New `Section` at the bottom of `SettingsView` with header "Danger Zone". Contains two buttons:

- **Reset Data** — red/destructive styling. Triggers a confirmation alert before executing.
- **Reset All** — red/destructive styling. Triggers a separate confirmation alert before executing.

Both buttons are disabled while a reset is in progress (guarded by a `@State var isResetting: Bool`).

### Confirmation Alerts

**Reset Data alert:**
- Title: "Reset All Data?"
- Message: "This will permanently delete all projects and their associated data. This cannot be undone."
- Actions: Cancel (default) / "Delete All Data" (destructive)

**Reset All alert:**
- Title: "Reset Everything?"
- Message: "This will permanently delete all projects and reset all settings to defaults. This cannot be undone."
- Actions: Cancel (default) / "Reset Everything" (destructive)

## Data Deletion

`SettingsView` acquires `@Environment(\.modelContext) private var modelContext`.

Fetch and delete all records for each SwiftData model type in this order (children before parents to avoid dangling references):
1. `Checkpoint`
2. `ProjectTask`
3. `Engagement`
4. `Note`
5. `Contact`
6. `Project`

Each type: `try modelContext.fetch(FetchDescriptor<T>())` → iterate → `modelContext.delete(record)` → `try modelContext.save()`.

## Settings Reset (Reset All only)

After data deletion, clear these `AppState` properties (which propagate to `UserDefaults` via `didSet`):
- `appState.templateFolderPath = nil`
- `appState.templateFolderBookmark = nil`
- `appState.themeMode = .system`
- `appState.isCloudSyncEnabled = false`

## Files Modified

- `EngagementTracker/Views/Settings/SettingsView.swift` — add Danger Zone section, alerts, deletion logic

No new files required.
