import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState
        Form {
            Section {
                Toggle("Sync with iCloud", isOn: Binding(
                    get: { appState.isCloudSyncEnabled },
                    set: { appState.isCloudSyncEnabled = $0 }
                ))
                Text("Enables CloudKit sync across your Macs. Restart the app after changing this setting for it to take effect. Foundation for a future iOS companion app.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            } header: {
                Text("Sync")
            }

            Section {
                LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
            } header: {
                Text("About")
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 200)
    }
}
