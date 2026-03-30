import SwiftUI
import SwiftData

struct LogEngagementSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let project: Project

    @State private var date: Date = Date()
    @State private var summary: String = ""
    @State private var selectedContactIDs: Set<UUID> = []

    var isValid: Bool { !summary.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Log Engagement")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.gruvFg)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
                Button("Save") { save() }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.gruvOrange)
                    .disabled(!isValid)
                    .keyboardShortcut(.return, modifiers: .command)
            }
            .padding()
            .background(Color.gruvBg1)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    FormSection(title: "When") {
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .foregroundStyle(Color.gruvFg)
                    }

                    FormSection(title: "Summary *") {
                        TextEditor(text: $summary)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.gruvFg)
                            .frame(height: 100)
                            .padding(4)
                            .background(Color.gruvBg2)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    if !project.contacts.isEmpty {
                        FormSection(title: "Who was involved?") {
                            ForEach(project.contacts.sorted { $0.name < $1.name }) { contact in
                                Button {
                                    if selectedContactIDs.contains(contact.id) {
                                        selectedContactIDs.remove(contact.id)
                                    } else {
                                        selectedContactIDs.insert(contact.id)
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: selectedContactIDs.contains(contact.id) ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(selectedContactIDs.contains(contact.id) ? Color.gruvAqua : Color.gruvBg3)
                                        Text(contact.name)
                                            .foregroundStyle(Color.gruvFg)
                                        if let title = contact.title {
                                            Text("· \(title)")
                                                .font(.system(size: 11))
                                                .foregroundStyle(Color.gruvFgDim)
                                        }
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color.gruvBg)
        .frame(width: 460)
    }

    private func save() {
        let engagement = Engagement(
            date: date,
            summary: summary.trimmingCharacters(in: .whitespaces),
            contactIDs: Array(selectedContactIDs)
        )
        context.insert(engagement)
        project.engagements.append(engagement)
        project.updatedAt = Date()
        try? context.save()
        dismiss()
    }
}
