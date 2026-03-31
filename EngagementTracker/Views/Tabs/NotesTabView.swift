import SwiftUI
import SwiftData
import MarkdownUI

struct NotesTabView: View {
    @Environment(\.modelContext) private var context
    let project: Project

    @State private var newNoteTitle: String = ""
    @State private var newNoteContent: String = ""
    @State private var isAddingNote: Bool = false
    @State private var editingNoteID: UUID? = nil

    private var sorted: [Note] {
        project.notes.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        VStack(spacing: 0) {
            if isAddingNote {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Title (optional)", text: $newNoteTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.themeFg)
                        .padding(6)
                        .background(Color.themeBg2)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    TextEditor(text: $newNoteContent)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.themeFg)
                        .frame(height: 100)
                        .padding(4)
                        .background(Color.themeBg2)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    HStack {
                        Button("Cancel") {
                            newNoteTitle = ""
                            newNoteContent = ""
                            isAddingNote = false
                        }
                        Spacer()
                        Button("Save Note") {
                            saveNote()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.themeAqua)
                        .disabled(newNoteContent.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                .padding()
                .background(Color.themeBg1)
                Divider()
            } else {
                HStack {
                    Spacer()
                    Button {
                        isAddingNote = true
                    } label: {
                        Label("Add Note", systemImage: "square.and.pencil")
                    }
                    .padding()
                }
                .background(Color.themeBg1)
                Divider()
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(sorted) { note in
                        NoteRowView(
                            note: note,
                            onDelete: { delete(note) },
                            editingNoteID: $editingNoteID
                        )
                        Divider()
                    }
                    if sorted.isEmpty {
                        ContentUnavailableView(
                            "No Notes",
                            systemImage: "note.text",
                            description: Text("Add your first project note.")
                        )
                        .padding()
                    }
                }
            }
        }
    }

    private func saveNote() {
        let content = newNoteContent.trimmingCharacters(in: .whitespaces)
        guard !content.isEmpty else { return }
        let titleInput = newNoteTitle.trimmingCharacters(in: .whitespaces)
        let note = Note(
            title: titleInput.isEmpty ? defaultTitle(for: Date()) : titleInput,
            content: content
        )
        context.insert(note)
        project.notes.append(note)
        project.updatedAt = Date()
        try? context.save()
        newNoteTitle = ""
        newNoteContent = ""
        isAddingNote = false
    }

    private func delete(_ note: Note) {
        project.notes.removeAll { $0.id == note.id }
        context.delete(note)
        try? context.save()
    }

    private func defaultTitle(for date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day().year())
    }
}

struct NoteRowView: View {
    @Environment(\.modelContext) private var context
    let note: Note
    let onDelete: () -> Void
    @Binding var editingNoteID: UUID?
    @State private var editedTitle: String = ""
    @State private var editedContent: String = ""

    private var isEditing: Bool { editingNoteID == note.id }

    private func defaultTitle(for date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day().year())
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(note.createdAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                .font(.system(size: 10))
                .foregroundStyle(Color.themeFgDim)
                .frame(width: 90, alignment: .leading)
                .padding(.top, 2)

            if isEditing {
                VStack(alignment: .leading, spacing: 6) {
                    TextField("Title (optional)", text: $editedTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.themeFg)
                        .padding(6)
                        .background(Color.themeBg)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.themeAqua, lineWidth: 1.5)
                        )
                    TextEditor(text: $editedContent)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.themeFg)
                        .frame(minHeight: 80)
                        .padding(4)
                        .background(Color.themeBg)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.themeAqua, lineWidth: 1.5)
                        )
                    HStack {
                        Button("Cancel") {
                            editedTitle = note.title
                            editedContent = note.content
                            editingNoteID = nil
                        }
                        Spacer()
                        Button("Save") {
                            let titleInput = editedTitle.trimmingCharacters(in: .whitespaces)
                            note.title = titleInput.isEmpty ? defaultTitle(for: note.createdAt) : titleInput
                            note.content = editedContent
                            note.project?.updatedAt = Date()
                            try? context.save()
                            editingNoteID = nil
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.themeAqua)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.title.isEmpty ? defaultTitle(for: note.createdAt) : note.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.themeFg)
                    Markdown(note.content)
                        .markdownTheme(.engagementTracker)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    editedTitle = note.title
                    editedContent = note.content
                    editingNoteID = note.id
                }
            }

            if !isEditing {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(Color.themeRed)
                }
                .buttonStyle(.plain)
                .opacity(0.6)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}
