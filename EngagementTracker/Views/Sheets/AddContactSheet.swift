import SwiftUI
import SwiftData

struct AddContactSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let project: Project

    @State private var name: String = ""
    @State private var title: String = ""
    @State private var email: String = ""
    @State private var type: ContactType = .external
    @State private var internalRole: InternalRole = .ae

    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Add Contact")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.gruvFg)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
                Button("Add") { save() }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.gruvAqua)
                    .disabled(!isValid)
                    .keyboardShortcut(.return, modifiers: .command)
            }
            .padding()
            .background(Color.gruvBg1)

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                FormSection(title: "Contact Type") {
                    Picker("Type", selection: $type) {
                        ForEach(ContactType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    if type == .ibmInternal {
                        Picker("Role", selection: $internalRole) {
                            ForEach(InternalRole.allCases, id: \.self) { r in
                                Text(r.rawValue).tag(r)
                            }
                        }
                    }
                }

                FormSection(title: "Contact Details") {
                    LabeledField(label: "Name *") {
                        TextField("Required", text: $name)
                    }
                    LabeledField(label: "Title / Position") {
                        TextField("Optional", text: $title)
                    }
                    LabeledField(label: "Email") {
                        TextField("Optional", text: $email)
                    }
                }
            }
            .padding()
        }
        .background(Color.gruvBg)
        .frame(width: 420)
    }

    private func save() {
        let contact = Contact(
            name: name.trimmingCharacters(in: .whitespaces),
            title: title.isEmpty ? nil : title,
            email: email.isEmpty ? nil : email,
            type: type,
            internalRole: type == .ibmInternal ? internalRole : nil
        )
        context.insert(contact)
        project.contacts.append(contact)
        project.updatedAt = Date()
        try? context.save()
        dismiss()
    }
}
