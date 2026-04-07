import Foundation

/// Parses a single Reminders inbox item to determine which Charter `Project` it targets.
enum RemindersRouting {

    struct ParsedRoute: Equatable, Sendable {
        /// Lowercased, trimmed; use for lookup against `Project.remindersCode`.
        let normalizedCode: String
        /// Title for `ProjectTask` (routing markers stripped from the reminder title when using title-based routing).
        let taskTitle: String
    }

    /// Parses routing from Apple Reminders title and notes.
    ///
    /// Priority: (1) first non-empty notes line `Charter: <code>`, (2) title `[CODE] rest`, (3) title `#code rest`.
    static func parse(title rawTitle: String, notes: String?) -> ParsedRoute? {
        let titleTrimmed = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if let fromNotes = parseNotesCharterLine(notes, reminderTitle: titleTrimmed) {
            return fromNotes
        }
        return parseTitleBracketOrHash(titleTrimmed)
    }

    // MARK: - Private

    private static func parseNotesCharterLine(_ notes: String?, reminderTitle: String) -> ParsedRoute? {
        guard let notes, !notes.isEmpty else { return nil }
        for line in notes.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = String(line).trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            guard trimmed.lowercased().hasPrefix("charter:") else {
                // First non-empty line that isn't Charter: — stop scanning notes for routing
                return nil
            }
            let after = trimmed.dropFirst("charter:".count).trimmingCharacters(in: .whitespaces)
            let normalized = normalizeCode(after)
            guard !normalized.isEmpty else { return nil }
            let displayTitle = reminderTitle.isEmpty ? "Reminder" : reminderTitle
            return ParsedRoute(normalizedCode: normalized, taskTitle: displayTitle)
        }
        return nil
    }

    private static func parseTitleBracketOrHash(_ title: String) -> ParsedRoute? {
        if !title.isEmpty, title.hasPrefix("["), let closeIdx = title.firstIndex(of: "]"), closeIdx > title.startIndex {
            let open = title.index(after: title.startIndex)
            let codeRaw = String(title[open..<closeIdx]).trimmingCharacters(in: .whitespaces)
            let afterBracket = title.index(after: closeIdx)
            var rest = String(title[afterBracket...]).trimmingCharacters(in: .whitespacesAndNewlines)
            let normalized = normalizeCode(codeRaw)
            guard !normalized.isEmpty else { return nil }
            if rest.isEmpty { rest = "Reminder" }
            return ParsedRoute(normalizedCode: normalized, taskTitle: rest)
        }

        if !title.isEmpty, title.first == "#" {
            let withoutHash = String(title.dropFirst()).trimmingCharacters(in: .whitespaces)
            let parts = withoutHash.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
            guard let first = parts.first else { return nil }
            let codeRaw = String(first)
            let normalized = normalizeCode(codeRaw)
            guard !normalized.isEmpty else { return nil }
            let rest: String
            if parts.count > 1 {
                rest = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                rest = "Reminder"
            }
            let taskTitle = rest.isEmpty ? "Reminder" : rest
            return ParsedRoute(normalizedCode: normalized, taskTitle: taskTitle)
        }

        return nil
    }

    private static func normalizeCode(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
