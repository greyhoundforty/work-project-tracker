import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState
        NavigationSplitView {
            StagesSidebarView()
        } content: {
            ProjectListView()
        } detail: {
            if let project = appState.selectedProject {
                ProjectDetailView(project: project)
            } else {
                ContentUnavailableView("Select a Project", systemImage: "briefcase", description: Text("Choose a project from the list."))
                    .background(Color.gruvBg)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .background(Color.gruvBg)
    }
}
