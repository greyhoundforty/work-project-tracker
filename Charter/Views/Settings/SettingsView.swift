import SwiftUI
import SwiftData
import AppKit

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(RemindersService.self) private var remindersService
    @Environment(\.modelContext) private var modelContext

    @State private var showResetDataAlert = false
    @State private var showResetAllAlert = false

    private var loadedTemplates: [ProjectTemplate] {
        var templates = ProjectTemplate.loadBundled()
        if let url = appState.resolveTemplateFolderURL() {
            let userTemplates = ProjectTemplate.load(from: url)
            let userNames = Set(userTemplates.map(\.name))
            templates = templates.filter { !userNames.contains($0.name) } + userTemplates
        }
        templates.sort { $0.name < $1.name }
        return templates
    }

    var body: some View {
        @Bindable var appState = appState
        Form {
            Section {
                HStack(spacing: 12) {
                    if let appIcon = NSImage(named: NSImage.applicationIconName) {
                        Image(nsImage: appIcon)
                            .resizable()
                            .frame(width: 48, height: 48)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Charter")
                            .font(.system(size: 14, weight: .semibold))
                        LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.2.2")
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("About")
            }

            Section {
                Picker("Theme", selection: Binding(
                    get: { appState.themeMode },
                    set: { appState.themeMode = $0 }
                )) {
                    Text("System").tag(ThemeMode.system)
                    Text("Light").tag(ThemeMode.light)
                    Text("Dark").tag(ThemeMode.dark)
                }
                .pickerStyle(.radioGroup)
            } header: {
                Text("Appearance")
            }

            Section {
                HStack {
                    if let path = appState.templateFolderPath {
                        Text(path)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Button("Clear") {
                            appState.templateFolderPath = nil
                            appState.templateFolderBookmark = nil
                        }
                        .buttonStyle(.borderless)
                    } else {
                        Text("No folder selected")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Button("Choose…") {
                        chooseTemplateFolder()
                    }
                }
                Text("JSON template files in this folder appear as options when creating a new project.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                if !loadedTemplates.isEmpty {
                    VStack(spacing: 0) {
                        HStack {
                            Text("NAME").frame(maxWidth: .infinity, alignment: .leading)
                            Text("STAGE").frame(width: 110, alignment: .leading)
                            Text("POC").frame(width: 36, alignment: .center)
                            Text("TASKS").frame(width: 44, alignment: .trailing)
                            Text("SOURCE").frame(width: 60, alignment: .trailing)
                        }
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.themeFgDim)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)

                        Divider()

                        ForEach(loadedTemplates) { template in
                            HStack {
                                Text(template.name)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(template.stage)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 110, alignment: .leading)
                                Image(systemName: template.isPOC ? "checkmark" : "minus")
                                    .foregroundStyle(template.isPOC ? Color.themeGreen : Color.themeFgDim)
                                    .frame(width: 36, alignment: .center)
                                Text("\(template.taskTitles.count)")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 44, alignment: .trailing)
                                Group {
                                    if template.isBuiltIn {
                                        Text("Built-in")
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("Custom")
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                .frame(width: 60, alignment: .trailing)
                            }
                            .font(.system(size: 11))
                            .foregroundStyle(Color.themeFg)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            Divider()
                        }
                    }
                    .background(Color.themeBg2)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            } header: {
                Text("Templates")
            }

            Section {
                Toggle("Sync with iCloud", isOn: Binding(
                    get: { appState.isCloudSyncEnabled },
                    set: { appState.isCloudSyncEnabled = $0 }
                ))
                Text("Enables CloudKit sync across your Macs. Restart the app after changing this setting for it to take effect.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            } header: {
                Text("Sync")
            }

            Section {
                RemindersSettingsSection()
            } header: {
                Text("Reminders")
            }

            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reset Data")
                            .foregroundStyle(.red)
                        Text("Permanently delete all projects and their data.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Reset Data…") {
                        showResetDataAlert = true
                    }
                    .tint(.red)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reset All")
                            .foregroundStyle(.red)
                        Text("Delete all data and restore settings to defaults.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Reset All…") {
                        showResetAllAlert = true
                    }
                    .tint(.red)
                }
            } header: {
                Text("Danger Zone")
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 720)
        .alert("Reset Data?", isPresented: $showResetDataAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete All Data", role: .destructive) { resetData() }
        } message: {
            Text("This will permanently delete all projects and their associated data. This cannot be undone.")
        }
        .alert("Reset Everything?", isPresented: $showResetAllAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset Everything", role: .destructive) { resetAll() }
        } message: {
            Text("This will permanently delete all projects and reset all settings to defaults. This cannot be undone.")
        }
    }

    private func resetData() {
        let projects = (try? modelContext.fetch(FetchDescriptor<Project>())) ?? []
        projects.forEach { modelContext.delete($0) }
        try? modelContext.save()
        appState.selectedProject = nil
        appState.selectedStage = nil
        appState.selectedTag = nil
        appState.selectedLabel = nil
        appState.searchQuery = ""
    }

    private func resetAll() {
        resetData()
        appState.templateFolderPath = nil
        appState.templateFolderBookmark = nil
        appState.themeMode = .system
        appState.isCloudSyncEnabled = false
        appState.remindersListID = nil
        appState.remindersMarkCompleted = false
    }

    private func chooseTemplateFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Folder"
        if panel.runModal() == .OK, let url = panel.url {
            appState.templateFolderPath = url.path
            appState.templateFolderBookmark = try? url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        }
    }
}

// MARK: - RemindersSettingsSection

private struct RemindersSettingsSection: View {
    @Environment(AppState.self) private var appState
    @Environment(RemindersService.self) private var remindersService

    var body: some View {
        @Bindable var appState = appState

        Group {
            switch remindersService.authorizationStatus {
            case .notDetermined:
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Import tasks from Reminders")
                        Text("Charter will ask permission to read a Reminders list you choose.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Allow Access…") {
                        Task { await remindersService.requestAccess() }
                    }
                }
            case .denied, .restricted:
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Text("Reminders access was denied. Enable it in System Settings → Privacy & Security → Reminders.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            case .fullAccess:
                authorizedContent(appState: appState)
            default:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func authorizedContent(appState: AppState) -> some View {
        if remindersService.availableLists.isEmpty {
            Text("No Reminders lists found.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        } else {
            Picker("Import From", selection: Binding(
                get: { appState.remindersListID ?? "" },
                set: { appState.remindersListID = $0.isEmpty ? nil : $0 }
            )) {
                Text("None").tag("")
                ForEach(remindersService.availableLists, id: \.calendarIdentifier) { list in
                    Text(list.title).tag(list.calendarIdentifier)
                }
            }
            Text("Tasks will be imported from this list into whichever project you choose on the Tasks tab.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Toggle("Mark reminders as completed after import", isOn: Binding(
                get: { appState.remindersMarkCompleted },
                set: { appState.remindersMarkCompleted = $0 }
            ))
        }
    }
}
