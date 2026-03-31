// EngagementTracker/Views/MenuBar/MenuBarPopoverView.swift
import SwiftUI
import SwiftData

struct MenuBarPopoverView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openSettings) private var openSettings
    @Query(sort: \Project.updatedAt, order: .reverse) private var allProjects: [Project]

    @State private var showNewProject = false

    private var activeProjects: [Project] { allProjects.filter(\.isActive) }

    private var filtered: [Project] {
        guard !appState.searchQuery.isEmpty else { return [] }
        let q = appState.searchQuery.lowercased()
        return activeProjects.filter {
            $0.name.lowercased().contains(q) ||
            ($0.accountName?.lowercased().contains(q) ?? false) ||
            $0.tags.contains { $0.lowercased().contains(q) } ||
            $0.stage.rawValue.lowercased().contains(q)
        }
    }

    private var pipelineStages: [ProjectStage] {
        [.discovery, .initialDelivery, .refine, .proposal]
    }

    private func count(for stage: ProjectStage) -> Int {
        activeProjects.filter { $0.stage == stage }.count
    }

    var body: some View {
        @Bindable var appState = appState
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.themeFgDim)
                TextField("Search projects…", text: $appState.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                if !appState.searchQuery.isEmpty {
                    Button {
                        appState.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.themeFgDim)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color.themeBg1)

            Divider()

            if !appState.searchQuery.isEmpty {
                // Search results
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if filtered.isEmpty {
                            Text("No results")
                                .foregroundStyle(Color.themeFgDim)
                                .font(.system(size: 12))
                                .padding()
                        } else {
                            ForEach(filtered) { project in
                                MenuBarProjectRow(project: project)
                                Divider()
                            }
                        }
                    }
                }
                .frame(maxHeight: 260)
            } else {
                // Quick capture
                QuickCaptureView()

                Divider()

                // Pipeline summary
                VStack(alignment: .leading, spacing: 6) {
                    Text("PIPELINE")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.themeFgDim)
                        .padding(.horizontal, 10)
                        .padding(.top, 8)

                    HStack(spacing: 6) {
                        ForEach(pipelineStages) { stage in
                            VStack(spacing: 2) {
                                Text("\(count(for: stage))")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(Color.themeStageColor(for: stage))
                                Text(stageAbbrev(stage))
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color.themeFgDim)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.themeBg1)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)
                }

                Divider()

                // Last touched project
                if let last = activeProjects.first {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LAST TOUCHED")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.themeFgDim)
                        MenuBarProjectRow(project: last)
                    }
                    .padding(10)
                }
            }

            Divider()

            // Footer
            HStack {
                Button("Open App") {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.windows.first?.makeKeyAndOrderFront(nil)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundStyle(Color.themeBlue)
                Spacer()
                Button {
                    showNewProject = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color.themeFgDim)
                }
                .buttonStyle(.plain)
                .help("New Project")
                Button {
                    openSettings()
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(Color.themeFgDim)
                }
                .buttonStyle(.plain)
                Button("Quit") { NSApp.terminate(nil) }
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.themeFgDim)
            }
            .padding(10)
            .background(Color.themeBg1)
        }
        .background(Color.themeBg)
        .frame(width: 320)
        .sheet(isPresented: $showNewProject) {
            NewProjectSheet()
        }
    }

    private func stageAbbrev(_ stage: ProjectStage) -> String {
        switch stage {
        case .discovery:       return "Discovery"
        case .initialDelivery: return "Init.\nDel."
        case .refine:          return "Refine"
        case .proposal:        return "Proposal"
        default:               return stage.rawValue
        }
    }
}

struct MenuBarProjectRow: View {
    let project: Project

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.themeFg)
                HStack(spacing: 4) {
                    Text(project.stage.rawValue)
                        .font(.system(size: 10))
                        .foregroundStyle(Color.themeStageColor(for: project.stage))
                    if project.isPOC {
                        Text("· POC")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.themePurple)
                    }
                    if let account = project.accountName {
                        Text("· \(account)")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.themeFgDim)
                    }
                }
            }
            Spacer()
            Image(systemName: "arrow.right")
                .font(.system(size: 10))
                .foregroundStyle(Color.themeFgDim)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
}
