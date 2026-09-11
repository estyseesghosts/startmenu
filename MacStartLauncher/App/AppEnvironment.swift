import AppKit
import Observation

/// Composition root for the launcher's application-scoped services and view
/// models.
@MainActor
@Observable
final class AppEnvironment {
    let iconService: ApplicationIconService
    let launcher: LauncherViewModel
    let folders: FolderShortcutsViewModel
    private let changeMonitor: ApplicationChangeMonitor

    init() {
        let preferencesStore = PreferencesStore()
        let resolver = CategoryResolver()
        let discoveryService = ApplicationDiscoveryService(resolver: resolver)
        let launchService = ApplicationLaunchService()
        let folderService = FolderService()

        let launcher = LauncherViewModel(
            discoveryService: discoveryService,
            launchService: launchService,
            preferencesStore: preferencesStore,
            resolver: resolver
        )
        let folders = FolderShortcutsViewModel(
            service: folderService,
            preferencesStore: preferencesStore
        )

        self.iconService = ApplicationIconService()
        self.launcher = launcher
        self.folders = folders
        self.changeMonitor = ApplicationChangeMonitor { [weak launcher] in
            launcher?.refresh()
        }
    }

    /// Performs the first application scan and begins watching for changes.
    func start() {
        launcher.load()
        changeMonitor.start()
    }

    func refreshApplications() {
        launcher.refresh()
    }
}
