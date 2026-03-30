import SwiftUI

struct ProjectDetailView: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            ProjectDetailHeaderView(project: project)
            Divider()
            // Tabs — implemented in Task 8
            Text("Tabs coming soon")
                .foregroundStyle(Color.gruvFgDim)
                .padding()
            Spacer()
        }
        .background(Color.gruvBg)
    }
}

struct ProjectDetailHeaderView: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(project.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.gruvFg)
                Spacer()
                if !project.stage.isTerminal, let next = project.stage.next {
                    Button("Advance to \(next.rawValue)") {
                        project.stage = next
                        project.updatedAt = Date()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.gruvStageColor(for: next))
                }
            }
            HStack(spacing: 8) {
                StagePill(stage: project.stage)
                if project.isPOC {
                    TagPill(label: "POC", color: .gruvPurple)
                }
                if let value = project.estimatedValueFormatted {
                    TagPill(label: value, color: .gruvGreen)
                }
                if let account = project.accountName {
                    TagPill(label: account, color: .gruvFgDim)
                }
                if let closeDate = project.targetCloseDate {
                    TagPill(label: "Close: \(closeDate.formatted(date: .abbreviated, time: .omitted))", color: .gruvFgDim)
                }
            }
        }
        .padding()
        .background(Color.gruvBg1)
    }
}

struct StagePill: View {
    let stage: ProjectStage
    var body: some View {
        Text("● \(stage.rawValue)")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.gruvStageColor(for: stage))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.gruvBg2)
            .clipShape(Capsule())
    }
}

struct TagPill: View {
    let label: String
    let color: Color
    var body: some View {
        Text(label)
            .font(.system(size: 11))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.gruvBg2)
            .clipShape(Capsule())
    }
}
