import Testing
import Foundation
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
