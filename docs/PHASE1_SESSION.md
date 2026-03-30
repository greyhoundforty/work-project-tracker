# Phase 1 Session Notes

**Date:** 2026-03-30
**Goal:** Build the initial macOS EngagementTracker app from scratch — models, views, navigation, theming, and persistence.

---

## What Was Built

The full app skeleton was implemented in one session using subagent-driven development (12 tasks). The core stack is SwiftUI + SwiftData on macOS 14+, with xcodegen managing the Xcode project.

### Models

| Model | Key fields | Notes |
|---|---|---|
| `Project` | name, accountName, opportunityID, stage, isPOC, estimatedValueCents, targetCloseDate, tags, iscOpportunityLink, gtmNavAccountLink, oneDriveFolderLink | Root aggregate |
| `Contact` | name, title, email, type (external/IBM/partner), internalRole | IBM contacts have an optional InternalRole |
| `Checkpoint` | title, stage, sortOrder, isCompleted, completedAt | Seeded per-project at creation |
| `ProjectTask` | title, isCompleted, completedAt | Separate from checkpoints |
| `Engagement` | date, summary, contactIDs ([UUID]) | Contact refs are UUIDs, not SwiftData relationships — intentional |
| `Note` | content, createdAt | Plain timestamped text |

Money is stored as `Int` cents (`estimatedValueCents`) to avoid SwiftData serialization issues with `Decimal`. Link fields (`iscOpportunityLink` etc.) are `String` with default `""` — empty string means not set.

### Architecture

- **`EngagementTrackerApp`** — dual-scene app: `WindowGroup` (main window) + `MenuBarExtra` (.window style popover). A single `@State private var container` is shared across all scenes.
- **`AppState`** — `@Observable` singleton shared via `.environment()`. Holds `selectedStage`, `selectedTag`, `selectedProject`, `searchQuery`, and `isCloudSyncEnabled`. This is the coordination layer between the menu bar and the main window.
- **Navigation** — `NavigationSplitView` (3 columns): stages sidebar → project list → project detail.
- **Project detail** — `TabView` with 6 tabs: Overview, Checkpoints, Tasks, Contacts, Engagements, Notes.

### Theme

Gruvbox Dark Medium (`#282828` background) with the full palette implemented as `Color` extensions in `GruvboxColors.swift`. Each stage has an assigned color (`gruvStageColor(for:)`).

---

## What Didn't Work Initially (and the Fixes)

### 1. `ModelContainer` recreated on every render

**Symptom:** App launched but projects couldn't be interacted with. Changes didn't persist reliably. Menu bar and main window appeared to have separate data.

**Root cause:** `container` was a `var` computed property on `EngagementTrackerApp`:
```swift
// WRONG — creates a new ModelContainer instance on every body evaluation
var container: ModelContainer {
    AppState.makeContainer(cloudSync: appState.isCloudSyncEnabled)
}
```
Each call to `body` created a fresh `ModelContainer`. Because `body` is evaluated multiple times and called separately for `WindowGroup` and `MenuBarExtra`, the two scenes ended up with **different container instances** pointing at the same SQLite file — separate in-memory caches, no coordination.

**Fix:** Make it `@State` so it's created exactly once at app startup:
```swift
@State private var container = AppState.makeContainer(
    cloudSync: UserDefaults.standard.bool(forKey: "cloudSyncEnabled")
)
```

### 2. Stage sidebar buttons silently broken

**Symptom:** Clicking stage names in the left sidebar did nothing.

**Root cause:** `List(selection: $appState.selectedStage)` where `selectedStage: ProjectStage?`. SwiftUI's `List` treats a `nil` selection value as "nothing selected" — but we also used `nil` as a valid tag meaning "All Projects". The two meanings conflicted and the binding broke silently.

**Fix:** Replaced the entire sidebar with explicit `Button`-based rows that call `appState.selectedStage = stage` directly. Manual `isSelected` state drives the highlight via `.background`. No `List(selection:)` at all.

### 3. Project disappeared after advancing stage

**Symptom:** After clicking "Advance to Refine", the project vanished from view and the detail pane went blank.

**Root cause:** `selectedStage` stayed on the old stage (e.g., Discovery) after the project advanced. The project left the `filtered` array. SwiftUI's `List` automatically clears its selection binding when the selected item is no longer in the data source, so `selectedProject` was nil'd out.

**Fix (two parts):**
1. In `ProjectDetailHeaderView`, added `appState.selectedStage = next` alongside the stage advance — the sidebar filter follows the project.
2. Replaced `List(filtered, selection: $appState.selectedProject)` with explicit `.onTapGesture` rows. Selection is now fully owned by `AppState` and the list can't touch it when items change.

### 4. No auto-select after project creation

**Symptom:** After creating a project in the sheet and dismissing, the project appeared in the list but nothing was selected — user had to click it manually.

**Fix:** `NewProjectSheet.save()` now sets `appState.selectedStage = project.stage` and `appState.selectedProject = project` before dismissing.

### 5. Mutations not saving reliably

**Symptom:** Toggling checkboxes or completing tasks sometimes didn't persist across app launches.

**Root cause:** SwiftData's autosave runs on the run loop, not synchronously. Views that mutated model objects (checkpoint toggle, task toggle, stage advance) had no explicit `context.save()` call.

**Fix:** Added `try? context.save()` to every mutation handler: checkpoint toggle, task add/toggle/delete, note save/delete, contact delete, engagement delete, stage advance, project delete.

### 6. New Swift files invisible to Xcode after creation

**Symptom:** `Cannot find 'OverviewTabView' in scope` build error after adding a new `.swift` file.

**Root cause:** The Xcode project (`EngagementTracker.xcodeproj`) is generated by xcodegen from `project.yml`. The `.xcodeproj` is not auto-updated when files are added to disk — xcodegen must be re-run.

**Fix / ongoing workflow:**
```bash
cd /Users/ryan/claude-projects/work-project-tracker
xcodegen generate
```
Run this any time a new `.swift` file is added. It's safe to re-run; it doesn't touch your build settings.

---

## Design Decisions with Future Implications

### Engagement contacts stored as `[UUID]`, not a SwiftData relationship

`Engagement.contactIDs` is `[UUID]` rather than `@Relationship var contacts: [Contact]`. This was intentional: if a contact is deleted, the engagement history doesn't cascade-delete or leave dangling relationship pointers. The trade-off is that contact name resolution happens at render time by filtering `project.contacts` for matching IDs. If a contact is deleted, their name won't show on old engagements (shows nothing rather than crashing). Keep this in mind if you ever add an engagement export or reporting feature.

### iCloud sync requires app restart to take effect

`isCloudSyncEnabled` is read from `UserDefaults` once at app startup when `@State private var container` is initialized. Toggling the setting in Settings takes effect on next launch. The Settings view documents this. If you want live switching, `container` would need to become a published value that triggers scene reconstruction — complex, not worth it yet.

### Swift 5.9 pinned to avoid Swift 6 concurrency strictness

`SWIFT_VERSION = 5.9` is set in `project.yml`. `@Model` and `@Observable` objects are not `Sendable`, and Swift 6's strict concurrency checking produces errors in common SwiftData + SwiftUI patterns. Leave this as-is until Apple resolves the `@Observable`/`Sendable` story in a future SDK. Don't bump this without testing the full build first.

### SwiftData schema migration

SwiftData performs lightweight migration automatically for:
- Adding new optional properties (`String?`, `Int?`, etc.)
- Adding new `String` properties with a default value (`""`)

The three link fields added in this session (`iscOpportunityLink`, `gtmNavAccountLink`, `oneDriveFolderLink`) used this pattern. Existing database rows get `""` on first access.

**This will NOT automatically migrate:**
- Renaming a property
- Changing a property's type
- Removing a property and reusing the column name with a different type

For any of those, you need a `SchemaMigrationPlan` with explicit migration stages. Avoid renaming model properties without planning the migration first.

### `AppState.selectedTag` and `selectedStage` are mutually exclusive

The sidebar enforces this: clicking a stage clears `selectedTag`, and clicking a tag clears `selectedStage`. `ProjectListView.filtered` checks `selectedTag` first, then `selectedStage`. If you add new filter types (e.g., filter by IBM seller), extend `AppState` with a new optional and add it to the priority chain in `filtered`.

---

## Known Gaps / Not Yet Built

- **Edit project** — no way to change a project's name, account, opportunity ID, tags, or estimated value after creation. The Overview tab shows these fields read-only (except links). A future edit sheet or inline editing on the Overview tab would address this.
- **Archive / soft-delete** — projects have `isActive: Bool` but no UI to archive them. Advancing to Won/Lost marks the stage but doesn't flip `isActive`.
- **Search from main window** — search is wired through `appState.searchQuery` and works from the menu bar popover, but there's no search field in the main window toolbar yet.
- **Engagement quick-log from menu bar** — the "Log Engagement" button in the menu bar popover always logs against the most-recently-updated project. It should let the user pick which project.
- **iOS companion** — the SwiftData schema was designed with iCloud sync in mind (`ModelConfiguration(.cloudKitDatabase:)`). The iCloud container is not yet configured in App Store Connect. Before building the iOS app, the CloudKit container needs to be provisioned and tested.

---

## Tooling

| Tool | Usage |
|---|---|
| `xcodegen generate` | Regenerate `.xcodeproj` after adding/removing files or changing `project.yml` |
| `mise run build` | xcodebuild Debug build via terminal |
| `mise run clean` | Clean build products |
| `mise run clean-build` | Clean + build in one step |
| `mise run test` | Run unit test suite |

Tests live in `EngagementTrackerTests/` and use Swift Testing (`@Suite`, `@Test`, `#expect`). 16 tests covering `CheckpointSeeder`, `ProjectStage` transitions, and `SearchFilter` logic.
