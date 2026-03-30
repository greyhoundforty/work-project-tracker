import SwiftUI
import SwiftData

struct StagesSidebarView: View {
    @Environment(AppState.self) private var appState
    @Query private var projects: [Project]

    private var allTags: [String] {
        let active = projects.filter(\.isActive)
        let tagSet = Set(active.flatMap(\.tags))
        return tagSet.sorted()
    }

    var body: some View {
        List {
            Section {
                SidebarRow(
                    label: "All Projects",
                    icon: "folder",
                    badge: projects.filter(\.isActive).count,
                    isSelected: appState.selectedStage == nil && appState.selectedTag == nil,
                    color: .themeFg
                ) {
                    appState.selectedStage = nil
                    appState.selectedTag = nil
                }
            }

            Section("Pipeline") {
                ForEach(ProjectStage.allCases.filter { !$0.isTerminal }) { stage in
                    SidebarRow(
                        label: stage.rawValue,
                        icon: stageIcon(stage),
                        badge: count(for: stage),
                        isSelected: appState.selectedStage == stage && appState.selectedTag == nil,
                        color: Color.themeStageColor(for: stage)
                    ) {
                        appState.selectedStage = stage
                        appState.selectedTag = nil
                    }
                }
            }

            Section("Closed") {
                SidebarRow(
                    label: ProjectStage.won.rawValue,
                    icon: "checkmark.seal.fill",
                    badge: count(for: .won),
                    isSelected: appState.selectedStage == .won && appState.selectedTag == nil,
                    color: .themeGreen
                ) {
                    appState.selectedStage = .won
                    appState.selectedTag = nil
                }
                SidebarRow(
                    label: ProjectStage.lost.rawValue,
                    icon: "xmark.seal.fill",
                    badge: count(for: .lost),
                    isSelected: appState.selectedStage == .lost && appState.selectedTag == nil,
                    color: .themeRed
                ) {
                    appState.selectedStage = .lost
                    appState.selectedTag = nil
                }
            }

            if !allTags.isEmpty {
                Section("Tags") {
                    ForEach(allTags, id: \.self) { tag in
                        SidebarRow(
                            label: tag,
                            icon: "tag",
                            badge: tagCount(tag),
                            isSelected: appState.selectedTag == tag,
                            color: .themeYellow
                        ) {
                            appState.selectedTag = tag
                            appState.selectedStage = nil
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Engagement Tracker")
        .frame(minWidth: 160)
    }

    private func count(for stage: ProjectStage) -> Int {
        projects.filter { $0.stage == stage && $0.isActive }.count
    }

    private func tagCount(_ tag: String) -> Int {
        projects.filter { $0.isActive && $0.tags.contains(tag) }.count
    }

    private func stageIcon(_ stage: ProjectStage) -> String {
        switch stage {
        case .discovery:       return "magnifyingglass"
        case .initialDelivery: return "doc.text"
        case .refine:          return "pencil.and.list.clipboard"
        case .proposal:        return "envelope.open"
        case .won:             return "checkmark.seal.fill"
        case .lost:            return "xmark.seal.fill"
        }
    }
}

private struct SidebarRow: View {
    let label: String
    let icon: String
    let badge: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Label(label, systemImage: icon)
                    .foregroundStyle(color)
                Spacer()
                if badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.themeFgDim)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.themeBg2)
                        .clipShape(Capsule())
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.themeAqua.opacity(0.2) : Color.clear)
        )
    }
}
