import Foundation
import Sparkle

@MainActor
final class UpdaterService: ObservableObject {
    static let shared = UpdaterService()

    private let updaterController: SPUStandardUpdaterController

    private init() {
        self.updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    func checkForUpdates() {
        updaterController.updater.checkForUpdates()
    }
}
