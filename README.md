# Engagement Tracker

A macOS app for tracking IBM sales engagements as projects. Runs as both a menu bar popover (quick access) and a full dock window (project management). Local-first storage via SwiftData with optional iCloud sync.

Projects move through a fixed lifecycle: Discovery -> Initial Delivery -> Refine -> Proposal -> Won/Lost. Each project tracks contacts (customer, IBM, business partner), stage checkpoints, tasks, timestamped engagement logs, and notes.

## Requirements

- macOS 14.0+
- Xcode 16+
- [xcodegen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`
- [mise](https://mise.jdx.dev) (optional, for terminal build tasks) — `brew install mise`

## Build

```bash
git clone https://github.com/greyhoundforty/engagement-tracker.git
cd engagement-tracker
xcodegen generate
open EngagementTracker.xcodeproj
```

Press `Cmd+R` to build and run.

## Terminal builds (mise)

```bash
mise run build        # Debug build
mise run clean        # Clean build products
mise run clean-build  # Clean then build
mise run test         # Run unit tests
```

## Project structure

```
project.yml                  # xcodegen project spec — source of truth for the Xcode project
EngagementTracker/
  App/                       # App entry point, AppState, ModelContainer setup
  Models/                    # SwiftData models and enums
  Services/                  # Export and import logic (Phase 2)
  Theme/                     # Gruvbox color extensions and asset catalog
  Views/
    Main/                    # NavigationSplitView, sidebar, project list, detail
    Tabs/                    # Per-tab views (Overview, Checkpoints, Tasks, etc.)
    Sheets/                  # New project, add contact, log engagement sheets
    Export/                  # Export and import sheets (Phase 2)
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

## Notes

- Swift is pinned to 5.9 in `project.yml` to avoid Swift 6 concurrency strictness with SwiftData. Do not bump without testing.
- The `ModelContainer` is a `@State` property on the app struct — one instance shared across all scenes. Do not make it a computed property.
- Changing the iCloud sync setting in Settings requires an app restart.
- See `docs/PHASE1_SESSION.md` for SwiftData migration rules before changing any model properties.
