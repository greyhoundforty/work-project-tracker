import SwiftUI

struct CheckpointsTabView: View {
    let project: Project

    private var checkpointsByStage: [(ProjectStage, [Checkpoint])] {
        let sorted = project.checkpoints.sorted {
            let stageOrder = ProjectStage.allCases
            let aIdx = stageOrder.firstIndex(of: $0.stage) ?? 0
            let bIdx = stageOrder.firstIndex(of: $1.stage) ?? 0
            if aIdx != bIdx { return aIdx < bIdx }
            return $0.sortOrder < $1.sortOrder
        }
        var result: [(ProjectStage, [Checkpoint])] = []
        for stage in ProjectStage.allCases {
            let cps = sorted.filter { $0.stage == stage }
            if !cps.isEmpty { result.append((stage, cps)) }
        }
        return result
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16, pinnedViews: .sectionHeaders) {
                ForEach(checkpointsByStage, id: \.0) { stage, checkpoints in
                    Section {
                        ForEach(checkpoints) { checkpoint in
                            CheckpointRowView(checkpoint: checkpoint)
                        }
                    } header: {
                        HStack {
                            Text(stage.rawValue.uppercased())
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color.themeStageColor(for: stage))
                            Spacer()
                            let completed = checkpoints.filter(\.isCompleted).count
                            Text("\(completed)/\(checkpoints.count)")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.themeFgDim)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                        .background(Color.themeBg1)
                    }
                }
            }
        }
    }
}

struct CheckpointRowView: View {
    let checkpoint: Checkpoint
    @Environment(\.modelContext) private var context

    var body: some View {
        Button {
            checkpoint.toggle()
            checkpoint.project?.updatedAt = Date()
            try? context.save()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: checkpoint.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(checkpoint.isCompleted ? Color.themeGreen : Color.themeBg3)
                    .font(.system(size: 16))
                Text(checkpoint.title)
                    .font(.system(size: 13))
                    .foregroundStyle(checkpoint.isCompleted ? Color.themeFgDim : Color.themeFg)
                    .strikethrough(checkpoint.isCompleted, color: Color.themeFgDim)
                Spacer()
                if let completedAt = checkpoint.completedAt {
                    Text(completedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 10))
                        .foregroundStyle(Color.themeFgDim)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}
