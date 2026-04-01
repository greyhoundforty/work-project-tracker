import SwiftUI
import SwiftData

struct ContactsTabView: View {
    @Environment(\.modelContext) private var context
    let project: Project
    @State private var showAddContact = false

    private func contacts(of type: ContactType) -> [Contact] {
        project.contacts.filter { $0.type == type }.sorted { $0.name < $1.name }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    showAddContact = true
                } label: {
                    Label("Add Contact", systemImage: "person.badge.plus")
                }
                .padding()
            }
            .background(Color.themeBg1)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(ContactType.allCases, id: \.self) { type in
                        let group = contacts(of: type)
                        if !group.isEmpty {
                            Section {
                                ForEach(group) { contact in
                                    ContactRowView(contact: contact, onDelete: { delete(contact) })
                                }
                            } header: {
                                Text(type.rawValue.uppercased())
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Color.themeFgDim)
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                            }
                        }
                    }

                    if project.contacts.isEmpty {
                        ContentUnavailableView("No Contacts", systemImage: "person.2", description: Text("Add internal or external contacts."))
                            .padding()
                    }
                }
            }
        }
        .sheet(isPresented: $showAddContact) {
            AddContactSheet(project: project)
        }
    }

    private func delete(_ contact: Contact) {
        project.contacts.removeAll { $0.id == contact.id }
        context.delete(contact)
        try? context.save()
    }
}

struct ContactRowView: View {
    let contact: Contact
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.themeBg2)
                .frame(width: 36, height: 36)
                .overlay(
                    Text(initials(for: contact.name))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.themeFg)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(contact.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.themeFg)
                    if let role = contact.role, !role.isEmpty {
                        Text(role)
                            .font(.system(size: 10))
                            .foregroundStyle(Color.themeAqua)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Color.themeBg2)
                            .clipShape(Capsule())
                    }
                }
                if let title = contact.title {
                    Text(title)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.themeFgDim)
                }
                if let email = contact.email {
                    Text(email)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.themeBlue)
                }
                if let notes = contact.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.themeFgDim)
                        .lineLimit(2)
                }
            }
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(Color.themeRed)
            }
            .buttonStyle(.plain)
            .opacity(0.6)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first.map { String($0.prefix(1)) } ?? ""
        let last = parts.count > 1 ? parts.last.map { String($0.prefix(1)) } ?? "" : ""
        return (first + last).uppercased()
    }
}
