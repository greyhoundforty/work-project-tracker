import Foundation
import Testing
@testable import Charter

@Suite("ProjectTask")
struct ProjectTaskTests {

    @Test("init creates uncompleted task with correct properties and no dueDate")
    func initDefaults() {
        let task = ProjectTask(title: "Send BOM")
        #expect(task.title == "Send BOM")
        #expect(task.isCompleted == false)
        #expect(task.completedAt == nil)
        #expect(task.dueDate == nil)
    }

    @Test("init with dueDate stores dueDate")
    func initWithDueDate() {
        let due = Date(timeIntervalSince1970: 1_000_000)
        let task = ProjectTask(title: "Follow up", dueDate: due)
        #expect(task.dueDate == due)
    }

    @Test("each task gets a unique id")
    func uniqueIDs() {
        let t1 = ProjectTask(title: "Task A")
        let t2 = ProjectTask(title: "Task B")
        #expect(t1.id != t2.id)
    }

    @Test("toggle marks task as completed and sets completedAt")
    func toggleToCompleted() {
        let task = ProjectTask(title: "Send BOM")
        task.toggle()
        #expect(task.isCompleted == true)
        #expect(task.completedAt != nil)
    }

    @Test("toggle twice restores task to uncompleted and clears completedAt")
    func toggleTwiceResetsState() {
        let task = ProjectTask(title: "Send BOM")
        task.toggle()
        task.toggle()
        #expect(task.isCompleted == false)
        #expect(task.completedAt == nil)
    }

    @Test("completedAt is set to a recent timestamp when toggled to completed")
    func completedAtIsRecent() {
        let before = Date()
        let task = ProjectTask(title: "Review proposal")
        task.toggle()
        let after = Date()
        #expect(task.completedAt != nil)
        if let completedAt = task.completedAt {
            #expect(completedAt >= before)
            #expect(completedAt <= after)
        }
    }

    @Test("createdAt is set on init")
    func createdAtIsSet() {
        let before = Date()
        let task = ProjectTask(title: "Test")
        let after = Date()
        #expect(task.createdAt >= before)
        #expect(task.createdAt <= after)
    }
}
