import Foundation
import EventKit
import SwiftData

// MARK: - ReminderItem

/// A lightweight value type bridging an EKReminder to Charter's task model.
/// Used as an intermediate representation to keep EventKit isolated from the UI layer
/// and to enable unit testing without requiring a live EKEventStore.
struct ReminderItem {
    let title: String
    let dueDate: Date?
    let notes: String?

    init(title: String, dueDate: Date? = nil, notes: String? = nil) {
        self.title = title
        self.dueDate = dueDate
        self.notes = notes
    }

    init(from reminder: EKReminder) {
        let rawTitle = reminder.title ?? ""
        let trimmed = rawTitle.trimmingCharacters(in: .whitespaces)
        self.title = trimmed.isEmpty ? "Untitled Reminder" : trimmed
        self.dueDate = reminder.dueDateComponents?.date
        self.notes = reminder.notes
    }
}

// MARK: - RemindersService

/// Manages access to Apple Reminders via EventKit.
///
/// Use `requestAccess()` to prompt the user for permission, then call
/// `fetchPendingReminders(fromListWithID:)` to retrieve incomplete reminders
/// from a chosen list. Call `createTasks(from:into:context:)` to persist them
/// as `ProjectTask` objects in the SwiftData store.
@Observable
@MainActor
final class RemindersService {
    static let shared = RemindersService()

    private let eventStore = EKEventStore()

    private(set) var authorizationStatus: EKAuthorizationStatus = .notDetermined
    private(set) var availableLists: [EKCalendar] = []

    private init() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
        if authorizationStatus == .fullAccess {
            loadAvailableLists()
        }
    }

    // MARK: Authorization

    var isAuthorized: Bool {
        authorizationStatus == .fullAccess
    }

    func requestAccess() async {
        do {
            let granted = try await eventStore.requestFullAccessToReminders()
            authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
            if granted {
                loadAvailableLists()
            }
        } catch {
            authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
        }
    }

    // MARK: List Discovery

    func loadAvailableLists() {
        availableLists = eventStore.calendars(for: .reminder)
            .sorted { $0.title < $1.title }
    }

    // MARK: Fetching Reminders

    /// Fetches all incomplete reminders from the given list identifier.
    func fetchPendingReminders(fromListWithID listID: String) async -> [ReminderItem] {
        let calendars = eventStore.calendars(for: .reminder)
            .filter { $0.calendarIdentifier == listID }
        guard !calendars.isEmpty else { return [] }

        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: nil,
            ending: nil,
            calendars: calendars
        )

        return await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                let items = (reminders ?? []).map { ReminderItem(from: $0) }
                continuation.resume(returning: items)
            }
        }
    }

    // MARK: Import

    /// Imports incomplete reminders from the given list into the project as tasks.
    /// Reminders whose title already exists among the project's tasks are skipped.
    /// Returns the number of new tasks created.
    @discardableResult
    func importPendingReminders(
        fromListWithID listID: String,
        into project: Project,
        context: ModelContext,
        markCompleted: Bool
    ) async -> Int {
        let items = await fetchPendingReminders(fromListWithID: listID)
        guard !items.isEmpty else { return 0 }

        let existingTitles = Set(project.tasks.map(\.title))
        let newItems = items.filter { !existingTitles.contains($0.title) }

        for item in newItems {
            let task = ProjectTask(title: item.title, dueDate: item.dueDate)
            context.insert(task)
            project.tasks.append(task)
        }

        if !newItems.isEmpty {
            project.updatedAt = Date()
            try? context.save()
        }

        if markCompleted {
            await markAllRemindersCompleted(inListWithID: listID)
        }

        return newItems.count
    }

    // MARK: Mark Completed

    /// Marks all incomplete reminders in the specified list as completed.
    func markAllRemindersCompleted(inListWithID listID: String) async {
        let calendars = eventStore.calendars(for: .reminder)
            .filter { $0.calendarIdentifier == listID }
        guard !calendars.isEmpty else { return }

        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: nil,
            ending: nil,
            calendars: calendars
        )

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            eventStore.fetchReminders(matching: predicate) { [weak self] reminders in
                guard let self else {
                    continuation.resume()
                    return
                }
                var saveError: Error?
                for reminder in reminders ?? [] {
                    reminder.isCompleted = true
                    do {
                        try self.eventStore.save(reminder, commit: false)
                    } catch {
                        saveError = error
                    }
                }
                if saveError == nil {
                    do {
                        try self.eventStore.commit()
                    } catch {
                        saveError = error
                    }
                }
                if let saveError {
                    print("[RemindersService] Failed to mark reminders completed: \(saveError)")
                }
                continuation.resume()
            }
        }
    }
}
