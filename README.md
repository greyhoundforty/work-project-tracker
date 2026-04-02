# Charter

A macOS app for tracking client projects and engagements through their full lifecycle. Runs as a menu bar popover for quick capture and a full dock window for project management. Local-first via SwiftData with optional iCloud sync.

![Charter in action](work-tracker-demo.gif)

## What it does

**Project lifecycle tracking** — Projects move through a fixed pipeline: Discovery → Initial Delivery → Refine → Proposal → Won/Lost. Stage-specific checkpoints keep each phase on track.

**Contact management** — Track everyone involved: internal team members and external contacts. Contacts can include a free-form role, title, email, and notes (preferred contact method, office hours, etc.). Contacts are linked to engagement logs so you always know who was in the room.

**Engagement logs** — Timestamped notes on every interaction. Log a call, meeting, or email with a summary and the contacts who participated. The full history stays attached to the project.

**Tasks** — Lightweight per-project task list. Create tasks manually or let a template pre-populate them when the project is created.

**Notes** — Free-form markdown notes per project, rendered with syntax highlighting. Good for keeping context, open questions, and decisions in one place.

**Quick capture (menu bar)** — Click the briefcase icon in the menu bar to log an engagement, add a task, or drop a note without opening the main window. Defaults to your most recently active project; tap **change** to switch.

**Export and import** — Export projects to JSON or CSV for backup or sharing. Import JSON bundles or CSV files to restore or migrate data. A test dataset is included at `examples/test-projects.json`.

**Project templates** — Define JSON template files in a folder of your choosing. When creating a new project, templates pre-fill stage, tags, isPOC, and create an initial task list with custom fields. Three example templates are included in `examples/templates/`.

## Install

Download the latest `.dmg` from [Releases](https://github.com/greyhoundforty/work-project-tracker/releases), open it, and drag **Charter.app** to your Applications folder.

## Requirements (building from source)

- macOS 14.0+
- Xcode 16+
- [xcodegen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

## Building from source

```bash
git clone https://github.com/greyhoundforty/work-project-tracker.git
cd work-project-tracker
xcodegen generate
open Charter.xcodeproj
```

Press `⌘R` to build and run.

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
  ],
  "customFields": [
    { "label": "Contract Link", "placeholder": "Paste URL…" },
    { "label": "Budget", "placeholder": "e.g. $5,000" }
  ]
}
```

3. When creating a new project, the template picker appears at the top of the sheet. Selecting one pre-fills stage, tags, and isPOC, creates initial tasks, and adds any custom fields to the project overview.

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
