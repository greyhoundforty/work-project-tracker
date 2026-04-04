# Charter App — Swift Scripts Overview

## What Each Script Does

### Models (11 files)

| File | Purpose |
|---|---|
| `Models/Enums.swift` | Defines `ProjectStage` (discovery → won/lost, with progression logic) and `ContactType` (external/internal, with legacy decoding) |
| `Models/Project.swift` | Core `@Model` class — stores project data (name, stage, value, links) and owns all child relationships (contacts, tasks, notes, etc.) |
| `Models/Engagement.swift` | Records a customer interaction — date, summary, and which contact IDs were involved |
| `Models/Checkpoint.swift` | A stage milestone with `toggle()` to mark complete/incomplete (records `completedAt`) |
| `Models/Contact.swift` | Stakeholder record — name, role, title, email, type |
| `Models/Note.swift` | Free-form markdown note attached to a project |
| `Models/ProjectTask.swift` | To-do item with `toggle()` and optional due date |
| `Models/ProjectCustomField.swift` | Template-driven custom key/value field on a project |
| `Models/ProjectLink.swift` | Named URL quick link on a project |
| `Models/ProjectTemplate.swift` | Defines template schemas (bundled + user) with checkpoint/field defaults; loads from bundle or user folder |
| `Models/CheckpointSeeder.swift` | Factory that maps each `ProjectStage` to a set of default checkpoint titles and creates them |

### Services (4 files)

| File | Purpose |
|---|---|
| `Services/ExportModels.swift` | Plain `Codable` structs (`ExportBundle`, `ExportedProject`, etc.) used as the serialization layer — not the SwiftData models |
| `Services/ExportService.swift` | Converts `Project` → `ExportedProject` structs, then encodes to JSON or CSV (5-file ZIP); handles RFC 4180 CSV escaping |
| `Services/ImportService.swift` | Parses JSON or CSV files into `ExportedProject` structs; validates names/stages; RFC 4180 CSV parser |
| `Services/UpdaterService.swift` | `@MainActor` singleton wrapping Sparkle to trigger in-app update checks |

### App & State (2 files)

| File | Purpose |
|---|---|
| `App/EngagementTrackerApp.swift` | `@main` entry point — sets up `WindowGroup`, `MenuBarExtra`, `Settings` scenes; builds `ModelContainer`; applies theme |
| `App/AppState.swift` | `@Observable` global state — active filters (stage/tag/label/search), theme mode, CloudKit toggle, template folder path, and `ModelContainer` factory |

### Theme (3 files)

| File | Purpose |
|---|---|
| `Theme/AppColors.swift` | Extends `Color` with semantic theme tokens (`themeBg`, `themeFg`, stage accent colors) |
| `Theme/GeneratedTheme.swift` | Material Design 3 light/dark palettes via SwiftThemeKit; `CustomThemeProvider` wrapper |
| `Theme/MarkdownTheme.swift` | Custom MarkdownUI theme for rendering note content (headings, code, blockquotes) |

### Main Views (4 files)

| File | Purpose |
|---|---|
| `Views/Main/ContentView.swift` | Root `NavigationSplitView` — composes sidebar, list, and detail panes |
| `Views/Main/StagesSidebarView.swift` | Left pane — All/stage sections, tags, tasks-with-items; bottom buttons for settings/import/share/backup |
| `Views/Main/ProjectListView.swift` | Middle pane — filtered project rows; "New Project" sheet trigger |
| `Views/Main/ProjectDetailView.swift` | Right pane — project header, stage/tag editing, 6-tab `TabView` |

### Tab Views (6 files)

| File | Purpose |
|---|---|
| `Views/Tabs/OverviewTabView.swift` | Project info card, quick links, custom fields, engagement calendar |
| `Views/Tabs/CheckpointsTabView.swift` | Stage-grouped milestones with completion progress |
| `Views/Tabs/TasksTabView.swift` | Pending/completed tasks with add-inline input |
| `Views/Tabs/ContactsTabView.swift` | Contacts grouped by type (External/Internal); initials avatar |
| `Views/Tabs/EngagementsTabView.swift` | Engagement log sorted by date; shows tagged contacts |
| `Views/Tabs/NotesTabView.swift` | Markdown notes with edit mode and MarkdownUI rendering |

### Sheet Views (3 files)

| File | Purpose |
|---|---|
| `Views/Sheets/NewProjectSheet.swift` | Create project — name, summary, tags, template picker; applies template defaults on save |
| `Views/Sheets/AddContactSheet.swift` | Add contact to current project |
| `Views/Sheets/LogEngagementSheet.swift` | Log engagement with date, summary, multi-select contacts |

### Export/Import Views (4 files)

| File | Purpose |
|---|---|
| `Views/Export/ExportSheet.swift` | Full export — scope (all/single), format (JSON/CSV-ZIP), NSSavePanel |
| `Views/Export/ImportSheet.swift` | Import JSON or CSV — preview results, skip-duplicates toggle, seeds missing checkpoints |
| `Views/Export/BackupSheet.swift` | One-click timestamped JSON backup of all active projects |
| `Views/Export/ShareSheet.swift` | Single-project selective share — choose which sections (tasks, notes, etc.) and format |

### Settings & Menu Bar (3 files)

| File | Purpose |
|---|---|
| `Views/Settings/SettingsView.swift` | App settings — theme, template folder, CloudKit sync, reset/danger zone |
| `Views/MenuBar/MenuBarPopoverView.swift` | Menu bar popover — search, pipeline summary, last-touched project |
| `Views/MenuBar/QuickCaptureView.swift` | Quick-create Engagement/Task/Note from menu bar, attached to a chosen project |

### Tests (13 files)

| File | Covers |
|---|---|
| `BundledTemplatesTests.swift` | Template loading, count, sorting |
| `CheckpointSeederTests.swift` | Checkpoint title generation per stage |
| `CheckpointTests.swift` | `Checkpoint` model init, `toggle()`, `completedAt` |
| `ContactTypeTests.swift` | Legacy `ContactType` decoding |
| `ProjectCustomFieldTests.swift` | Custom field models and decoding |
| `ProjectStageTests.swift` | Stage `.next`, terminal flag |
| `ProjectTaskTests.swift` | `ProjectTask` toggle, dueDate, `completedAt` |
| `ProjectTemplateDecodingTests.swift` | Full JSON decoding of template schemas |
| `QuickCaptureTests.swift` | `makeEngagement/Task/Note` free functions, `updatedAt` |
| `SearchFilterTests.swift` | Filter logic across all fields, currency formatting |
| `ExportModelsTests.swift` | Round-trip JSON encoding of export structs |
| `ExportServiceTests.swift` | JSON/CSV export output, CSV escaping |
| `ImportServiceTests.swift` | JSON/CSV parsing, validation, edge cases |

---

## Interaction Diagram

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                         EngagementTrackerApp (@main)                         │
│  builds ModelContainer ──► AppState ◄── all views read filters/theme/sync    │
└────────────┬─────────────────────────────────────────────────────────────────┘
             │ WindowGroup                             MenuBarExtra
             ▼                                              ▼
     ┌───────────────────┐                    ┌─────────────────────────┐
     │    ContentView    │                    │  MenuBarPopoverView      │
     │  (3-pane split)   │                    │  + QuickCaptureView      │
     └──┬────────┬───────┘                    │  creates Engagement/     │
        │        │                            │  Task/Note on Project    │
        ▼        ▼                            └────────────┬────────────┘
 ┌──────────┐ ┌──────────────────────────────────────────┐│
 │ Stages   │ │         ProjectListView                   ││
 │ Sidebar  │ │  filters via AppState (stage/tag/search)  ││
 │ View     │ │  row: name, badge, value, stage color     ││
 └────┬─────┘ └──────────────────────────────────────────┘│
      │                        │ select project            │
      │ triggers sheets:       ▼                           │
      │  ImportSheet    ┌─────────────────┐                │
      │  ExportSheet    │ProjectDetailView│ ◄──────────────┘
      │  BackupSheet    │ header + tabs   │
      │  NewProject     └────────┬────────┘
      │  Settings                │
      └──────────────────        │ TabView (6 tabs)
                        ┌────────┼──────────────────────────────────┐
                        ▼        ▼         ▼        ▼       ▼       ▼
                   Overview Checkpoints  Tasks  Contacts  Engage-  Notes
                   TabView   TabView    TabView  TabView   ments   TabView
                      │                   │        │      TabView    │
                      │            LogEngagement  Add    LogEngage   │
                      │            Sheet          Contact  Sheet     │
                      │                           Sheet              │
                      ▼                                              ▼
               ProjectLinks                                    MarkdownTheme
               CustomFields                                    (MarkdownUI)
               EngagementCalendar
                        │
                        │ reads from / writes to
                        ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                         SwiftData Models                                  │
│  Project ──owns──► Contact, Checkpoint, ProjectTask, Engagement,          │
│                    Note, ProjectCustomField, ProjectLink                   │
│  Enums: ProjectStage, ContactType                                         │
└──────────────────────────┬───────────────────────────────────────────────┘
                           │
            ┌──────────────┼──────────────────┐
            ▼              ▼                   ▼
     ExportService   ImportService       CheckpointSeeder
     (→ ExportModels) (← ExportModels)   (seeds defaults
           │                │              per stage)
           ▼                ▼                   ▲
     ExportSheet /    ImportSheet           NewProjectSheet
     BackupSheet /    (preview +            (on template apply)
     ShareSheet       insert to context)
           │
           ▼
    ProjectTemplate
    (bundled + user
     folder; loaded
     in NewProjectSheet
     + SettingsView)
```

### Key Data Flows

| Flow | Path |
|---|---|
| **Create project** | `NewProjectSheet` → loads `ProjectTemplate` → calls `CheckpointSeeder` → inserts `Project` into SwiftData |
| **Export** | Any export view → `ExportService` → `ExportModels` (Codable structs) → file on disk |
| **Import** | `ImportSheet` → `ImportService` (parses file → `ExportModels`) → inserts into `ModelContext` → seeds checkpoints |
| **Quick capture** | `QuickCaptureView` → writes `Engagement`/`ProjectTask`/`Note` directly onto selected `Project` |
| **Filtering** | `AppState` holds stage/tag/search state → `ProjectListView` applies multi-criteria filter over SwiftData query results |
| **Theme** | `AppState.themeMode` → `CustomThemeProvider` → `AppColors` tokens used throughout all views |
| **CloudKit sync** | `AppState.isCloudSyncEnabled` → `ModelContainer` configured with/without CloudKit automatic sync |
