import SwiftUI
import SwiftData

struct OverviewTabView: View {
    let project: Project
    @Environment(\.modelContext) private var context

    var body: some View {
        @Bindable var project = project
        let ibmTeam = project.contacts
            .filter { $0.type == .ibmInternal }
            .sorted { $0.name < $1.name }

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Project summary card
                OverviewCard(title: "Project Info") {
                    OverviewInfoRow(label: "Account", value: project.accountName ?? "—")
                    OverviewInfoRow(label: "Stage") {
                        Text("● \(project.stage.rawValue)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.gruvStageColor(for: project.stage))
                    }
                    if let oppID = project.opportunityID, !oppID.isEmpty {
                        OverviewInfoRow(label: "Opp ID", value: oppID)
                    }
                    if !project.tags.isEmpty {
                        OverviewInfoRow(label: "Tags", value: project.tags.joined(separator: ", "))
                    }
                }

                // IBM team card (only shown when contacts exist)
                if !ibmTeam.isEmpty {
                    OverviewCard(title: "IBM Team") {
                        ForEach(ibmTeam) { contact in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.gruvBg3)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Text(initials(for: contact.name))
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(Color.gruvFg)
                                    )
                                Text(contact.name)
                                    .font(.system(size: 13))
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
                                Spacer()
                                if let email = contact.email, !email.isEmpty {
                                    Text(email)
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color.gruvBlue)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                // Links card
                OverviewCard(title: "Links") {
                    LinkRow(
                        label: "ISC Opportunity",
                        icon: "link.badge.plus",
                        value: $project.iscOpportunityLink,
                        onSave: { try? context.save() }
                    )
                    Divider().padding(.vertical, 4)
                    LinkRow(
                        label: "GTM Nav Account",
                        icon: "building.2",
                        value: $project.gtmNavAccountLink,
                        onSave: { try? context.save() }
                    )
                    Divider().padding(.vertical, 4)
                    LinkRow(
                        label: "OneDrive Folder",
                        icon: "folder.badge.questionmark",
                        value: $project.oneDriveFolderLink,
                        onSave: { try? context.save() }
                    )
                }
            }
            .padding()
        }
        .background(Color.gruvBg)
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first.map { String($0.prefix(1)) } ?? ""
        let last = parts.count > 1 ? parts.last.map { String($0.prefix(1)) } ?? "" : ""
        return (first + last).uppercased()
    }
}

// MARK: - Link row with inline editing + open button

struct LinkRow: View {
    let label: String
    let icon: String
    @Binding var value: String
    let onSave: () -> Void

    private var url: URL? {
        let s = value.trimmingCharacters(in: .whitespaces)
        guard !s.isEmpty else { return nil }
        // Prepend https:// if missing a scheme so URL(string:) parses it
        let normalized = s.hasPrefix("http") ? s : "https://\(s)"
        return URL(string: normalized)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(url != nil ? Color.gruvAqua : Color.gruvBg3)
                    .frame(width: 18)
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.gruvFgDim)
                Spacer()
                if let url {
                    Link(destination: url) {
                        HStack(spacing: 3) {
                            Text("Open")
                                .font(.system(size: 11))
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(Color.gruvBlue)
                    }
                }
            }
            TextField("Paste link…", text: $value)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12))
                .foregroundStyle(Color.gruvFg)
                .onSubmit { onSave() }
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
                .foregroundStyle(Color.gruvFgDim)
            content
        }
        .padding()
        .background(Color.gruvBg1)
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
                .foregroundStyle(Color.gruvFgDim)
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
            .foregroundStyle(Color.gruvFg)
    }
}
