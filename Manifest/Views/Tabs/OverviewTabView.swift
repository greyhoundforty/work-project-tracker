import SwiftUI
import SwiftData

struct OverviewTabView: View {
    let project: Project
    @Environment(\.modelContext) private var context

    var body: some View {
        @Bindable var project = project

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Top row: Project Info + Quick Links side by side, equal height
                HStack(alignment: .top, spacing: 12) {
                    OverviewCard(title: "Project Info") {
                        OverviewInfoRow(label: "Account", value: project.accountName ?? "—")
                        OverviewInfoRow(label: "Stage") {
                            Text("● \(project.stage.rawValue)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.themeStageColor(for: project.stage))
                        }
                        if let oppID = project.opportunityID, !oppID.isEmpty {
                            OverviewInfoRow(label: "Opp ID", value: oppID)
                        }
                        let projectTags = project.tags.filter { $0.hasPrefix("#") }
                        if !projectTags.isEmpty {
                            OverviewInfoRow(label: "Tags", value: projectTags.map { String($0.dropFirst()) }.joined(separator: ", "))
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxHeight: .infinity)

                    ProjectLinksCard(project: project)
                        .frame(maxHeight: .infinity)
                }
                .fixedSize(horizontal: false, vertical: true)

                if !project.customFields.isEmpty {
                    CustomFieldsCard(project: project)
                }

                // Engagement calendar
                EngagementCalendarView(engagements: project.engagements)
            }
            .padding()
        }
        .background(Color.themeBg)
    }

}

// MARK: - Quick Links Card

private struct ProjectLinksCard: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var context

    private let maxLinks = 3

    private var sortedLinks: [ProjectLink] {
        project.links.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        OverviewCard(title: "Quick Links") {
            VStack(spacing: 6) {
                ForEach(sortedLinks) { link in
                    ProjectLinkRow(link: link, onSave: { try? context.save() }, onClear: {
                        link.name = ""
                        link.url = ""
                        try? context.save()
                    })
                }
            }
        }
        .onAppear { ensureLinks() }
    }

    private func ensureLinks() {
        let existing = sortedLinks.count
        guard existing < maxLinks else { return }
        for i in existing..<maxLinks {
            let link = ProjectLink(sortOrder: i)
            link.project = project
            project.links.append(link)
            context.insert(link)
        }
        try? context.save()
    }
}

private struct ProjectLinkRow: View {
    @Bindable var link: ProjectLink
    let onSave: () -> Void
    let onClear: () -> Void

    @State private var isEditing = false

    private var isFilled: Bool {
        !link.url.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var resolvedURL: URL? {
        let s = link.url.trimmingCharacters(in: .whitespaces)
        guard !s.isEmpty else { return nil }
        let normalized = s.hasPrefix("http") ? s : "https://\(s)"
        return URL(string: normalized)
    }

    var body: some View {
        if isFilled && !isEditing {
            // Display mode: rendered clickable link
            HStack(spacing: 8) {
                Button {
                    if let url = resolvedURL { NSWorkspace.shared.open(url) }
                } label: {
                    Text(link.name.isEmpty ? link.url : link.name)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.themeAqua)
                        .underline()
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .help(link.url)

                Button { isEditing = true } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.themeFgDim)
                }
                .buttonStyle(.plain)
                .help("Edit link")

                Button { onClear(); isEditing = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.themeFgDim)
                }
                .buttonStyle(.plain)
                .help("Clear link")
            }
            .frame(height: 22)
        } else {
            // Edit mode: text fields
            HStack(spacing: 8) {
                TextField("Name", text: $link.name)
                    .font(.system(size: 12))
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)
                    .onSubmit { commitEdit() }

                TextField("https://", text: $link.url)
                    .font(.system(size: 12))
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)
                    .onSubmit { commitEdit() }

                if isFilled {
                    Button { commitEdit() } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.themeAqua)
                    }
                    .buttonStyle(.plain)
                    .help("Done")
                } else {
                    Color.clear.frame(width: 20)
                }
            }
        }
    }

    private func commitEdit() {
        onSave()
        if isFilled { isEditing = false }
    }
}

// MARK: - Engagement Calendar

struct EngagementCalendarView: View {
    let engagements: [Engagement]

    @State private var displayedMonth: Date = {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: Date())
        return cal.date(from: comps) ?? Date()
    }()

    private let calendar = Calendar.current
    private let dayColumns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols

    private var engagementDays: Set<String> {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return Set(engagements.map { fmt.string(from: $0.date) })
    }

    private var daysInGrid: [Date?] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)),
              let range = calendar.range(of: .day, in: .month, for: monthStart) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let leadingBlanks = (firstWeekday - calendar.firstWeekday + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for day in range {
            days.append(calendar.date(byAdding: .day, value: day - 1, to: monthStart))
        }
        return days
    }

    var body: some View {
        OverviewCard(title: "Engagement Activity") {
            // Month navigation header
            HStack {
                Button {
                    displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.themeFgDim)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(displayedMonth, format: .dateTime.month(.wide).year())
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.themeFg)

                Spacer()

                Button {
                    displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.themeFgDim)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 4)

            // Weekday headers
            LazyVGrid(columns: dayColumns, spacing: 4) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.themeFgDim)
                        .frame(maxWidth: .infinity)
                }

                // Day cells
                ForEach(Array(daysInGrid.enumerated()), id: \.offset) { _, date in
                    if let date {
                        CalendarDayCell(date: date, hasEngagement: engagementDays.contains(dayKey(date)), isToday: calendar.isDateInToday(date))
                    } else {
                        Color.clear.frame(height: 28)
                    }
                }
            }

            // Legend
            if !engagementDays.isEmpty {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.themeAqua.opacity(0.35))
                        .frame(width: 8, height: 8)
                    Text("Engagement logged")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.themeFgDim)
                }
                .padding(.top, 6)
            }
        }
    }

    private func dayKey(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }
}

private struct CalendarDayCell: View {
    let date: Date
    let hasEngagement: Bool
    let isToday: Bool

    var body: some View {
        ZStack {
            if hasEngagement {
                Circle()
                    .fill(Color.themeAqua.opacity(0.35))
            } else if isToday {
                Circle()
                    .strokeBorder(Color.themeFgDim.opacity(0.4), lineWidth: 1)
            }
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 11, weight: hasEngagement ? .semibold : .regular))
                .foregroundStyle(hasEngagement ? Color.themeAqua : (isToday ? Color.themeFg : Color.themeFgDim))
        }
        .frame(height: 28)
    }
}

// MARK: - Link icon button with popover editor

struct LinkIconButton: View {
    let label: String
    let icon: String
    @Binding var value: String
    let onSave: () -> Void

    @State private var showPopover = false

    private var url: URL? {
        let s = value.trimmingCharacters(in: .whitespaces)
        guard !s.isEmpty else { return nil }
        let normalized = s.hasPrefix("http") ? s : "https://\(s)"
        return URL(string: normalized)
    }

    var body: some View {
        Button {
            if let url {
                NSWorkspace.shared.open(url)
            } else {
                showPopover = true
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(url != nil ? Color.themeAqua : Color.themeBg3)
                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(url != nil ? Color.themeAqua : Color.themeFgDim.opacity(0.5))
                    .underline(url != nil)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .help(url != nil ? "Open \(label)" : "Set \(label)")
        .contextMenu {
            if url != nil {
                Button("Edit Link") { showPopover = true }
                Button("Clear Link") { value = ""; onSave() }
            } else {
                Button("Set Link") { showPopover = true }
            }
        }
        .popover(isPresented: $showPopover, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.themeFgDim)
                HStack(spacing: 6) {
                    TextField("Paste link…", text: $value)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))
                        .frame(width: 260)
                        .onSubmit { onSave(); showPopover = false }
                    if url != nil {
                        Button("Clear") { value = ""; onSave(); showPopover = false }
                            .font(.system(size: 11))
                    }
                    Button("Save") { onSave(); showPopover = false }
                        .font(.system(size: 11))
                }
            }
            .padding(12)
            .background(Color.themeBg1)
        }
    }
}

// MARK: - Reusable card + row layout

struct OverviewCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.themeFgDim)
            content
        }
        .padding()
        .background(Color.themeBg1)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct OverviewInfoRow<Value: View>: View {
    let label: String
    @ViewBuilder let valueView: Value

    init(label: String, @ViewBuilder value: () -> Value) {
        self.label = label
        self.valueView = value()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Color.themeFgDim)
                .frame(width: 90, alignment: .leading)
            valueView
        }
    }
}

// Convenience overload for plain string values
extension OverviewInfoRow where Value == Text {
    init(label: String, value: String) {
        self.label = label
        self.valueView = Text(value)
            .font(.system(size: 12))
            .foregroundStyle(Color.themeFg)
    }
}

// MARK: - Custom Fields Card

struct CustomFieldsCard: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var context

    private var sortedFields: [ProjectCustomField] {
        project.customFields.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        OverviewCard(title: "Template Fields") {
            ForEach(sortedFields) { field in
                CustomFieldRow(field: field, onSave: { try? context.save() })
            }
        }
    }
}

struct CustomFieldRow: View {
    @Bindable var field: ProjectCustomField
    let onSave: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(field.label)
                .font(.system(size: 12))
                .foregroundStyle(Color.themeFgDim)
                .frame(width: 90, alignment: .leading)
            TextField("Enter value", text: $field.value)
                .font(.system(size: 12))
                .foregroundStyle(Color.themeFg)
                .textFieldStyle(.roundedBorder)
                .onSubmit { onSave() }
        }
    }
}
