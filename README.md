# Engagement Tracker

A macOS app for tracking client projects and sales engagements through their full lifecycle. Runs as a menu bar popover for quick capture and a full dock window for project management. Local-first via SwiftData with optional iCloud sync.

![Engagement Tracker in action](work-tracker-demo.gif)

## What it does

**Project lifecycle tracking** — Projects move through a fixed pipeline: Discovery → Initial Delivery → Refine → Proposal → Won/Lost. Stage-specific checkpoints keep each phase on track and auto-advance as milestones are completed.

**Contact management** — Track everyone involved: customers, internal team members, and business partners. Contacts are linked to engagement logs so you always know who was in the room.

**Engagement logs** — Timestamped notes on every interaction. Log a call, meeting, or email with a summary and the contacts who participated. The full history stays attached to the project.

**Tasks** — Lightweight per-project task list. Create tasks manually or let a template pre-populate them when the project is created.

**Notes** — Free-form markdown notes per project, rendered with syntax highlighting. Good for keeping context, open questions, and decisions in one place.

**Quick capture (menu bar)** — Click the briefcase icon in the menu bar to log an engagement, add a task, or drop a note without opening the main window. Defaults to your most recently active project; tap **change** to switch.

**Export and import** — Export projects to JSON or CSV for backup or sharing. Import JSON bundles or CSV files to restore or migrate data. A test dataset is included at `examples/test-projects.json`.

**Project templates** — Define JSON template files in a folder of your choosing. When creating a new project, templates pre-fill stage, tags, isPOC, and create an initial task list. Three example templates are included in `examples/templates/`.

## Requirements

- macOS 14.0+
- Xcode 16+
- [xcodegen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`
- [mise](https://mise.jdx.dev) (optional, for terminal build tasks) — `brew install mise`

## Getting started

```bash
git clone https://github.com/greyhoundforty/work-project-tracker.git
cd work-project-tracker
xcodegen generate
open EngagementTracker.xcodeproj
```

Press `⌘R` to build and run.

### Terminal builds (mise)

```bash
mise run build        # Debug build
mise run test         # Run unit tests
mise run clean        # Clean build products
mise run db-backup    # Backup SwiftData store to ~/Desktop/EngagementTracker-backups/
```

## Using templates

1. Open **Settings → Templates** and choose a folder containing `.json` template files.
2. Each template defines defaults for a new project:

```json
{
  "name": "Freelance Client Project",
  "isPOC": false,
  "stage": "Discovery",
  "tags": ["freelance", "client"],
  "taskTitles": [
    "Send project proposal",
    "Get contract signed",
    "Schedule kickoff call",
    "Deliver first milestone",
    "Send invoice",
    "Get client sign-off"
  ]
}
```

3. When creating a new project, the template picker appears at the top of the sheet. Selecting one pre-fills stage, tags, and isPOC, and creates initial tasks on save.

Three example templates are in `examples/templates/` — copy them to any folder and point Settings at it to get started.

## Adding new files

The `.xcodeproj` is generated from `project.yml` by xcodegen. After adding or removing `.swift` files, regenerate it:

```bash
xcodegen generate
```

## Notes

- Changing the iCloud sync setting requires an app restart.
- Swift is pinned to 5.9 in `project.yml` to avoid Swift 6 concurrency strictness with SwiftData. Do not bump without testing.
- The `ModelContainer` is a `@State` property on the app struct — one instance shared across all scenes. Do not make it a computed property.
