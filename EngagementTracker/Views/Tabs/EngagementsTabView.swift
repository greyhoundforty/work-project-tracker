import SwiftUI
import SwiftData

struct EngagementsTabView: View {
    @Environment(\.modelContext) private var context
    let project: Project
    @State private var showLogEngagement = false

    private var sorted: [Engagement] {
        project.engagements.sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    showLogEngagement = true
                } label: {
                    Label("Log Engagement", systemImage: "plus.bubble")
                }
                .padding()
            }
            .background(Color.gruvBg1)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(sorted) { engagement in
                        EngagementRowView(engagement: engagement, project: project, onDelete: { delete(engagement) })
                        Divider().padding(.leading, 16)
                    }
                    if sorted.isEmpty {
                        ContentUnavailableView("No Engagements", systemImage: "bubble.left.and.bubble.right", description: Text("Log your first customer interaction."))
                            .padding()
                    }
                }
            }
        }
        .sheet(isPresented: $showLogEngagement) {
            LogEngagementSheet(project: project)
        }
    }

    private func delete(_ engagement: Engagement) {
        project.engagements.removeAll { $0.id == engagement.id }
        context.delete(engagement)
    }
}

struct EngagementRowView: View {
    let engagement: Engagement
    let project: Project
    let onDelete: () -> Void

    private var taggedContacts: [Contact] {
        project.contacts.filter { engagement.contactIDs.contains($0.id) }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                Text(engagement.date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.gruvOrange)
                Text(engagement.date.formatted(.dateTime.year()))
                    .font(.system(size: 10))
                    .foregroundStyle(Color.gruvFgDim)
            }
            .frame(width: 48)
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(engagement.summary)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.gruvFg)
                if !taggedContacts.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(taggedContacts) { contact in
                            Text(contact.name)
                                .font(.system(size: 10))
                                .foregroundStyle(Color.gruvAqua)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gruvBg2)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(Color.gruvRed)
            }
            .buttonStyle(.plain)
            .opacity(0.6)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}
