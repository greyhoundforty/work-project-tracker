import SwiftUI
import SwiftData

struct AddContactSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let project: Project

    @State private var name: String = ""
    @State private var role: String = ""
    @State private var title: String = ""
    @State private var email: String = ""
    @State private var notes: String = ""
    @State private var type: ContactType = .external

    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Add Contact")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.themeFg)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
                Button("Add") { save() }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.themeAqua)
                    .disabled(!isValid)
                    .keyboardShortcut(.return, modifiers: .command)
            }
            .padding()
            .background(Color.themeBg1)

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                FormSection(title: "Contact Type") {
                    Picker("Type", selection: $type) {
                        ForEach(ContactType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.radioGroup)
                }

                FormSection(title: "Contact Details") {
                    LabeledField(label: "Name *") {
                        TextField("Required", text: $name)
                    }
                    LabeledField(label: "Role") {
                        TextField("e.g. Account Executive, Designer…", text: $role)
                    }
                    LabeledField(label: "Title / Position") {
                        TextField("Optional", text: $title)
                    }
                    LabeledField(label: "Email") {
                        TextField("Optional", text: $email)
                    }
                }

                FormSection(title: "Notes") {
                    TextEditor(text: $notes)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.themeFg)
                        .frame(minHeight: 72)
                        .scrollContentBackground(.hidden)
                        .background(Color.themeBg2)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    Text("Preferred contact method, office hours, etc.")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.themeFgDim)
                }
            }
            .padding()
        }
        .background(Color.themeBg)
        .frame(width: 420)
    }

    private func save() {
        let contact = Contact(
            name: name.trimmingCharacters(in: .whitespaces),
            role: role.isEmpty ? nil : role,
            title: title.isEmpty ? nil : title,
            email: email.isEmpty ? nil : email,
            notes: notes.isEmpty ? nil : notes,
            type: type
        )
        context.insert(contact)
        project.contacts.append(contact)
        project.updatedAt = Date()
        try? context.save()
        dismiss()
    }
}
