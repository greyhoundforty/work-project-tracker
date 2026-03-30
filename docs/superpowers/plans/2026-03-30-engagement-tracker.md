# Engagement Tracker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a macOS 14+ menu bar + dock app for tracking sales engagement projects through a Discovery → Initial Delivery → Refine → Proposal → Won/Lost lifecycle with contacts, tasks, notes, and engagement logging.

**Architecture:** SwiftUI + SwiftData on macOS 14+. App runs in dual mode — a `MenuBarExtra` popover for quick access and a standard `WindowGroup` for full project management. All views share a single `ModelContainer`. iCloud sync is opt-in via `ModelConfiguration`.

**Tech Stack:** Swift 5.9+, SwiftUI, SwiftData, Swift Testing (Xcode 16), xcodegen for project generation, macOS 14.0 minimum deployment target.

---

## File Map

```
project.yml                                    // xcodegen project spec
EngagementTracker/
  App/
    EngagementTrackerApp.swift                 // @main, MenuBarExtra + WindowGroup, ModelContainer setup
    AppState.swift                             // @Observable shared state (selected project, search query)
  Models/
    Enums.swift                                // ProjectStage, ContactType, InternalRole
    Project.swift                              // @Model Project
    Contact.swift                              // @Model Contact
    Checkpoint.swift                           // @Model Checkpoint
    ProjectTask.swift                          // @Model ProjectTask
    Engagement.swift                           // @Model Engagement
    Note.swift                                 // @Model Note
    CheckpointSeeder.swift                     // Pure function: stage → [String] default titles
  Theme/
    GruvboxColors.swift                        // ShapeStyle extensions for Gruvbox light+dark
  Views/
    Main/
      ContentView.swift                        // NavigationSplitView root (3 columns)
      StagesSidebarView.swift                  // Column 1: stage list with count badges
      ProjectListView.swift                    // Column 2: projects for selected stage
      ProjectDetailView.swift                  // Column 3: header + TabView
    Tabs/
      CheckpointsTabView.swift                 // Grouped checkpoints by stage, toggle completion
      TasksTabView.swift                       // Todo-style task list with add/complete/delete
      ContactsTabView.swift                    // External/Internal/Partner contact groups
      EngagementsTabView.swift                 // Chronological engagement log
      NotesTabView.swift                       // Timestamped note entries
    MenuBar/
      MenuBarPopoverView.swift                 // Search + pipeline summary + quick actions
    Sheets/
      NewProjectSheet.swift                    // Create project with all optional fields
      LogEngagementSheet.swift                 // Quick engagement log with contact multi-select
      AddContactSheet.swift                    // Add contact to project
    Settings/
      SettingsView.swift                       // iCloud sync toggle
EngagementTrackerTests/
  CheckpointSeederTests.swift                  // Tests for default checkpoint seeding
  ProjectStageTests.swift                      // Tests for stage progression helpers
  SearchFilterTests.swift                      // Tests for project search/filter logic
```

---

## Task 1: Project scaffold with xcodegen

**Files:**
- Create: `project.yml`
- Create: `EngagementTracker/App/EngagementTrackerApp.swift` (stub)

- [ ] **Step 1: Install xcodegen if not present**

```bash
which xcodegen || brew install xcodegen
```

Expected: prints a path or installs successfully.

- [ ] **Step 2: Write project.yml**

```yaml
name: EngagementTracker
options:
  bundleIdPrefix: com.greyhoundforty
  deploymentTarget:
    macOS: "14.0"
  xcodeVersion: "16.0"
  createIntermediateGroups: true
  groupSortPosition: top

settings:
  base:
    SWIFT_VERSION: "5.9"
    ENABLE_HARDENED_RUNTIME: YES
    PRODUCT_BUNDLE_IDENTIFIER: com.greyhoundforty.EngagementTracker

targets:
  EngagementTracker:
    type: application
    platform: macOS
    sources:
      - EngagementTracker
    settings:
      base:
        PRODUCT_NAME: EngagementTracker
        INFOPLIST_FILE: EngagementTracker/Info.plist
        CODE_SIGN_STYLE: Automatic
    entitlements:
      path: EngagementTracker/EngagementTracker.entitlements
      properties:
        com.apple.security.app-sandbox: true
        com.apple.security.network.client: true
        com.apple.security.files.user-selected.read-write: true
    dependencies:
      - sdk: SwiftData.framework

  EngagementTrackerTests:
    type: bundle.unit-test
    platform: macOS
    sources:
      - EngagementTrackerTests
    dependencies:
      - target: EngagementTracker
    settings:
      base:
        PRODUCT_NAME: EngagementTrackerTests
```

- [ ] **Step 3: Create Info.plist**

Create `EngagementTracker/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>EngagementTracker</string>
    <key>CFBundleDisplayName</key>
    <string>Engagement Tracker</string>
    <key>CFBundleIdentifier</key>
    <string>com.greyhoundforty.EngagementTracker</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
```

- [ ] **Step 4: Create entitlements file**

Create `EngagementTracker/EngagementTracker.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
</dict>
</plist>
```

- [ ] **Step 5: Create stub app entry point**

Create `EngagementTracker/App/EngagementTrackerApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct EngagementTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Hello, Engagement Tracker")
        }
    }
}
```

- [ ] **Step 6: Create stub test file**

Create `EngagementTrackerTests/CheckpointSeederTests.swift`:

```swift
import Testing
@testable import EngagementTracker

@Suite("Checkpoint Seeder")
struct CheckpointSeederTests {
    @Test func placeholder() {
        #expect(1 == 1)
    }
}
```

- [ ] **Step 7: Generate and open Xcode project**

```bash
cd /Users/ryan/claude-projects/worktrees/feat-swift-app-internal-7gs
xcodegen generate
open EngagementTracker.xcodeproj
```

Expected: Xcode opens with the project. Build succeeds (Cmd+B).

- [ ] **Step 8: Commit**

```bash
git add project.yml EngagementTracker/ EngagementTrackerTests/
git commit -m "feat: scaffold xcodegen project with stub app entry"
```

---

## Task 2: Enums and SwiftData models

**Files:**
- Create: `EngagementTracker/Models/Enums.swift`
- Create: `EngagementTracker/Models/Project.swift`
- Create: `EngagementTracker/Models/Contact.swift`
- Create: `EngagementTracker/Models/Checkpoint.swift`
- Create: `EngagementTracker/Models/ProjectTask.swift`
- Create: `EngagementTracker/Models/Engagement.swift`
- Create: `EngagementTracker/Models/Note.swift`

- [ ] **Step 1: Write Enums.swift**

```swift
import Foundation

enum ProjectStage: String, Codable, CaseIterable, Identifiable {
    case discovery        = "Discovery"
    case initialDelivery  = "Initial Delivery"
    case refine           = "Refine"
    case proposal         = "Proposal"
    case won              = "Won"
    case lost             = "Lost"

    var id: String { rawValue }

    var isTerminal: Bool {
        self == .won || self == .lost
    }

    var next: ProjectStage? {
        switch self {
        case .discovery:       return .initialDelivery
        case .initialDelivery: return .refine
        case .refine:          return .proposal
        case .proposal:        return nil
        case .won, .lost:      return nil
        }
    }
}

enum ContactType: String, Codable, CaseIterable {
    case external       = "External (Customer)"
    case ibmInternal    = "Internal (IBM)"
    case businessPartner = "Business Partner"
}

enum InternalRole: String, Codable, CaseIterable {
    case ae      = "Account Executive"
    case se      = "Solutions Engineer"
    case manager = "Manager"
    case other   = "Other"
}
```

- [ ] **Step 2: Write Project.swift**

```swift
import Foundation
import SwiftData

@Model
final class Project {
    var id: UUID
    var name: String
    var accountName: String?
    var opportunityID: String?
    var stage: ProjectStage
    var isPOC: Bool
    var estimatedValueCents: Int?           // stored as cents to avoid Decimal SwiftData issues
    var targetCloseDate: Date?
    var tags: [String]
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade) var contacts: [Contact]
    @Relationship(deleteRule: .cascade) var checkpoints: [Checkpoint]
    @Relationship(deleteRule: .cascade) var tasks: [ProjectTask]
    @Relationship(deleteRule: .cascade) var engagements: [Engagement]
    @Relationship(deleteRule: .cascade) var notes: [Note]

    init(
        name: String,
        accountName: String? = nil,
        opportunityID: String? = nil,
        stage: ProjectStage = .discovery,
        isPOC: Bool = false,
        estimatedValueCents: Int? = nil,
        targetCloseDate: Date? = nil,
        tags: [String] = []
    ) {
        self.id = UUID()
        self.name = name
        self.accountName = accountName
        self.opportunityID = opportunityID
        self.stage = stage
        self.isPOC = isPOC
        self.estimatedValueCents = estimatedValueCents
        self.targetCloseDate = targetCloseDate
        self.tags = tags
        self.isActive = true
        self.createdAt = Date()
        self.updatedAt = Date()
        self.contacts = []
        self.checkpoints = []
        self.tasks = []
        self.engagements = []
        self.notes = []
    }

    var estimatedValueFormatted: String? {
        guard let cents = estimatedValueCents else { return nil }
        let dollars = Double(cents) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: dollars))
    }
}
```

- [ ] **Step 3: Write Contact.swift**

```swift
import Foundation
import SwiftData

@Model
final class Contact {
    var id: UUID
    var name: String
    var title: String?
    var email: String?
    var type: ContactType
    var internalRole: InternalRole?
    var createdAt: Date

    var project: Project?

    init(
        name: String,
        title: String? = nil,
        email: String? = nil,
        type: ContactType,
        internalRole: InternalRole? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.title = title
        self.email = email
        self.type = type
        self.internalRole = internalRole
        self.createdAt = Date()
    }
}
```

- [ ] **Step 4: Write Checkpoint.swift**

```swift
import Foundation
import SwiftData

@Model
final class Checkpoint {
    var id: UUID
    var title: String
    var stage: ProjectStage
    var isCompleted: Bool
    var completedAt: Date?
    var sortOrder: Int

    var project: Project?

    init(title: String, stage: ProjectStage, sortOrder: Int) {
        self.id = UUID()
        self.title = title
        self.stage = stage
        self.isCompleted = false
        self.completedAt = nil
        self.sortOrder = sortOrder
    }

    func toggle() {
        isCompleted.toggle()
        completedAt = isCompleted ? Date() : nil
    }
}
```

- [ ] **Step 5: Write ProjectTask.swift**

```swift
import Foundation
import SwiftData

@Model
final class ProjectTask {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var completedAt: Date?
    var dueDate: Date?
    var createdAt: Date

    var project: Project?

    init(title: String, dueDate: Date? = nil) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.completedAt = nil
        self.dueDate = dueDate
        self.createdAt = Date()
    }

    func toggle() {
        isCompleted.toggle()
        completedAt = isCompleted ? Date() : nil
    }
}
```

- [ ] **Step 6: Write Engagement.swift**

```swift
import Foundation
import SwiftData

@Model
final class Engagement {
    var id: UUID
    var date: Date
    var summary: String
    var contactIDs: [UUID]      // IDs of Contact objects on this project
    var createdAt: Date

    var project: Project?

    init(date: Date = Date(), summary: String, contactIDs: [UUID] = []) {
        self.id = UUID()
        self.date = date
        self.summary = summary
        self.contactIDs = contactIDs
        self.createdAt = Date()
    }
}
```

- [ ] **Step 7: Write Note.swift**

```swift
import Foundation
import SwiftData

@Model
final class Note {
    var id: UUID
    var content: String
    var createdAt: Date

    var project: Project?

    init(content: String) {
        self.id = UUID()
        self.content = content
        self.createdAt = Date()
    }
}
```

- [ ] **Step 8: Build to confirm no errors**

In Xcode: Cmd+B. Expected: Build Succeeded with 0 errors.

- [ ] **Step 9: Commit**

```bash
git add EngagementTracker/Models/
git commit -m "feat: add SwiftData models and enums"
```

---

## Task 3: CheckpointSeeder (with tests)

**Files:**
- Create: `EngagementTracker/Models/CheckpointSeeder.swift`
- Modify: `EngagementTrackerTests/CheckpointSeederTests.swift`

- [ ] **Step 1: Write the failing tests first**

Replace `EngagementTrackerTests/CheckpointSeederTests.swift`:

```swift
import Testing
@testable import EngagementTracker

@Suite("CheckpointSeeder")
struct CheckpointSeederTests {

    @Test func discoveryTitles() {
        let titles = CheckpointSeeder.titles(for: .discovery)
        #expect(titles.count == 4)
        #expect(titles[0] == "Discovery call scheduled")
        #expect(titles[1] == "Discovery call completed")
        #expect(titles[2] == "Stakeholders identified")
        #expect(titles[3] == "Pain points documented")
    }

    @Test func initialDeliveryTitles() {
        let titles = CheckpointSeeder.titles(for: .initialDelivery)
        #expect(titles.count == 3)
        #expect(titles[0] == "Solution / BOM draft started")
        #expect(titles[1] == "Initial BOM delivered")
        #expect(titles[2] == "Architecture overview shared")
    }

    @Test func refineTitles() {
        let titles = CheckpointSeeder.titles(for: .refine)
        #expect(titles.count == 3)
        #expect(titles[0] == "Customer feedback received")
        #expect(titles[1] == "BOM / solution revised")
        #expect(titles[2] == "Technical deep-dive completed")
    }

    @Test func proposalTitles() {
        let titles = CheckpointSeeder.titles(for: .proposal)
        #expect(titles.count == 3)
        #expect(titles[0] == "Proposal drafted")
        #expect(titles[1] == "Internal review complete")
        #expect(titles[2] == "Proposal delivered to customer")
    }

    @Test func wonTitles() {
        let titles = CheckpointSeeder.titles(for: .won)
        #expect(titles.count == 1)
        #expect(titles[0] == "Contract / order signed")
    }

    @Test func lostTitles() {
        let titles = CheckpointSeeder.titles(for: .lost)
        #expect(titles.count == 1)
        #expect(titles[0] == "Close reason documented")
    }

    @Test func allActiveStagesSeeded() {
        let active: [ProjectStage] = [.discovery, .initialDelivery, .refine, .proposal]
        for stage in active {
            #expect(!CheckpointSeeder.titles(for: stage).isEmpty, "Stage \(stage.rawValue) has no checkpoints")
        }
    }

    @Test func checkpointsHaveCorrectStageAndOrder() {
        let checkpoints = CheckpointSeeder.makeCheckpoints(for: .discovery)
        #expect(checkpoints.count == 4)
        for (i, cp) in checkpoints.enumerated() {
            #expect(cp.stage == .discovery)
            #expect(cp.sortOrder == i)
            #expect(cp.isCompleted == false)
        }
    }
}
```

- [ ] **Step 2: Run tests to confirm they fail**

In Xcode: Cmd+U. Expected: All CheckpointSeederTests fail — "CheckpointSeeder not found".

- [ ] **Step 3: Write CheckpointSeeder.swift**

```swift
import Foundation

enum CheckpointSeeder {

    static func titles(for stage: ProjectStage) -> [String] {
        switch stage {
        case .discovery:
            return [
                "Discovery call scheduled",
                "Discovery call completed",
                "Stakeholders identified",
                "Pain points documented"
            ]
        case .initialDelivery:
            return [
                "Solution / BOM draft started",
                "Initial BOM delivered",
                "Architecture overview shared"
            ]
        case .refine:
            return [
                "Customer feedback received",
                "BOM / solution revised",
                "Technical deep-dive completed"
            ]
        case .proposal:
            return [
                "Proposal drafted",
                "Internal review complete",
                "Proposal delivered to customer"
            ]
        case .won:
            return ["Contract / order signed"]
        case .lost:
            return ["Close reason documented"]
        }
    }

    /// Creates Checkpoint model objects for a single stage (not inserted into context).
    static func makeCheckpoints(for stage: ProjectStage) -> [Checkpoint] {
        titles(for: stage).enumerated().map { index, title in
            Checkpoint(title: title, stage: stage, sortOrder: index)
        }
    }

    /// Creates Checkpoint model objects for all stages.
    static func makeAllCheckpoints() -> [Checkpoint] {
        ProjectStage.allCases.flatMap { makeCheckpoints(for: $0) }
    }
}
```

- [ ] **Step 4: Run tests — all should pass**

In Xcode: Cmd+U. Expected: All 8 CheckpointSeederTests pass.

- [ ] **Step 5: Commit**

```bash
git add EngagementTracker/Models/CheckpointSeeder.swift EngagementTrackerTests/CheckpointSeederTests.swift
git commit -m "feat: add CheckpointSeeder with full test coverage"
```

---

## Task 4: AppState and persistence setup

**Files:**
- Create: `EngagementTracker/App/AppState.swift`
- Modify: `EngagementTracker/App/EngagementTrackerApp.swift`

- [ ] **Step 1: Write AppState.swift**

```swift
import SwiftUI
import SwiftData

@Observable
final class AppState {
    var selectedStage: ProjectStage? = .discovery
    var selectedProject: Project?
    var searchQuery: String = ""
    var isCloudSyncEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "cloudSyncEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "cloudSyncEnabled") }
    }

    static func makeContainer(cloudSync: Bool) -> ModelContainer {
        let schema = Schema([
            Project.self,
            Contact.self,
            Checkpoint.self,
            ProjectTask.self,
            Engagement.self,
            Note.self
        ])
        let config: ModelConfiguration
        if cloudSync {
            config = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
        } else {
            config = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        }
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
```

- [ ] **Step 2: Update EngagementTrackerApp.swift with dual-mode setup**

```swift
import SwiftUI
import SwiftData

@main
struct EngagementTrackerApp: App {
    @State private var appState = AppState()

    var container: ModelContainer {
        AppState.makeContainer(cloudSync: appState.isCloudSyncEnabled)
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environment(appState)
        }
        .modelContainer(container)

        MenuBarExtra("Engagement Tracker", systemImage: "briefcase.fill") {
            MenuBarPopoverView()
                .environment(appState)
                .modelContainer(container)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(appState)
        }
    }
}
```

- [ ] **Step 3: Create stub ContentView**

Create `EngagementTracker/Views/Main/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Main Window — coming soon")
            .frame(minWidth: 900, minHeight: 600)
    }
}
```

- [ ] **Step 4: Create stub MenuBarPopoverView**

Create `EngagementTracker/Views/MenuBar/MenuBarPopoverView.swift`:

```swift
import SwiftUI

struct MenuBarPopoverView: View {
    var body: some View {
        Text("Menu Bar — coming soon")
            .frame(width: 320, height: 200)
            .padding()
    }
}
```

- [ ] **Step 5: Create stub SettingsView**

Create `EngagementTracker/Views/Settings/SettingsView.swift`:

```swift
import SwiftUI

struct SettingsView: View {
    var body: some View {
        Text("Settings — coming soon")
            .frame(width: 400, height: 200)
            .padding()
    }
}
```

- [ ] **Step 6: Build and run**

Cmd+R. Expected: App launches showing "Main Window — coming soon" in the dock window and a briefcase icon in the menu bar.

- [ ] **Step 7: Commit**

```bash
git add EngagementTracker/App/ EngagementTracker/Views/
git commit -m "feat: dual-mode app entry with SwiftData container and menu bar extra"
```

---

## Task 5: Gruvbox theme

**Files:**
- Create: `EngagementTracker/Theme/GruvboxColors.swift`

- [ ] **Step 1: Write GruvboxColors.swift**

```swift
import SwiftUI

// Gruvbox Light and Dark Medium palettes
// https://github.com/morhetz/gruvbox
extension Color {

    // MARK: - Backgrounds

    /// Main window background
    static var gruvBg: Color          { Color("gruvBg") }
    /// Sidebar / panel background
    static var gruvBg1: Color         { Color("gruvBg1") }
    /// Selected row / elevated surface
    static var gruvBg2: Color         { Color("gruvBg2") }
    /// Dividers / subtle borders
    static var gruvBg3: Color         { Color("gruvBg3") }

    // MARK: - Foregrounds

    static var gruvFg: Color          { Color("gruvFg") }
    static var gruvFg2: Color         { Color("gruvFg2") }
    static var gruvFgDim: Color       { Color("gruvFgDim") }

    // MARK: - Accent colors

    static var gruvRed: Color         { Color("gruvRed") }
    static var gruvGreen: Color       { Color("gruvGreen") }
    static var gruvYellow: Color      { Color("gruvYellow") }
    static var gruvBlue: Color        { Color("gruvBlue") }
    static var gruvPurple: Color      { Color("gruvPurple") }
    static var gruvAqua: Color        { Color("gruvAqua") }
    static var gruvOrange: Color      { Color("gruvOrange") }
}

extension Color {
    /// Returns the Gruvbox accent color for a given project stage.
    static func gruvStageColor(for stage: ProjectStage) -> Color {
        switch stage {
        case .discovery:       return .gruvAqua
        case .initialDelivery: return .gruvYellow
        case .refine:          return .gruvOrange
        case .proposal:        return .gruvRed
        case .won:             return .gruvGreen
        case .lost:            return .gruvRed
        }
    }
}

// MARK: - Asset catalog values
// Add these in Assets.xcassets as Color Sets with "Any Appearance" and "Dark" variants.
//
// gruvBg:      light=#fbf1c7   dark=#282828
// gruvBg1:     light=#f2e5bc   dark=#32302f
// gruvBg2:     light=#ebdbb2   dark=#3c3836
// gruvBg3:     light=#d5c4a1   dark=#504945
// gruvFg:      light=#282828   dark=#ebdbb2
// gruvFg2:     light=#3c3836   dark=#d5c4a1
// gruvFgDim:   light=#a89984   dark=#a89984
// gruvRed:     light=#9d0006   dark=#fb4934
// gruvGreen:   light=#79740e   dark=#b8bb26
// gruvYellow:  light=#b57614   dark=#fabd2f
// gruvBlue:    light=#076678   dark=#83a598
// gruvPurple:  light=#8f3f71   dark=#d3869b
// gruvAqua:    light=#427b58   dark=#8ec07c
// gruvOrange:  light=#af3a03   dark=#fe8019
```

- [ ] **Step 2: Add color assets to Assets.xcassets**

In Xcode, open `EngagementTracker/Assets.xcassets`. For each color name listed in the comment above, create a new Color Set with the light and dark hex values. Values:

| Asset name   | Any (Light)  | Dark         |
|--------------|-------------|--------------|
| gruvBg       | #fbf1c7     | #282828      |
| gruvBg1      | #f2e5bc     | #32302f      |
| gruvBg2      | #ebdbb2     | #3c3836      |
| gruvBg3      | #d5c4a1     | #504945      |
| gruvFg       | #282828     | #ebdbb2      |
| gruvFg2      | #3c3836     | #d5c4a1      |
| gruvFgDim    | #a89984     | #a89984      |
| gruvRed      | #9d0006     | #fb4934      |
| gruvGreen    | #79740e     | #b8bb26      |
| gruvYellow   | #b57614     | #fabd2f      |
| gruvBlue     | #076678     | #83a598      |
| gruvPurple   | #8f3f71     | #d3869b      |
| gruvAqua     | #427b58     | #8ec07c      |
| gruvOrange   | #af3a03     | #fe8019      |

Alternatively, create `EngagementTracker/Assets.xcassets/Colors/` folder and add each as a `.colorset` directory with `Contents.json`.

- [ ] **Step 3: Verify colors resolve**

Add a quick test to `ContentView.swift` (temporary, remove after verifying):

```swift
HStack {
    Color.gruvBg.frame(width: 30, height: 30)
    Color.gruvAqua.frame(width: 30, height: 30)
    Color.gruvYellow.frame(width: 30, height: 30)
    Color.gruvOrange.frame(width: 30, height: 30)
    Color.gruvRed.frame(width: 30, height: 30)
    Color.gruvGreen.frame(width: 30, height: 30)
}
```

Run app, confirm color swatches appear. Toggle system dark/light mode to verify both variants work.

- [ ] **Step 4: Revert ContentView to stub**

Remove the test swatches — restore `ContentView.swift` to the stub from Task 4.

- [ ] **Step 5: Commit**

```bash
git add EngagementTracker/Theme/ EngagementTracker/Assets.xcassets/
git commit -m "feat: Gruvbox light/dark color theme with asset catalog"
```

---

## Task 6: Main window NavigationSplitView

**Files:**
- Modify: `EngagementTracker/Views/Main/ContentView.swift`
- Create: `EngagementTracker/Views/Main/StagesSidebarView.swift`
- Create: `EngagementTracker/Views/Main/ProjectListView.swift`
- Create: `EngagementTracker/Views/Main/ProjectDetailView.swift`

- [ ] **Step 1: Write StagesSidebarView.swift**

```swift
import SwiftUI
import SwiftData

struct StagesSidebarView: View {
    @Environment(AppState.self) private var appState
    @Query private var projects: [Project]

    var body: some View {
        @Bindable var appState = appState
        List(selection: $appState.selectedStage) {
            Section {
                Label("All Projects", systemImage: "folder")
                    .tag(Optional<ProjectStage>.none)
                    .badge(projects.filter(\.isActive).count)
            }

            Section("Pipeline") {
                ForEach(ProjectStage.allCases.filter { !$0.isTerminal }) { stage in
                    Label(stage.rawValue, systemImage: stageIcon(stage))
                        .tag(Optional(stage))
                        .badge(count(for: stage))
                        .foregroundStyle(Color.gruvStageColor(for: stage))
                }
            }

            Section("Closed") {
                Label(ProjectStage.won.rawValue, systemImage: "checkmark.seal.fill")
                    .tag(Optional(ProjectStage.won))
                    .badge(count(for: .won))
                    .foregroundStyle(Color.gruvGreen)

                Label(ProjectStage.lost.rawValue, systemImage: "xmark.seal.fill")
                    .tag(Optional(ProjectStage.lost))
                    .badge(count(for: .lost))
                    .foregroundStyle(Color.gruvRed)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Engagement Tracker")
        .frame(minWidth: 160)
    }

    private func count(for stage: ProjectStage) -> Int {
        projects.filter { $0.stage == stage && $0.isActive }.count
    }

    private func stageIcon(_ stage: ProjectStage) -> String {
        switch stage {
        case .discovery:       return "magnifyingglass"
        case .initialDelivery: return "doc.text"
        case .refine:          return "pencil.and.list.clipboard"
        case .proposal:        return "envelope.open"
        case .won:             return "checkmark.seal.fill"
        case .lost:            return "xmark.seal.fill"
        }
    }
}
```

- [ ] **Step 2: Write ProjectListView.swift**

```swift
import SwiftUI
import SwiftData

struct ProjectListView: View {
    @Environment(AppState.self) private var appState
    @Query private var allProjects: [Project]

    private var filtered: [Project] {
        let base = allProjects.filter(\.isActive)
        let byStage: [Project]
        if let stage = appState.selectedStage {
            byStage = base.filter { $0.stage == stage }
        } else {
            byStage = base
        }
        guard !appState.searchQuery.isEmpty else { return byStage }
        let q = appState.searchQuery.lowercased()
        return byStage.filter {
            $0.name.lowercased().contains(q) ||
            ($0.accountName?.lowercased().contains(q) ?? false) ||
            ($0.opportunityID?.lowercased().contains(q) ?? false)
        }
    }

    var body: some View {
        @Bindable var appState = appState
        List(filtered, selection: $appState.selectedProject) { project in
            ProjectRowView(project: project)
                .tag(project)
        }
        .listStyle(.inset)
        .frame(minWidth: 220)
        .navigationTitle(appState.selectedStage?.rawValue ?? "All Projects")
        .overlay {
            if filtered.isEmpty {
                ContentUnavailableView("No Projects", systemImage: "briefcase", description: Text("Create a project to get started."))
            }
        }
    }
}

struct ProjectRowView: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(project.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.gruvFg)
                if project.isPOC {
                    Text("POC")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.gruvPurple)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.gruvBg2)
                        .clipShape(Capsule())
                }
                Spacer()
                if let value = project.estimatedValueFormatted {
                    Text(value)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.gruvGreen)
                }
            }
            HStack(spacing: 6) {
                if let account = project.accountName {
                    Text(account)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.gruvFgDim)
                }
                Spacer()
                Text(project.stage.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.gruvStageColor(for: project.stage))
            }
        }
        .padding(.vertical, 4)
    }
}
```

- [ ] **Step 3: Write stub ProjectDetailView.swift**

```swift
import SwiftUI

struct ProjectDetailView: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            ProjectDetailHeaderView(project: project)
            Divider()
            // Tabs — implemented in Task 7
            Text("Tabs coming soon")
                .foregroundStyle(Color.gruvFgDim)
                .padding()
            Spacer()
        }
        .background(Color.gruvBg)
    }
}

struct ProjectDetailHeaderView: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(project.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.gruvFg)
                Spacer()
                if !project.stage.isTerminal, let next = project.stage.next {
                    Button("Advance to \(next.rawValue)") {
                        project.stage = next
                        project.updatedAt = Date()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.gruvStageColor(for: next))
                }
            }
            HStack(spacing: 8) {
                StagePill(stage: project.stage)
                if project.isPOC {
                    TagPill(label: "POC", color: .gruvPurple)
                }
                if let value = project.estimatedValueFormatted {
                    TagPill(label: value, color: .gruvGreen)
                }
                if let account = project.accountName {
                    TagPill(label: account, color: .gruvFgDim)
                }
                if let closeDate = project.targetCloseDate {
                    TagPill(label: "Close: \(closeDate.formatted(date: .abbreviated, time: .omitted))", color: .gruvFgDim)
                }
            }
        }
        .padding()
        .background(Color.gruvBg1)
    }
}

struct StagePill: View {
    let stage: ProjectStage
    var body: some View {
        Text("● \(stage.rawValue)")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.gruvStageColor(for: stage))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.gruvBg2)
            .clipShape(Capsule())
    }
}

struct TagPill: View {
    let label: String
    let color: Color
    var body: some View {
        Text(label)
            .font(.system(size: 11))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.gruvBg2)
            .clipShape(Capsule())
    }
}
```

- [ ] **Step 4: Wire up ContentView.swift**

```swift
import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState
        NavigationSplitView {
            StagesSidebarView()
        } content: {
            ProjectListView()
        } detail: {
            if let project = appState.selectedProject {
                ProjectDetailView(project: project)
            } else {
                ContentUnavailableView("Select a Project", systemImage: "briefcase", description: Text("Choose a project from the list."))
                    .background(Color.gruvBg)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .background(Color.gruvBg)
    }
}
```

- [ ] **Step 5: Build and run**

Cmd+R. Expected: Three-column window appears. Stage sidebar shows all stages. Project list is empty but shows "No Projects" empty state. Menu bar briefcase icon present.

- [ ] **Step 6: Commit**

```bash
git add EngagementTracker/Views/Main/
git commit -m "feat: three-column NavigationSplitView with stage sidebar and project list"
```

---

## Task 7: New Project sheet

**Files:**
- Create: `EngagementTracker/Views/Sheets/NewProjectSheet.swift`
- Modify: `EngagementTracker/Views/Main/ProjectListView.swift`

- [ ] **Step 1: Write NewProjectSheet.swift**

```swift
import SwiftUI
import SwiftData

struct NewProjectSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var accountName: String = ""
    @State private var opportunityID: String = ""
    @State private var isPOC: Bool = false
    @State private var estimatedValueString: String = ""
    @State private var targetCloseDate: Date = Date()
    @State private var hasCloseDate: Bool = false
    @State private var tagsString: String = ""
    @State private var initialStage: ProjectStage = .discovery

    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title bar
            HStack {
                Text("New Project")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.gruvFg)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
                Button("Create") { save() }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.gruvAqua)
                    .disabled(!isValid)
                    .keyboardShortcut(.return, modifiers: .command)
            }
            .padding()
            .background(Color.gruvBg1)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    FormSection(title: "Project") {
                        LabeledField(label: "Name *") {
                            TextField("Required", text: $name)
                        }
                        LabeledField(label: "Account / Company") {
                            TextField("Optional", text: $accountName)
                        }
                        LabeledField(label: "Opportunity ID") {
                            TextField("Optional", text: $opportunityID)
                        }
                        LabeledField(label: "Initial Stage") {
                            Picker("", selection: $initialStage) {
                                ForEach(ProjectStage.allCases) { stage in
                                    Text(stage.rawValue).tag(stage)
                                }
                            }
                            .labelsHidden()
                        }
                    }

                    FormSection(title: "Details") {
                        LabeledField(label: "Estimated Value") {
                            TextField("e.g. 240000", text: $estimatedValueString)
                        }
                        Toggle("Has Target Close Date", isOn: $hasCloseDate)
                            .foregroundStyle(Color.gruvFg)
                        if hasCloseDate {
                            DatePicker("Close Date", selection: $targetCloseDate, displayedComponents: .date)
                                .foregroundStyle(Color.gruvFg)
                        }
                        LabeledField(label: "Tags (comma-separated)") {
                            TextField("Optional", text: $tagsString)
                        }
                    }

                    FormSection(title: "Flags") {
                        Toggle("This is a POC engagement", isOn: $isPOC)
                            .foregroundStyle(Color.gruvFg)
                    }
                }
                .padding()
            }
        }
        .background(Color.gruvBg)
        .frame(width: 480)
    }

    private func save() {
        let project = Project(
            name: name.trimmingCharacters(in: .whitespaces),
            accountName: accountName.isEmpty ? nil : accountName,
            opportunityID: opportunityID.isEmpty ? nil : opportunityID,
            stage: initialStage,
            isPOC: isPOC,
            estimatedValueCents: parseCents(estimatedValueString),
            targetCloseDate: hasCloseDate ? targetCloseDate : nil,
            tags: tagsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        )
        context.insert(project)
        let checkpoints = CheckpointSeeder.makeAllCheckpoints()
        checkpoints.forEach { cp in
            project.checkpoints.append(cp)
            context.insert(cp)
        }
        try? context.save()
        dismiss()
    }

    private func parseCents(_ string: String) -> Int? {
        let digits = string.filter { $0.isNumber || $0 == "." }
        guard let value = Double(digits) else { return nil }
        return Int(value * 100)
    }
}

struct FormSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.gruvFgDim)
            content
        }
        .padding()
        .background(Color.gruvBg1)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct LabeledField<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.gruvFgDim)
            content
                .textFieldStyle(.roundedBorder)
        }
    }
}
```

- [ ] **Step 2: Add toolbar button to ProjectListView.swift**

Add a toolbar to `ProjectListView.swift`. Add these state properties and the toolbar modifier to the `List`:

```swift
// Add to ProjectListView:
@State private var showNewProject = false

// Add .toolbar modifier to the List:
.toolbar {
    ToolbarItem(placement: .primaryAction) {
        Button {
            showNewProject = true
        } label: {
            Label("New Project", systemImage: "plus")
        }
        .keyboardShortcut("n", modifiers: .command)
    }
}
.sheet(isPresented: $showNewProject) {
    NewProjectSheet()
}
```

- [ ] **Step 3: Build and run — create a test project**

Cmd+R. Click + in the toolbar. Fill in a project name (e.g. "Test Corp"), click Create. Verify the project appears in the list with correct stage color pill and POC badge if applicable.

- [ ] **Step 4: Commit**

```bash
git add EngagementTracker/Views/Sheets/NewProjectSheet.swift EngagementTracker/Views/Main/ProjectListView.swift
git commit -m "feat: new project sheet with all optional fields and checkpoint auto-seeding"
```

---

## Task 8: Project detail tabs

**Files:**
- Modify: `EngagementTracker/Views/Main/ProjectDetailView.swift`
- Create: `EngagementTracker/Views/Tabs/CheckpointsTabView.swift`
- Create: `EngagementTracker/Views/Tabs/TasksTabView.swift`
- Create: `EngagementTracker/Views/Tabs/ContactsTabView.swift`
- Create: `EngagementTracker/Views/Tabs/EngagementsTabView.swift`
- Create: `EngagementTracker/Views/Tabs/NotesTabView.swift`

- [ ] **Step 1: Write CheckpointsTabView.swift**

```swift
import SwiftUI

struct CheckpointsTabView: View {
    let project: Project

    private var checkpointsByStage: [(ProjectStage, [Checkpoint])] {
        let sorted = project.checkpoints.sorted {
            let stageOrder = ProjectStage.allCases
            let aIdx = stageOrder.firstIndex(of: $0.stage) ?? 0
            let bIdx = stageOrder.firstIndex(of: $1.stage) ?? 0
            if aIdx != bIdx { return aIdx < bIdx }
            return $0.sortOrder < $1.sortOrder
        }
        var result: [(ProjectStage, [Checkpoint])] = []
        for stage in ProjectStage.allCases {
            let cps = sorted.filter { $0.stage == stage }
            if !cps.isEmpty { result.append((stage, cps)) }
        }
        return result
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16, pinnedViews: .sectionHeaders) {
                ForEach(checkpointsByStage, id: \.0) { stage, checkpoints in
                    Section {
                        ForEach(checkpoints) { checkpoint in
                            CheckpointRowView(checkpoint: checkpoint)
                        }
                    } header: {
                        HStack {
                            Text(stage.rawValue.uppercased())
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color.gruvStageColor(for: stage))
                            Spacer()
                            let completed = checkpoints.filter(\.isCompleted).count
                            Text("\(completed)/\(checkpoints.count)")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.gruvFgDim)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                        .background(Color.gruvBg1)
                    }
                }
            }
        }
    }
}

struct CheckpointRowView: View {
    let checkpoint: Checkpoint

    var body: some View {
        Button {
            checkpoint.toggle()
            checkpoint.project?.updatedAt = Date()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: checkpoint.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(checkpoint.isCompleted ? Color.gruvGreen : Color.gruvBg3)
                    .font(.system(size: 16))
                Text(checkpoint.title)
                    .font(.system(size: 13))
                    .foregroundStyle(checkpoint.isCompleted ? Color.gruvFgDim : Color.gruvFg)
                    .strikethrough(checkpoint.isCompleted, color: Color.gruvFgDim)
                Spacer()
                if let completedAt = checkpoint.completedAt {
                    Text(completedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 10))
                        .foregroundStyle(Color.gruvFgDim)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 2: Write TasksTabView.swift**

```swift
import SwiftUI
import SwiftData

struct TasksTabView: View {
    @Environment(\.modelContext) private var context
    let project: Project

    @State private var newTaskTitle: String = ""
    @State private var showCompleted: Bool = false

    private var pendingTasks: [ProjectTask] {
        project.tasks.filter { !$0.isCompleted }.sorted { $0.createdAt < $1.createdAt }
    }
    private var completedTasks: [ProjectTask] {
        project.tasks.filter(\.isCompleted).sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Add task row
            HStack {
                TextField("Add a task…", text: $newTaskTitle)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { addTask() }
                Button(action: addTask) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.gruvAqua)
                }
                .disabled(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.gruvBg1)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(pendingTasks) { task in
                        TaskRowView(task: task, onDelete: { delete(task) })
                        Divider().padding(.leading, 42)
                    }

                    if !completedTasks.isEmpty {
                        Button {
                            showCompleted.toggle()
                        } label: {
                            HStack {
                                Text(showCompleted ? "Hide Completed" : "Show Completed (\(completedTasks.count))")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.gruvFgDim)
                                Spacer()
                            }
                            .padding()
                        }
                        .buttonStyle(.plain)

                        if showCompleted {
                            ForEach(completedTasks) { task in
                                TaskRowView(task: task, onDelete: { delete(task) })
                                Divider().padding(.leading, 42)
                            }
                        }
                    }
                }
            }
        }
    }

    private func addTask() {
        let title = newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        let task = ProjectTask(title: title)
        context.insert(task)
        project.tasks.append(task)
        project.updatedAt = Date()
        newTaskTitle = ""
    }

    private func delete(_ task: ProjectTask) {
        project.tasks.removeAll { $0.id == task.id }
        context.delete(task)
    }
}

struct TaskRowView: View {
    let task: ProjectTask
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button {
                task.toggle()
                task.project?.updatedAt = Date()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isCompleted ? Color.gruvGreen : Color.gruvBg3)
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)

            Text(task.title)
                .font(.system(size: 13))
                .foregroundStyle(task.isCompleted ? Color.gruvFgDim : Color.gruvFg)
                .strikethrough(task.isCompleted, color: Color.gruvFgDim)
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(Color.gruvRed)
            }
            .buttonStyle(.plain)
            .opacity(0.6)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
```

- [ ] **Step 3: Write ContactsTabView.swift**

```swift
import SwiftUI
import SwiftData

struct ContactsTabView: View {
    @Environment(\.modelContext) private var context
    let project: Project
    @State private var showAddContact = false

    private func contacts(of type: ContactType) -> [Contact] {
        project.contacts.filter { $0.type == type }.sorted { $0.name < $1.name }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    showAddContact = true
                } label: {
                    Label("Add Contact", systemImage: "person.badge.plus")
                }
                .padding()
            }
            .background(Color.gruvBg1)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(ContactType.allCases, id: \.self) { type in
                        let group = contacts(of: type)
                        if !group.isEmpty {
                            Section {
                                ForEach(group) { contact in
                                    ContactRowView(contact: contact, onDelete: { delete(contact) })
                                }
                            } header: {
                                Text(type.rawValue.uppercased())
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Color.gruvFgDim)
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                            }
                        }
                    }

                    if project.contacts.isEmpty {
                        ContentUnavailableView("No Contacts", systemImage: "person.2", description: Text("Add customer, IBM, or partner contacts."))
                            .padding()
                    }
                }
            }
        }
        .sheet(isPresented: $showAddContact) {
            AddContactSheet(project: project)
        }
    }

    private func delete(_ contact: Contact) {
        project.contacts.removeAll { $0.id == contact.id }
        context.delete(contact)
    }
}

struct ContactRowView: View {
    let contact: Contact
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gruvBg2)
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String(contact.name.prefix(1)).uppercased())
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.gruvFg)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(contact.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.gruvFg)
                    if let role = contact.internalRole {
                        Text(role.rawValue)
                            .font(.system(size: 10))
                            .foregroundStyle(Color.gruvAqua)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Color.gruvBg2)
                            .clipShape(Capsule())
                    }
                }
                if let title = contact.title {
                    Text(title)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.gruvFgDim)
                }
                if let email = contact.email {
                    Text(email)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.gruvBlue)
                }
            }
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(Color.gruvRed)
            }
            .buttonStyle(.plain)
            .opacity(0.6)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
```

- [ ] **Step 4: Write EngagementsTabView.swift**

```swift
import SwiftUI
import SwiftData

struct EngagementsTabView: View {
    @Environment(\.modelContext) private var context
    let project: Project
    @State private var showLogEngagement = false

    private var sorted: [Engagement] {
        project.engagements.sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    showLogEngagement = true
                } label: {
                    Label("Log Engagement", systemImage: "plus.bubble")
                }
                .padding()
            }
            .background(Color.gruvBg1)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(sorted) { engagement in
                        EngagementRowView(engagement: engagement, project: project, onDelete: { delete(engagement) })
                        Divider().padding(.leading, 16)
                    }
                    if sorted.isEmpty {
                        ContentUnavailableView("No Engagements", systemImage: "bubble.left.and.bubble.right", description: Text("Log your first customer interaction."))
                            .padding()
                    }
                }
            }
        }
        .sheet(isPresented: $showLogEngagement) {
            LogEngagementSheet(project: project)
        }
    }

    private func delete(_ engagement: Engagement) {
        project.engagements.removeAll { $0.id == engagement.id }
        context.delete(engagement)
    }
}

struct EngagementRowView: View {
    let engagement: Engagement
    let project: Project
    let onDelete: () -> Void

    private var taggedContacts: [Contact] {
        project.contacts.filter { engagement.contactIDs.contains($0.id) }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                Text(engagement.date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.gruvOrange)
                Text(engagement.date.formatted(.dateTime.year()))
                    .font(.system(size: 10))
                    .foregroundStyle(Color.gruvFgDim)
            }
            .frame(width: 48)
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(engagement.summary)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.gruvFg)
                if !taggedContacts.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(taggedContacts) { contact in
                            Text(contact.name)
                                .font(.system(size: 10))
                                .foregroundStyle(Color.gruvAqua)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gruvBg2)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(Color.gruvRed)
            }
            .buttonStyle(.plain)
            .opacity(0.6)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}
```

- [ ] **Step 5: Write NotesTabView.swift**

```swift
import SwiftUI
import SwiftData

struct NotesTabView: View {
    @Environment(\.modelContext) private var context
    let project: Project

    @State private var newNoteContent: String = ""
    @State private var isAddingNote: Bool = false

    private var sorted: [Note] {
        project.notes.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        VStack(spacing: 0) {
            if isAddingNote {
                VStack(alignment: .leading, spacing: 8) {
                    TextEditor(text: $newNoteContent)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.gruvFg)
                        .frame(height: 100)
                        .padding(4)
                        .background(Color.gruvBg2)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    HStack {
                        Button("Cancel") {
                            newNoteContent = ""
                            isAddingNote = false
                        }
                        Spacer()
                        Button("Save Note") {
                            saveNote()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.gruvAqua)
                        .disabled(newNoteContent.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                .padding()
                .background(Color.gruvBg1)
                Divider()
            } else {
                HStack {
                    Spacer()
                    Button {
                        isAddingNote = true
                    } label: {
                        Label("Add Note", systemImage: "square.and.pencil")
                    }
                    .padding()
                }
                .background(Color.gruvBg1)
                Divider()
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(sorted) { note in
                        NoteRowView(note: note, onDelete: { delete(note) })
                        Divider()
                    }
                    if sorted.isEmpty {
                        ContentUnavailableView("No Notes", systemImage: "note.text", description: Text("Add your first project note."))
                            .padding()
                    }
                }
            }
        }
    }

    private func saveNote() {
        let content = newNoteContent.trimmingCharacters(in: .whitespaces)
        guard !content.isEmpty else { return }
        let note = Note(content: content)
        context.insert(note)
        project.notes.append(note)
        project.updatedAt = Date()
        newNoteContent = ""
        isAddingNote = false
    }

    private func delete(_ note: Note) {
        project.notes.removeAll { $0.id == note.id }
        context.delete(note)
    }
}

struct NoteRowView: View {
    let note: Note
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(note.createdAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                .font(.system(size: 10))
                .foregroundStyle(Color.gruvFgDim)
                .frame(width: 90, alignment: .leading)
                .padding(.top, 2)
            Text(note.content)
                .font(.system(size: 13))
                .foregroundStyle(Color.gruvFg)
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(Color.gruvRed)
            }
            .buttonStyle(.plain)
            .opacity(0.6)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}
```

- [ ] **Step 6: Wire tabs into ProjectDetailView.swift**

Replace the `ProjectDetailView` body in `ProjectDetailView.swift`:

```swift
import SwiftUI

struct ProjectDetailView: View {
    let project: Project
    @State private var selectedTab: String = "checkpoints"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ProjectDetailHeaderView(project: project)
            Divider()
            TabView(selection: $selectedTab) {
                CheckpointsTabView(project: project)
                    .tabItem { Label("Checkpoints", systemImage: "checklist") }
                    .tag("checkpoints")
                TasksTabView(project: project)
                    .tabItem { Label("Tasks", systemImage: "checkmark.square") }
                    .tag("tasks")
                ContactsTabView(project: project)
                    .tabItem { Label("Contacts", systemImage: "person.2") }
                    .tag("contacts")
                EngagementsTabView(project: project)
                    .tabItem { Label("Engagements", systemImage: "bubble.left.and.bubble.right") }
                    .tag("engagements")
                NotesTabView(project: project)
                    .tabItem { Label("Notes", systemImage: "note.text") }
                    .tag("notes")
            }
        }
        .background(Color.gruvBg)
    }
}
```

- [ ] **Step 7: Build and run — exercise all tabs**

Cmd+R. Create a project. Click into it. Verify all 5 tabs render and switch correctly. Add a task — confirm it appears and can be toggled. Add a note — confirm it saves. Check checkpoints from seeding appear under the Checkpoints tab.

- [ ] **Step 8: Commit**

```bash
git add EngagementTracker/Views/Tabs/ EngagementTracker/Views/Main/ProjectDetailView.swift
git commit -m "feat: project detail tabs — checkpoints, tasks, contacts, engagements, notes"
```

---

## Task 9: Add Contact and Log Engagement sheets

**Files:**
- Create: `EngagementTracker/Views/Sheets/AddContactSheet.swift`
- Create: `EngagementTracker/Views/Sheets/LogEngagementSheet.swift`

- [ ] **Step 1: Write AddContactSheet.swift**

```swift
import SwiftUI
import SwiftData

struct AddContactSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let project: Project

    @State private var name: String = ""
    @State private var title: String = ""
    @State private var email: String = ""
    @State private var type: ContactType = .external
    @State private var internalRole: InternalRole = .ae

    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Add Contact")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.gruvFg)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
                Button("Add") { save() }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.gruvAqua)
                    .disabled(!isValid)
                    .keyboardShortcut(.return, modifiers: .command)
            }
            .padding()
            .background(Color.gruvBg1)

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                FormSection(title: "Contact Type") {
                    Picker("Type", selection: $type) {
                        ForEach(ContactType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    if type == .ibmInternal {
                        Picker("Role", selection: $internalRole) {
                            ForEach(InternalRole.allCases, id: \.self) { r in
                                Text(r.rawValue).tag(r)
                            }
                        }
                    }
                }

                FormSection(title: "Contact Details") {
                    LabeledField(label: "Name *") {
                        TextField("Required", text: $name)
                    }
                    LabeledField(label: "Title / Position") {
                        TextField("Optional", text: $title)
                    }
                    LabeledField(label: "Email") {
                        TextField("Optional", text: $email)
                    }
                }
            }
            .padding()
        }
        .background(Color.gruvBg)
        .frame(width: 420)
    }

    private func save() {
        let contact = Contact(
            name: name.trimmingCharacters(in: .whitespaces),
            title: title.isEmpty ? nil : title,
            email: email.isEmpty ? nil : email,
            type: type,
            internalRole: type == .ibmInternal ? internalRole : nil
        )
        context.insert(contact)
        project.contacts.append(contact)
        project.updatedAt = Date()
        try? context.save()
        dismiss()
    }
}
```

- [ ] **Step 2: Write LogEngagementSheet.swift**

```swift
import SwiftUI
import SwiftData

struct LogEngagementSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let project: Project

    @State private var date: Date = Date()
    @State private var summary: String = ""
    @State private var selectedContactIDs: Set<UUID> = []

    var isValid: Bool { !summary.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Log Engagement")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.gruvFg)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
                Button("Save") { save() }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.gruvOrange)
                    .disabled(!isValid)
                    .keyboardShortcut(.return, modifiers: .command)
            }
            .padding()
            .background(Color.gruvBg1)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    FormSection(title: "When") {
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .foregroundStyle(Color.gruvFg)
                    }

                    FormSection(title: "Summary *") {
                        TextEditor(text: $summary)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.gruvFg)
                            .frame(height: 100)
                            .padding(4)
                            .background(Color.gruvBg2)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    if !project.contacts.isEmpty {
                        FormSection(title: "Who was involved?") {
                            ForEach(project.contacts.sorted { $0.name < $1.name }) { contact in
                                Button {
                                    if selectedContactIDs.contains(contact.id) {
                                        selectedContactIDs.remove(contact.id)
                                    } else {
                                        selectedContactIDs.insert(contact.id)
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: selectedContactIDs.contains(contact.id) ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(selectedContactIDs.contains(contact.id) ? Color.gruvAqua : Color.gruvBg3)
                                        Text(contact.name)
                                            .foregroundStyle(Color.gruvFg)
                                        if let title = contact.title {
                                            Text("· \(title)")
                                                .font(.system(size: 11))
                                                .foregroundStyle(Color.gruvFgDim)
                                        }
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color.gruvBg)
        .frame(width: 460)
    }

    private func save() {
        let engagement = Engagement(
            date: date,
            summary: summary.trimmingCharacters(in: .whitespaces),
            contactIDs: Array(selectedContactIDs)
        )
        context.insert(engagement)
        project.engagements.append(engagement)
        project.updatedAt = Date()
        try? context.save()
        dismiss()
    }
}
```

- [ ] **Step 3: Build and run — test both sheets**

Cmd+R. Open a project → Contacts tab → Add Contact. Verify contact appears grouped by type. Open Engagements tab → Log Engagement. Verify tagged contacts appear as pills on the engagement row.

- [ ] **Step 4: Commit**

```bash
git add EngagementTracker/Views/Sheets/
git commit -m "feat: add contact and log engagement sheets"
```

---

## Task 10: Menu bar popover

**Files:**
- Modify: `EngagementTracker/Views/MenuBar/MenuBarPopoverView.swift`

- [ ] **Step 1: Write the full MenuBarPopoverView.swift**

```swift
import SwiftUI
import SwiftData

struct MenuBarPopoverView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \Project.updatedAt, order: .reverse) private var allProjects: [Project]

    @State private var showNewProject = false
    @State private var showLogEngagement = false

    private var activeProjects: [Project] { allProjects.filter(\.isActive) }

    private var filtered: [Project] {
        guard !appState.searchQuery.isEmpty else { return [] }
        let q = appState.searchQuery.lowercased()
        return activeProjects.filter {
            $0.name.lowercased().contains(q) ||
            ($0.accountName?.lowercased().contains(q) ?? false)
        }
    }

    private var pipelineStages: [ProjectStage] {
        [.discovery, .initialDelivery, .refine, .proposal]
    }

    private func count(for stage: ProjectStage) -> Int {
        activeProjects.filter { $0.stage == stage }.count
    }

    var body: some View {
        @Bindable var appState = appState
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.gruvFgDim)
                TextField("Search projects…", text: $appState.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                if !appState.searchQuery.isEmpty {
                    Button {
                        appState.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.gruvFgDim)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color.gruvBg1)

            Divider()

            if !appState.searchQuery.isEmpty {
                // Search results
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if filtered.isEmpty {
                            Text("No results")
                                .foregroundStyle(Color.gruvFgDim)
                                .font(.system(size: 12))
                                .padding()
                        } else {
                            ForEach(filtered) { project in
                                MenuBarProjectRow(project: project)
                                Divider()
                            }
                        }
                    }
                }
                .frame(maxHeight: 260)
            } else {
                // Quick actions
                HStack(spacing: 8) {
                    Button {
                        showNewProject = true
                    } label: {
                        Label("New Project", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.gruvAqua)

                    Button {
                        showLogEngagement = true
                    } label: {
                        Label("Log Engagement", systemImage: "bolt")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.gruvOrange)
                    .disabled(activeProjects.isEmpty)
                }
                .padding(10)

                Divider()

                // Pipeline summary
                VStack(alignment: .leading, spacing: 6) {
                    Text("PIPELINE")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.gruvFgDim)
                        .padding(.horizontal, 10)
                        .padding(.top, 8)

                    HStack(spacing: 6) {
                        ForEach(pipelineStages) { stage in
                            VStack(spacing: 2) {
                                Text("\(count(for: stage))")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(Color.gruvStageColor(for: stage))
                                Text(stageAbbrev(stage))
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color.gruvFgDim)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.gruvBg1)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)
                }

                Divider()

                // Last touched project
                if let last = activeProjects.first {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LAST TOUCHED")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.gruvFgDim)
                        MenuBarProjectRow(project: last)
                    }
                    .padding(10)
                }
            }

            Divider()

            // Footer
            HStack {
                Button("Open App") {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.windows.first?.makeKeyAndOrderFront(nil)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundStyle(Color.gruvBlue)
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.gruvFgDim)
            }
            .padding(10)
            .background(Color.gruvBg1)
        }
        .background(Color.gruvBg)
        .frame(width: 320)
        .sheet(isPresented: $showNewProject) {
            NewProjectSheet()
        }
        .sheet(isPresented: $showLogEngagement) {
            if let last = activeProjects.first {
                LogEngagementSheet(project: last)
            }
        }
    }

    private func stageAbbrev(_ stage: ProjectStage) -> String {
        switch stage {
        case .discovery:       return "Discovery"
        case .initialDelivery: return "Init.\nDel."
        case .refine:          return "Refine"
        case .proposal:        return "Proposal"
        default:               return stage.rawValue
        }
    }
}

struct MenuBarProjectRow: View {
    let project: Project

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.gruvFg)
                HStack(spacing: 4) {
                    Text(project.stage.rawValue)
                        .font(.system(size: 10))
                        .foregroundStyle(Color.gruvStageColor(for: project.stage))
                    if project.isPOC {
                        Text("· POC")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.gruvPurple)
                    }
                    if let account = project.accountName {
                        Text("· \(account)")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.gruvFgDim)
                    }
                }
            }
            Spacer()
            Image(systemName: "arrow.right")
                .font(.system(size: 10))
                .foregroundStyle(Color.gruvFgDim)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
}
```

- [ ] **Step 2: Build and run — exercise menu bar**

Cmd+R. Click the briefcase icon in the menu bar. Verify:
- Pipeline summary shows counts
- Search filters projects live
- "New Project" sheet opens and creates projects
- "Log Engagement" opens with the last-touched project pre-selected
- "Open App" brings the main window forward

- [ ] **Step 3: Commit**

```bash
git add EngagementTracker/Views/MenuBar/MenuBarPopoverView.swift
git commit -m "feat: menu bar popover with search, pipeline summary, and quick actions"
```

---

## Task 11: Settings and iCloud toggle

**Files:**
- Modify: `EngagementTracker/Views/Settings/SettingsView.swift`

- [ ] **Step 1: Write SettingsView.swift**

```swift
import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState
        Form {
            Section {
                Toggle("Sync with iCloud", isOn: Binding(
                    get: { appState.isCloudSyncEnabled },
                    set: { appState.isCloudSyncEnabled = $0 }
                ))
                Text("Enables CloudKit sync across your Macs. Restart the app after changing this setting for it to take effect. Foundation for a future iOS companion app.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            } header: {
                Text("Sync")
            }

            Section {
                LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
            } header: {
                Text("About")
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 200)
    }
}
```

- [ ] **Step 2: Build and run — open settings**

Cmd+R. Open Settings (Cmd+,). Verify the iCloud toggle is present and persists across app restarts.

- [ ] **Step 3: Commit**

```bash
git add EngagementTracker/Views/Settings/SettingsView.swift
git commit -m "feat: settings view with iCloud sync toggle"
```

---

## Task 12: Search filter tests

**Files:**
- Create: `EngagementTrackerTests/SearchFilterTests.swift`
- Create: `EngagementTrackerTests/ProjectStageTests.swift`

- [ ] **Step 1: Write ProjectStageTests.swift**

```swift
import Testing
@testable import EngagementTracker

@Suite("ProjectStage")
struct ProjectStageTests {

    @Test func stageProgression() {
        #expect(ProjectStage.discovery.next == .initialDelivery)
        #expect(ProjectStage.initialDelivery.next == .refine)
        #expect(ProjectStage.refine.next == .proposal)
        #expect(ProjectStage.proposal.next == nil)
    }

    @Test func terminalStages() {
        #expect(ProjectStage.won.isTerminal == true)
        #expect(ProjectStage.lost.isTerminal == true)
        #expect(ProjectStage.discovery.isTerminal == false)
        #expect(ProjectStage.proposal.isTerminal == false)
    }

    @Test func allCasesCount() {
        #expect(ProjectStage.allCases.count == 6)
    }
}
```

- [ ] **Step 2: Write SearchFilterTests.swift**

```swift
import Testing
@testable import EngagementTracker

@Suite("Search Filtering")
struct SearchFilterTests {

    private func makeProject(name: String, account: String? = nil, stage: ProjectStage = .discovery) -> Project {
        Project(name: name, accountName: account, stage: stage)
    }

    @Test func matchesOnName() {
        let project = makeProject(name: "Acme Corp")
        let q = "acme"
        let matches = project.name.lowercased().contains(q)
        #expect(matches == true)
    }

    @Test func matchesOnAccountName() {
        let project = makeProject(name: "Deal 001", account: "GlobalBank")
        let q = "global"
        let matches = (project.accountName?.lowercased().contains(q) ?? false)
        #expect(matches == true)
    }

    @Test func noMatchOnUnrelatedQuery() {
        let project = makeProject(name: "Acme Corp", account: "Acme")
        let q = "xyz"
        let matchesName = project.name.lowercased().contains(q)
        let matchesAccount = project.accountName?.lowercased().contains(q) ?? false
        #expect(matchesName == false)
        #expect(matchesAccount == false)
    }

    @Test func estimatedValueCentsConversion() {
        let project = Project(name: "Test", estimatedValueCents: 24000000)
        let formatted = project.estimatedValueFormatted
        #expect(formatted != nil)
        #expect(formatted!.contains("240,000") || formatted!.contains("240000"))
    }

    @Test func nilValueReturnsNilFormatted() {
        let project = Project(name: "Test", estimatedValueCents: nil)
        #expect(project.estimatedValueFormatted == nil)
    }
}
```

- [ ] **Step 3: Run all tests**

In Xcode: Cmd+U. Expected: All tests pass — CheckpointSeederTests (8), ProjectStageTests (3), SearchFilterTests (5). Total: 16 tests.

- [ ] **Step 4: Commit**

```bash
git add EngagementTrackerTests/
git commit -m "test: add stage progression and search filter unit tests"
```

---

## Self-Review Notes

**Spec coverage check:**
- ✅ Discovery → Initial Delivery → Refine → Proposal → Won/Lost lifecycle (Enums.swift + StagesSidebarView)
- ✅ POC project-level toggle (Project model + NewProjectSheet + header pill)
- ✅ External/Internal/Business Partner contacts (Contact model + AddContactSheet + ContactsTabView)
- ✅ Internal role (AE, SE, Manager, etc.) (InternalRole enum + AddContactSheet)
- ✅ Fixed/predefined checkpoints per stage (CheckpointSeeder + auto-seeded on project creation)
- ✅ Menu bar icon with quick new project + search (MenuBarPopoverView)
- ✅ Pipeline count summary in popover (MenuBarPopoverView)
- ✅ Quick engagement log (LogEngagementSheet triggered from menu bar)
- ✅ Tasks with checkbox completion (TasksTabView)
- ✅ Notes with timestamp (NotesTabView)
- ✅ Engagement log with tagged contacts (EngagementsTabView + LogEngagementSheet)
- ✅ iCloud sync opt-in (AppState.makeContainer + SettingsView)
- ✅ Gruvbox light/dark theme (GruvboxColors.swift + asset catalog)
- ✅ Advance stage button (ProjectDetailHeaderView)
- ✅ All optional fields on project (NewProjectSheet — nullable with blank/NA)

**Type consistency verified:**
- `CheckpointSeeder.makeAllCheckpoints()` used in `NewProjectSheet.save()` ✅
- `CheckpointSeeder.titles(for:)` tested directly ✅
- `Project.estimatedValueFormatted` used in `ProjectRowView` and `ProjectDetailHeaderView` ✅
- `Contact.id: UUID` used in `Engagement.contactIDs: [UUID]` ✅
- `ProjectStage.next` used in `ProjectDetailHeaderView` advance button ✅
- `Color.gruvStageColor(for:)` used throughout ✅
