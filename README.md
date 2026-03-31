# Engagement Tracker

A macOS app for tracking IBM sales engagements as projects. Runs as both a menu bar popover (quick access) and a full dock window (project management). Local-first storage via SwiftData with optional iCloud sync.

Projects move through a fixed lifecycle: Discovery → Initial Delivery → Refine → Proposal → Won/Lost. Each project tracks contacts (customer, IBM, business partner), stage checkpoints, tasks, timestamped engagement logs, and notes.

## Requirements

- macOS 14.0+
- Xcode 16+
- [xcodegen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`
- [mise](https://mise.jdx.dev) (optional, for terminal build tasks) — `brew install mise`

## Build and Run

### Xcode (recommended)

```bash
git clone https://github.com/greyhoundforty/engagement-tracker.git
cd engagement-tracker
xcodegen generate
open EngagementTracker.xcodeproj
```

Press `Cmd+R` to build and run.

### Terminal — with mise

```bash
mise run build        # Debug build
mise run test         # Run unit tests
mise run clean        # Clean build products
mise run clean-build  # Clean then build
mise run db-backup    # Backup SwiftData store to ~/Desktop/EngagementTracker-backups/
```

To build and launch in one step:

```bash
mise run build && open ~/Library/Developer/Xcode/DerivedData/EngagementTracker-*/Build/Products/Debug/EngagementTracker.app
```

### Terminal — without mise (xcodebuild directly)

```bash
# Debug build
xcodebuild \
  -project EngagementTracker.xcodeproj \
  -scheme EngagementTracker \
  -destination 'platform=macOS,arch=arm64' \
  -configuration Debug \
  build

# Run unit tests
xcodebuild \
  -project EngagementTracker.xcodeproj \
  -scheme EngagementTrackerTests \
  -destination 'platform=macOS,arch=arm64' \
  test

# Build and launch
xcodebuild \
  -project EngagementTracker.xcodeproj \
  -scheme EngagementTracker \
  -destination 'platform=macOS,arch=arm64' \
  -configuration Debug \
  build && \
open ~/Library/Developer/Xcode/DerivedData/EngagementTracker-*/Build/Products/Debug/EngagementTracker.app
```

> **Note:** Builds from the terminal use ad-hoc codesigning. The app sandbox entitlement ensures they share the same SwiftData store as Xcode-run builds (`~/Library/Containers/com.greyhoundforty.EngagementTracker/`).

## Project structure

```
project.yml                  # xcodegen project spec — source of truth for the Xcode project
EngagementTracker/
  App/                       # App entry point, AppState, ModelContainer setup
  Models/                    # SwiftData models, enums, and ProjectTemplate
  Services/                  # Export and import logic
  Theme/                     # Gruvbox color extensions and asset catalog
  Views/
    Main/                    # NavigationSplitView, sidebar, project list, detail
    Tabs/                    # Per-tab views (Overview, Checkpoints, Tasks, etc.)
    Sheets/                  # New project, add contact, log engagement sheets
    Export/                  # Export and import sheets
    MenuBar/                 # Menu bar popover
    Settings/                # Settings window
EngagementTrackerTests/      # Swift Testing unit tests
docs/
  PHASE1_SESSION.md          # What was built, bugs fixed, design decisions
  PHASE2_PLAN.md             # Planned features: export/import, light theme, settings
```

## Adding new files

The `.xcodeproj` is generated from `project.yml` by xcodegen. After adding or removing any `.swift` files, regenerate it:

```bash
xcodegen generate
```

> **Note:** If you add files manually without xcodegen (e.g. during a worktree session), add the file references directly to `project.pbxproj` — see any existing model file as a template for the three required entries (PBXBuildFile, PBXFileReference, PBXGroup, PBXSourcesBuildPhase).

## Quick capture (menu bar)

Click the briefcase icon in the menu bar to open the popover. When no search query is active, the top of the popover is a quick-capture panel for adding records without opening the main window.

**Capture types** (segmented control):
- **Engagement** — summary text + date (defaults to today)
- **Task** — title + optional due date
- **Note** — optional title + content

The panel defaults to the most recently updated active project. Tap **change** to pick a different project from a dropdown. The Save button is enabled only when the required field for the selected type is non-empty.

After saving, the fields reset and the panel stays open for follow-up captures. The project selection and capture type are retained across saves.

Full project creation (New Project) is still available via the **+** button in the popover footer.

## Importing test data

A test project file is included at `docs/test-projects.json`. Import it via the **↓ toolbar button** in the project list to populate the app with sample data across all pipeline stages.

The import sheet accepts:
- **JSON** — full `ExportBundle` with projects, contacts, engagements, notes, tasks, and checkpoints
- **CSV** — `projects.csv` from a zip export (project metadata only; child records not included)

## Project templates

To use templates when creating new projects:

1. Open **Settings → Templates** and choose a folder containing `.json` template files.
2. Each template file defines default values for a new project:

```json
{
  "name": "POC Engagement",
  "isPOC": true,
  "tags": ["poc"],
  "stage": "Discovery",
  "taskTitles": ["Define POC scope", "Environment setup", "Build POC", "Present results"]
}
```

3. When creating a new project the template picker appears at the top of the sheet. Selecting a template pre-fills stage, tags, isPOC, and creates initial tasks on save.

## Notes

- Swift is pinned to 5.9 in `project.yml` to avoid Swift 6 concurrency strictness with SwiftData. Do not bump without testing.
- The `ModelContainer` is a `@State` property on the app struct — one instance shared across all scenes. Do not make it a computed property.
- Changing the iCloud sync setting in Settings requires an app restart.
- The three link fields (`iscOpportunityLink`, `gtmNavAccountLink`, `oneDriveFolderLink`) are `String?` — existing records with NULL values migrate cleanly. Do not change them back to non-optional without a versioned migration plan.
- See `docs/PHASE1_SESSION.md` for SwiftData migration rules before changing any model properties.
