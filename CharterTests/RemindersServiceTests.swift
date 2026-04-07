import Foundation
import Testing
@testable import Charter

@Suite("ReminderItem")
struct RemindersServiceTests {

    // MARK: - Initialisation

    @Test("init stores title, dueDate, and notes")
    func initStoresAllProperties() {
        let due = Date(timeIntervalSince1970: 2_000_000)
        let item = ReminderItem(title: "Send proposal", dueDate: due, notes: "Check pricing first")
        #expect(item.title == "Send proposal")
        #expect(item.dueDate == due)
        #expect(item.notes == "Check pricing first")
        #expect(item.calendarItemIdentifier.isEmpty)
    }

    @Test("init can store calendarItemIdentifier")
    func initStoresCalendarId() {
        let item = ReminderItem(title: "T", calendarItemIdentifier: "id-123")
        #expect(item.calendarItemIdentifier == "id-123")
    }

    @Test("init with no dueDate stores nil")
    func initWithNilDueDate() {
        let item = ReminderItem(title: "Call client")
        #expect(item.title == "Call client")
        #expect(item.dueDate == nil)
        #expect(item.notes == nil)
    }

    @Test("init preserves exact title without modification")
    func initPreservesTitle() {
        let item = ReminderItem(title: "  Review BOM  ")
        #expect(item.title == "  Review BOM  ")
    }

    // MARK: - Deduplication

    @Test("deduplication skips reminders already present in the project")
    func deduplicationFiltersExisting() {
        let existing = Set(["Buy milk", "Send report"])
        let incoming = [
            ReminderItem(title: "Buy milk"),
            ReminderItem(title: "New task"),
            ReminderItem(title: "Send report"),
        ]
        let newItems = incoming.filter { !existing.contains($0.title) }
        #expect(newItems.count == 1)
        #expect(newItems[0].title == "New task")
    }

    @Test("deduplication with no existing tasks imports all reminders")
    func deduplicationWithEmptyProject() {
        let existing = Set<String>()
        let incoming = [
            ReminderItem(title: "Task A"),
            ReminderItem(title: "Task B"),
        ]
        let newItems = incoming.filter { !existing.contains($0.title) }
        #expect(newItems.count == 2)
    }

    @Test("deduplication with all matching titles imports nothing")
    func deduplicationAllExisting() {
        let existing = Set(["Task A", "Task B"])
        let incoming = [
            ReminderItem(title: "Task A"),
            ReminderItem(title: "Task B"),
        ]
        let newItems = incoming.filter { !existing.contains($0.title) }
        #expect(newItems.isEmpty)
    }

    @Test("empty reminder list produces no imports")
    func emptyReminderListProducesNoImports() {
        let items: [ReminderItem] = []
        let existing = Set(["Existing task"])
        let newItems = items.filter { !existing.contains($0.title) }
        #expect(newItems.isEmpty)
    }

    // MARK: - ProjectTask creation from ReminderItem

    @Test("ProjectTask created from ReminderItem inherits title and dueDate")
    func projectTaskFromReminderItem() {
        let due = Date(timeIntervalSince1970: 3_000_000)
        let item = ReminderItem(title: "Prepare slides", dueDate: due)
        let task = ProjectTask(title: item.title, dueDate: item.dueDate)
        #expect(task.title == "Prepare slides")
        #expect(task.dueDate == due)
        #expect(task.isCompleted == false)
    }

    @Test("ProjectTask created from ReminderItem with no dueDate has nil dueDate")
    func projectTaskNoDueDate() {
        let item = ReminderItem(title: "Follow up")
        let task = ProjectTask(title: item.title, dueDate: item.dueDate)
        #expect(task.dueDate == nil)
    }

    // MARK: - Import count calculation

    @Test("RoutedImportSummary formattedReport explains empty import")
    func routedSummaryEmpty() {
        let s = RoutedImportSummary()
        #expect(s.formattedReport == "No matching reminders to import.")
    }

    @Test("RoutedImportSummary formattedReport lists issues")
    func routedSummaryWithIssues() {
        var s = RoutedImportSummary()
        s.importedCount = 2
        s.unknownCodes = ["zap"]
        s.unparseableTitles = ["Plain task"]
        let r = s.formattedReport
        #expect(r.contains("Imported 2 tasks"))
        #expect(r.contains("Unknown code"))
        #expect(r.contains("zap"))
        #expect(r.contains("Plain task"))
    }

    @Test("import count equals number of new items created")
    func importCountMatchesNewItems() {
        let existing = Set(["Old task"])
        let incoming = [
            ReminderItem(title: "Old task"),
            ReminderItem(title: "Fresh task 1"),
            ReminderItem(title: "Fresh task 2"),
        ]
        let newItems = incoming.filter { !existing.contains($0.title) }
        #expect(newItems.count == 2)
    }
}
