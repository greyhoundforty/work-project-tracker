import SwiftUI
import SwiftData

struct NewFolderSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ProjectFolder.sortOrder) private var folders: [ProjectFolder]

    @State private var name: String = ""
    @State private var selectedParent: ProjectFolder? = nil

    private var rootFolders: [ProjectFolder] { folders.filter { $0.parent == nil } }
    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("New Folder")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.themeFg)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
                Button("Create") { save() }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.themeAqua)
                    .disabled(!isValid)
                    .keyboardShortcut(.return, modifiers: .command)
            }
            .padding()
            .background(Color.themeBg1)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    FormSection(title: "Folder") {
                        LabeledField(label: "Name *") {
                            TextField("Required", text: $name)
                        }
                        if !rootFolders.isEmpty {
                            LabeledField(label: "Parent Folder") {
                                Picker("", selection: $selectedParent) {
                                    Text("None (root folder)").tag(Optional<ProjectFolder>.none)
                                    ForEach(rootFolders) { folder in
                                        Text(folder.name).tag(Optional(folder))
                                    }
                                }
                                .labelsHidden()
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color.themeBg)
        .frame(width: 360)
    }

    private func save() {
        let maxOrder = folders.map(\.sortOrder).max() ?? -1
        let folder = ProjectFolder(
            name: name.trimmingCharacters(in: .whitespaces),
            sortOrder: maxOrder + 1,
            parent: selectedParent
        )
        context.insert(folder)
        do {
            try context.save()
            dismiss()
        } catch {
            print("[NewFolderSheet] context.save() failed: \(error)")
        }
    }
}
