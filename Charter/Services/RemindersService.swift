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
    /// `EKReminder.calendarItemIdentifier` for selective completion after import.
    let calendarItemIdentifier: String

    init(title: String, dueDate: Date? = nil, notes: String? = nil, calendarItemIdentifier: String = "") {
        self.title = title
        self.dueDate = dueDate
        self.notes = notes
        self.calendarItemIdentifier = calendarItemIdentifier
    }

    init(from reminder: EKReminder) {
        let rawTitle = reminder.title ?? ""
        let trimmed = rawTitle.trimmingCharacters(in: .whitespaces)
        self.title = trimmed.isEmpty ? "Untitled Reminder" : trimmed
        self.dueDate = reminder.dueDateComponents?.date
        self.notes = reminder.notes
        self.calendarItemIdentifier = reminder.calendarItemIdentifier
    }
}

// MARK: - Routed import

struct RoutedImportSummary: Equatable, Sendable {
    var importedCount: Int = 0
    var skippedDuplicateTitleCount: Int = 0
    /// Normalized reminder codes with no matching `Project.remindersCode`.
    var unknownCodes: [String] = []
    /// Normalized codes that map to more than one project.
    var ambiguousCodes: [String] = []
    /// Reminder titles that had no routing token (notes/title).
    var unparseableTitles: [String] = []

    /// User-facing summary for alerts and settings.
    var formattedReport: String {
        var lines: [String] = []
        lines.append("Imported \(importedCount) task\(importedCount == 1 ? "" : "s").")
        if skippedDuplicateTitleCount > 0 {
            lines.append("Skipped \(skippedDuplicateTitleCount) (title already exists in project).")
        }
        if !unknownCodes.isEmpty {
            lines.append("Unknown code(s): \(unknownCodes.sorted().joined(separator: ", ")) — set a matching Reminders code on a project.")
        }
        if !ambiguousCodes.isEmpty {
            lines.append("Ambiguous code(s) (more than one project): \(ambiguousCodes.sorted().joined(separator: ", ")).")
        }
        if !unparseableTitles.isEmpty {
            let sample = unparseableTitles.prefix(8)
            let extra = unparseableTitles.count > 8 ? " (+\(unparseableTitles.count - 8) more)" : ""
            lines.append("No routing tag: \(sample.joined(separator: "; "))\(extra)")
        }
        if lines.count == 1, importedCount == 0, skippedDuplicateTitleCount == 0,
           unknownCodes.isEmpty, ambiguousCodes.isEmpty, unparseableTitles.isEmpty {
            return "No matching reminders to import."
        }
        return lines.joined(separator: "\n")
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
            task.project = project
            context.insert(task)
            project.tasks.append(task)
        }

        if !newItems.isEmpty {
            project.updatedAt = Date()
            try? context.save()
        }

        if markCompleted {
            let ids = newItems.map(\.calendarItemIdentifier).filter { !$0.isEmpty }
            await markRemindersCompleted(calendarItemIdentifiers: ids)
        }

        return newItems.count
    }

    /// Imports incomplete reminders from the inbox list, routes each to a project by `remindersCode`, and creates tasks.
    @discardableResult
    func importRoutedPendingReminders(
        fromListWithID listID: String,
        projects: [Project],
        context: ModelContext,
        markImportedRemindersCompleted: Bool,
        appState: AppState?
    ) async -> RoutedImportSummary {
        var summary = RoutedImportSummary()
        let items = await fetchPendingReminders(fromListWithID: listID)
        guard !items.isEmpty else { return summary }

        let codeMap = Self.projectsByNormalizedReminderCode(projects.filter(\.isActive))
        var completedIDs: [String] = []
        var touchedProjects: Set<ObjectIdentifier> = []

        for item in items {
            guard let route = RemindersRouting.parse(title: item.title, notes: item.notes) else {
                summary.unparseableTitles.append(item.title)
                continue
            }

            let matches = codeMap[route.normalizedCode] ?? []
            if matches.count > 1 {
                if !summary.ambiguousCodes.contains(route.normalizedCode) {
                    summary.ambiguousCodes.append(route.normalizedCode)
                }
                continue
            }
            guard let project = matches.first else {
                if !summary.unknownCodes.contains(route.normalizedCode) {
                    summary.unknownCodes.append(route.normalizedCode)
                }
                continue
            }

            let existingTitles = Set(project.tasks.map(\.title))
            if existingTitles.contains(route.taskTitle) {
                summary.skippedDuplicateTitleCount += 1
                continue
            }

            let task = ProjectTask(title: route.taskTitle, dueDate: item.dueDate)
            task.project = project
            context.insert(task)
            project.tasks.append(task)
            project.updatedAt = Date()
            touchedProjects.insert(ObjectIdentifier(project))
            summary.importedCount += 1
            if !item.calendarItemIdentifier.isEmpty {
                completedIDs.append(item.calendarItemIdentifier)
            }
        }

        if summary.importedCount > 0 {
            try? context.save()
        }

        if markImportedRemindersCompleted {
            await markRemindersCompleted(calendarItemIdentifiers: completedIDs)
        }

        if let appState, VaultService.isVaultConfigured(appState) {
            for p in projects where touchedProjects.contains(ObjectIdentifier(p)) {
                try? VaultService.mirrorAllTasksToVault(project: p, appState: appState)
            }
        }

        return summary
    }

    // MARK: - Mark completed (selective)

    /// Marks only the reminders with the given EventKit identifiers complete.
    func markRemindersCompleted(calendarItemIdentifiers: [String]) async {
        let ids = Array(Set(calendarItemIdentifiers.filter { !$0.isEmpty }))
        guard !ids.isEmpty else { return }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            var saveError: Error?
            for id in ids {
                guard let reminder = eventStore.calendarItem(withIdentifier: id) as? EKReminder else { continue }
                reminder.isCompleted = true
                do {
                    try eventStore.save(reminder, commit: false)
                } catch {
                    saveError = error
                }
            }
            if saveError == nil {
                do {
                    try eventStore.commit()
                } catch {
                    saveError = error
                }
            }
            if let saveError {
                print("[RemindersService] Failed to mark selected reminders completed: \(saveError)")
            }
            continuation.resume()
        }
    }

    private static func projectsByNormalizedReminderCode(_ projects: [Project]) -> [String: [Project]] {
        var map: [String: [Project]] = [:]
        for p in projects {
            guard let raw = p.remindersCode?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { continue }
            let key = raw.lowercased()
            map[key, default: []].append(p)
        }
        return map
    }
}
