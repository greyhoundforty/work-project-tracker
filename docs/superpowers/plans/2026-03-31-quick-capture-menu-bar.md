# Quick-Capture Menu Bar Integration — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the "New Project" / "Log Engagement" button row in the menu bar popover with a fully inline quick-capture UI supporting engagement log, task, and note creation — all without opening the main app window.

**Architecture:** A new `QuickCaptureView` component owns all capture state and three free-function save helpers (`makeEngagement`, `makeProjectTask`, `makeNote`) that are independently testable without a `ModelContext`. `MenuBarPopoverView` embeds `QuickCaptureView` in place of the old button row; "New Project" moves to the footer as a sheet trigger.

**Tech Stack:** SwiftUI, SwiftData (macOS 14+), Swift Testing framework, xcodegen

---

## File Map

| Path | Status | Responsibility |
|------|--------|----------------|
| `EngagementTracker/Views/MenuBar/QuickCaptureView.swift` | Create | `CaptureType` enum, 3 save helpers, full view body |
| `EngagementTracker/Views/MenuBar/MenuBarPopoverView.swift` | Modify | Remove old sheet state, embed `QuickCaptureView`, move New Project to footer |
| `EngagementTrackerTests/QuickCaptureTests.swift` | Create | Unit tests for save helpers |

No changes to models, services, app entry point, or any other views.

> After adding new Swift files, always run `xcodegen generate` before building — the project uses xcodegen for `.xcodeproj` management and picks up new files by directory scan.

---

### Task 1: Write failing tests for save helpers

**Files:**
- Create: `EngagementTrackerTests/QuickCaptureTests.swift`

The save helpers don't exist yet — this file will fail to compile until Task 2. That's the expected "failing" state.

- [ ] **Step 1: Create the test file**

```swift
// EngagementTrackerTests/QuickCaptureTests.swift
import Testing
@testable import EngagementTracker

@Suite("QuickCapture save helpers")
struct QuickCaptureTests {

    // MARK: - makeEngagement

    @Test("engagement gets correct summary and date")
    func engagementProperties() {
        let project = Project(name: "Acme")
        let date = Date(timeIntervalSinceReferenceDate: 0)
        let e = makeEngagement(summary: "Met with client", date: date, for: project)
        #expect(e.summary == "Met with client")
        #expect(e.date == date)
    }

    @Test("makeEngagement bumps project.updatedAt")
    func engagementBumpsUpdatedAt() async throws {
        let project = Project(name: "Acme")
        let before = project.updatedAt
        try await Task.sleep(nanoseconds: 5_000_000)
        _ = makeEngagement(summary: "x", date: Date(), for: project)
        #expect(project.updatedAt > before)
    }

    // MARK: - makeProjectTask

    @Test("task gets correct title, nil dueDate by default")
    func taskNoDueDate() {
        let project = Project(name: "Acme")
        let t = makeProjectTask(title: "Send BOM", dueDate: nil, for: project)
        #expect(t.title == "Send BOM")
        #expect(t.dueDate == nil)
        #expect(t.isCompleted == false)
    }

    @Test("task gets correct title and dueDate when provided")
    func taskWithDueDate() {
        let project = Project(name: "Acme")
        let due = Date(timeIntervalSinceReferenceDate: 86400)
        let t = makeProjectTask(title: "Follow up", dueDate: due, for: project)
        #expect(t.title == "Follow up")
        #expect(t.dueDate == due)
    }

    @Test("makeProjectTask bumps project.updatedAt")
    func taskBumpsUpdatedAt() async throws {
        let project = Project(name: "Acme")
        let before = project.updatedAt
        try await Task.sleep(nanoseconds: 5_000_000)
        _ = makeProjectTask(title: "x", dueDate: nil, for: project)
        #expect(project.updatedAt > before)
    }

    // MARK: - makeNote

    @Test("note gets correct content, nil title when title is nil")
    func noteNilTitle() {
        let project = Project(name: "Acme")
        let n = makeNote(title: nil, content: "Meeting notes here", for: project)
        #expect(n.content == "Meeting notes here")
        #expect(n.title == nil)
    }

    @Test("note gets correct content and title when title is provided")
    func noteWithTitle() {
        let project = Project(name: "Acme")
        let n = makeNote(title: "Q1 Review", content: "Key points discussed", for: project)
        #expect(n.title == "Q1 Review")
        #expect(n.content == "Key points discussed")
    }

    @Test("makeNote bumps project.updatedAt")
    func noteBumpsUpdatedAt() async throws {
        let project = Project(name: "Acme")
        let before = project.updatedAt
        try await Task.sleep(nanoseconds: 5_000_000)
        _ = makeNote(title: nil, content: "x", for: project)
        #expect(project.updatedAt > before)
    }
}
```

- [ ] **Step 2: Regenerate Xcode project and confirm compilation failure**

```bash
cd /Users/ryan/claude-projects/worktrees/feat-quick-capture-menu-bar-tl4
xcodegen generate
xcodebuild build -project EngagementTracker.xcodeproj -scheme EngagementTracker -destination 'platform=macOS,arch=arm64' 2>&1 | grep "error:"
```

Expected: errors like `use of unresolved identifier 'makeEngagement'`

---

### Task 2: Implement `CaptureType` enum and save helpers

**Files:**
- Create: `EngagementTracker/Views/MenuBar/QuickCaptureView.swift` (partial — enum + helpers + stub view)

- [ ] **Step 1: Create the file**

```swift
// EngagementTracker/Views/MenuBar/QuickCaptureView.swift
import SwiftUI
import SwiftData

// MARK: - CaptureType

enum CaptureType: String, CaseIterable, Identifiable {
    case engagement = "Engagement"
    case task = "Task"
    case note = "Note"
    var id: String { rawValue }
}

// MARK: - Save helpers (free functions — testable without ModelContext)

/// Creates an Engagement with the given properties and bumps project.updatedAt.
/// Caller is responsible for calling modelContext.insert() on the returned value.
func makeEngagement(summary: String, date: Date, for project: Project) -> Engagement {
    let e = Engagement(date: date, summary: summary)
    project.updatedAt = Date()
    return e
}

/// Creates a ProjectTask with the given properties and bumps project.updatedAt.
/// Caller is responsible for calling modelContext.insert() on the returned value.
func makeProjectTask(title: String, dueDate: Date?, for project: Project) -> ProjectTask {
    let t = ProjectTask(title: title, dueDate: dueDate)
    project.updatedAt = Date()
    return t
}

/// Creates a Note with the given properties and bumps project.updatedAt.
/// Caller is responsible for calling modelContext.insert() on the returned value.
func makeNote(title: String?, content: String, for project: Project) -> Note {
    let n = Note(title: title, content: content)
    project.updatedAt = Date()
    return n
}

// MARK: - QuickCaptureView (stub — implemented in Task 3)

struct QuickCaptureView: View {
    var body: some View { EmptyView() }
}
```

- [ ] **Step 2: Regenerate project and run tests**

```bash
cd /Users/ryan/claude-projects/worktrees/feat-quick-capture-menu-bar-tl4
xcodegen generate
xcodebuild test -project EngagementTracker.xcodeproj -scheme EngagementTracker -destination 'platform=macOS,arch=arm64' 2>&1 | grep -E "(Test Suite|✓|✗|PASSED|FAILED|error:)"
```

Expected: all 9 tests in `QuickCaptureTests` pass, all pre-existing tests still pass.

- [ ] **Step 3: Commit**

```bash
git add EngagementTracker/Views/MenuBar/QuickCaptureView.swift EngagementTrackerTests/QuickCaptureTests.swift
git commit -m "feat: add CaptureType enum and save helpers with tests"
```

---

### Task 3: Implement `QuickCaptureView` body

**Files:**
- Modify: `EngagementTracker/Views/MenuBar/QuickCaptureView.swift` (replace stub body with full implementation)

- [ ] **Step 1: Replace the `QuickCaptureView` stub with the full implementation**

Replace only the `struct QuickCaptureView` at the bottom of the file (everything from `// MARK: - QuickCaptureView` to the end) with:

```swift
// MARK: - QuickCaptureView

struct QuickCaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.updatedAt, order: .reverse) private var allProjects: [Project]

    @State private var captureType: CaptureType = .engagement
    @State private var selectedProject: Project?
    @State private var showProjectPicker = false

    // Engagement fields
    @State private var summary = ""
    @State private var engagementDate = Date()

    // Task fields
    @State private var taskTitle = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()

    // Note fields
    @State private var noteTitle = ""
    @State private var noteContent = ""

    private var activeProjects: [Project] { allProjects.filter(\.isActive) }

    private var canSave: Bool {
        guard selectedProject != nil else { return false }
        switch captureType {
        case .engagement: return !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .task:       return !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .note:       return !noteContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Zone 1: Type selector
            Picker("Capture type", selection: $captureType) {
                ForEach(CaptureType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .padding(.bottom, 8)

            // Zone 2: Form fields
            Group {
                switch captureType {
                case .engagement:
                    VStack(alignment: .leading, spacing: 6) {
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $summary)
                                .font(.system(size: 12))
                                .frame(height: 60)
                                .scrollContentBackground(.hidden)
                                .background(Color.themeBg1)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            if summary.isEmpty {
                                Text("Summary…")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.themeFgDim)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 8)
                                    .allowsHitTesting(false)
                            }
                        }
                        DatePicker("Date", selection: $engagementDate, displayedComponents: .date)
                            .font(.system(size: 12))
                            .datePickerStyle(.compact)
                    }

                case .task:
                    VStack(alignment: .leading, spacing: 6) {
                        TextField("Title", text: $taskTitle)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                            .padding(6)
                            .background(Color.themeBg1)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Toggle("Add due date", isOn: $hasDueDate)
                            .font(.system(size: 12))
                        if hasDueDate {
                            DatePicker("Due", selection: $dueDate,
                                       displayedComponents: [.date, .hourAndMinute])
                                .font(.system(size: 12))
                                .datePickerStyle(.compact)
                        }
                    }

                case .note:
                    VStack(alignment: .leading, spacing: 6) {
                        TextField("Title (optional)", text: $noteTitle)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                            .padding(6)
                            .background(Color.themeBg1)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $noteContent)
                                .font(.system(size: 12))
                                .frame(height: 60)
                                .scrollContentBackground(.hidden)
                                .background(Color.themeBg1)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            if noteContent.isEmpty {
                                Text("Content…")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.themeFgDim)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 8)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 10)

            // Zone 3: Project row + Save
            HStack(spacing: 8) {
                if showProjectPicker {
                    Picker("Project", selection: $selectedProject) {
                        ForEach(activeProjects) { project in
                            Text(project.name).tag(Optional(project))
                        }
                    }
                    .pickerStyle(.menu)
                    .font(.system(size: 12))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: selectedProject) { _, _ in
                        showProjectPicker = false
                    }
                } else {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.themeStageColor(for: selectedProject?.stage ?? .discovery))
                            .frame(width: 7, height: 7)
                        Text(selectedProject?.name ?? "No project")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.themeFg)
                            .lineLimit(1)
                        Text(selectedProject?.stage.rawValue ?? "")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.themeFgDim)
                            .lineLimit(1)
                        Button("change") {
                            showProjectPicker = true
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 10))
                        .foregroundStyle(Color.themeBlue)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button("Save") {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.themeAqua)
                .disabled(!canSave)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .onAppear {
            if selectedProject == nil {
                selectedProject = activeProjects.first
            }
        }
    }

    private func save() {
        guard let project = selectedProject else { return }
        switch captureType {
        case .engagement:
            let e = makeEngagement(summary: summary, date: engagementDate, for: project)
            e.project = project
            modelContext.insert(e)
            summary = ""
            engagementDate = Date()
        case .task:
            let t = makeProjectTask(title: taskTitle, dueDate: hasDueDate ? dueDate : nil, for: project)
            t.project = project
            modelContext.insert(t)
            taskTitle = ""
            hasDueDate = false
            dueDate = Date()
        case .note:
            let trimmedTitle = noteTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            let n = makeNote(
                title: trimmedTitle.isEmpty ? nil : trimmedTitle,
                content: noteContent,
                for: project
            )
            n.project = project
            modelContext.insert(n)
            noteTitle = ""
            noteContent = ""
        }
    }
}
```

- [ ] **Step 2: Regenerate project and build**

```bash
cd /Users/ryan/claude-projects/worktrees/feat-quick-capture-menu-bar-tl4
xcodegen generate
xcodebuild build -project EngagementTracker.xcodeproj -scheme EngagementTracker -destination 'platform=macOS,arch=arm64' 2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED|error:)"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Run tests to confirm all pass**

```bash
xcodebuild test -project EngagementTracker.xcodeproj -scheme EngagementTracker -destination 'platform=macOS,arch=arm64' 2>&1 | grep -E "(Test Suite|✓|✗|PASSED|FAILED|error:)"
```

Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add EngagementTracker/Views/MenuBar/QuickCaptureView.swift
git commit -m "feat: implement QuickCaptureView with segmented picker and inline forms"
```

---

### Task 4: Update `MenuBarPopoverView`

**Files:**
- Modify: `EngagementTracker/Views/MenuBar/MenuBarPopoverView.swift`

Changes: remove `showLogEngagement` state + both `.sheet()` modifiers; replace quick-actions `HStack` with `QuickCaptureView()`; add "New Project" `+` button to footer with its own `showNewProject` state and `.sheet()`.

- [ ] **Step 1: Replace the full content of `MenuBarPopoverView.swift`**

```swift
// EngagementTracker/Views/MenuBar/MenuBarPopoverView.swift
import SwiftUI
import SwiftData

struct MenuBarPopoverView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openSettings) private var openSettings
    @Query(sort: \Project.updatedAt, order: .reverse) private var allProjects: [Project]

    @State private var showNewProject = false

    private var activeProjects: [Project] { allProjects.filter(\.isActive) }

    private var filtered: [Project] {
        guard !appState.searchQuery.isEmpty else { return [] }
        let q = appState.searchQuery.lowercased()
        return activeProjects.filter {
            $0.name.lowercased().contains(q) ||
            ($0.accountName?.lowercased().contains(q) ?? false) ||
            $0.tags.contains { $0.lowercased().contains(q) } ||
            $0.stage.rawValue.lowercased().contains(q)
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
                    .foregroundStyle(Color.themeFgDim)
                TextField("Search projects…", text: $appState.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                if !appState.searchQuery.isEmpty {
                    Button {
                        appState.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.themeFgDim)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color.themeBg1)

            Divider()

            if !appState.searchQuery.isEmpty {
                // Search results
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if filtered.isEmpty {
                            Text("No results")
                                .foregroundStyle(Color.themeFgDim)
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
                // Quick capture
                QuickCaptureView()

                Divider()

                // Pipeline summary
                VStack(alignment: .leading, spacing: 6) {
                    Text("PIPELINE")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.themeFgDim)
                        .padding(.horizontal, 10)
                        .padding(.top, 8)

                    HStack(spacing: 6) {
                        ForEach(pipelineStages) { stage in
                            VStack(spacing: 2) {
                                Text("\(count(for: stage))")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(Color.themeStageColor(for: stage))
                                Text(stageAbbrev(stage))
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color.themeFgDim)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.themeBg1)
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
                            .foregroundStyle(Color.themeFgDim)
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
                .foregroundStyle(Color.themeBlue)
                Spacer()
                Button {
                    showNewProject = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color.themeFgDim)
                }
                .buttonStyle(.plain)
                .help("New Project")
                Button {
                    openSettings()
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(Color.themeFgDim)
                }
                .buttonStyle(.plain)
                Button("Quit") { NSApp.terminate(nil) }
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.themeFgDim)
            }
            .padding(10)
            .background(Color.themeBg1)
        }
        .background(Color.themeBg)
        .frame(width: 320)
        .sheet(isPresented: $showNewProject) {
            NewProjectSheet()
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
                    .foregroundStyle(Color.themeFg)
                HStack(spacing: 4) {
                    Text(project.stage.rawValue)
                        .font(.system(size: 10))
                        .foregroundStyle(Color.themeStageColor(for: project.stage))
                    if project.isPOC {
                        Text("· POC")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.themePurple)
                    }
                    if let account = project.accountName {
                        Text("· \(account)")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.themeFgDim)
                    }
                }
            }
            Spacer()
            Image(systemName: "arrow.right")
                .font(.system(size: 10))
                .foregroundStyle(Color.themeFgDim)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
}
```

- [ ] **Step 2: Regenerate project and build**

```bash
cd /Users/ryan/claude-projects/worktrees/feat-quick-capture-menu-bar-tl4
xcodegen generate
xcodebuild build -project EngagementTracker.xcodeproj -scheme EngagementTracker -destination 'platform=macOS,arch=arm64' 2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED|error:)"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Run full test suite**

```bash
xcodebuild test -project EngagementTracker.xcodeproj -scheme EngagementTracker -destination 'platform=macOS,arch=arm64' 2>&1 | grep -E "(Test Suite|✓|✗|PASSED|FAILED|error:)"
```

Expected: all tests pass (QuickCaptureTests + all pre-existing tests).

- [ ] **Step 4: Commit**

```bash
git add EngagementTracker/Views/MenuBar/MenuBarPopoverView.swift
git commit -m "feat: integrate QuickCaptureView into menu bar, move New Project to footer

Closes #4"
```
