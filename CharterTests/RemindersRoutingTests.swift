import Foundation
import Testing
@testable import Charter

@Suite("RemindersRouting")
struct RemindersRoutingTests {

    @Test("Charter: line in notes wins; task title is reminder title")
    func notesCharterLine() {
        let r = RemindersRouting.parse(
            title: "Call client",
            notes: "Charter: acme\nother note"
        )
        #expect(r?.normalizedCode == "acme")
        #expect(r?.taskTitle == "Call client")
    }

    @Test("charter: prefix is case-insensitive")
    func notesCharterCaseInsensitive() {
        let r = RemindersRouting.parse(
            title: "Task",
            notes: "CHARTER: Foo-Bar"
        )
        #expect(r?.normalizedCode == "foo-bar")
        #expect(r?.taskTitle == "Task")
    }

    @Test("first non-empty notes line must be Charter: or notes routing is skipped")
    func notesFirstLineBlocksWhenNotCharter() {
        let r = RemindersRouting.parse(
            title: "Plain title",
            notes: "Some other line\nCharter: acme"
        )
        #expect(r == nil)
    }

    @Test("title bracket prefix strips code and remainder becomes task title")
    func titleBracket() {
        let r = RemindersRouting.parse(
            title: "[ACME] Follow up",
            notes: nil
        )
        #expect(r?.normalizedCode == "acme")
        #expect(r?.taskTitle == "Follow up")
    }

    @Test("title hash prefix")
    func titleHash() {
        let r = RemindersRouting.parse(
            title: "#vip Ship v1",
            notes: nil
        )
        #expect(r?.normalizedCode == "vip")
        #expect(r?.taskTitle == "Ship v1")
    }

    @Test("hash with code only uses Reminder placeholder title")
    func hashOnlyCode() {
        let r = RemindersRouting.parse(
            title: "#acme",
            notes: nil
        )
        #expect(r?.normalizedCode == "acme")
        #expect(r?.taskTitle == "Reminder")
    }

    @Test("empty code after Charter: ignores notes line; title bracket still parses")
    func emptyCodeAfterCharterFallsBackToTitle() {
        let rNotes = RemindersRouting.parse(
            title: "[z] Do it",
            notes: "Charter:  \n"
        )
        #expect(rNotes?.normalizedCode == "z")
        #expect(rNotes?.taskTitle == "Do it")

        let rBracket = RemindersRouting.parse(
            title: "[z] Do it",
            notes: "Charter:  "
        )
        #expect(rBracket?.normalizedCode == "z")
    }

    @Test("no routing yields nil")
    func noMatch() {
        #expect(RemindersRouting.parse(title: "Just a task", notes: nil) == nil)
        #expect(RemindersRouting.parse(title: "  ", notes: "also empty") == nil)
    }

    @Test("notes Charter with empty reminder title still yields a task title")
    func emptyReminderTitleWithNotesCode() {
        let r = RemindersRouting.parse(
            title: "   ",
            notes: "Charter: p1"
        )
        #expect(r?.normalizedCode == "p1")
        #expect(r?.taskTitle == "Reminder")
    }
}
