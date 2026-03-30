import SwiftUI
import SwiftData

struct NotesTabView: View {
    @Environment(\.modelContext) private var context
    let project: Project

    @State private var newNoteContent: String = ""
    @State private var isAddingNote: Bool = false

    private var sorted: [Note] {
        project.notes.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        VStack(spacing: 0) {
            if isAddingNote {
                VStack(alignment: .leading, spacing: 8) {
                    TextEditor(text: $newNoteContent)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.themeFg)
                        .frame(height: 100)
                        .padding(4)
                        .background(Color.themeBg2)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    HStack {
                        Button("Cancel") {
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
                        NoteRowView(note: note, onDelete: { delete(note) })
                        Divider()
                    }
                    if sorted.isEmpty {
                        ContentUnavailableView("No Notes", systemImage: "note.text", description: Text("Add your first project note."))
                            .padding()
                    }
                }
            }
        }
    }

    private func saveNote() {
        let content = newNoteContent.trimmingCharacters(in: .whitespaces)
        guard !content.isEmpty else { return }
        let note = Note(content: content)
        context.insert(note)
        project.notes.append(note)
        project.updatedAt = Date()
        try? context.save()
        newNoteContent = ""
        isAddingNote = false
    }

    private func delete(_ note: Note) {
        project.notes.removeAll { $0.id == note.id }
        context.delete(note)
        try? context.save()
    }
}

struct NoteRowView: View {
    let note: Note
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(note.createdAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                .font(.system(size: 10))
                .foregroundStyle(Color.themeFgDim)
                .frame(width: 90, alignment: .leading)
                .padding(.top, 2)
            Text(note.content)
                .font(.system(size: 13))
                .foregroundStyle(Color.themeFg)
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(Color.themeRed)
            }
            .buttonStyle(.plain)
            .opacity(0.6)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}
