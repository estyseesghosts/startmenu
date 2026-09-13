import XCTest
@testable import MacStartLauncher

/// Regression tests for the dismissal contract: internal controls must never
/// close the launcher; only deliberate actions (opening an app or folder,
/// pressing Escape at the root) request a close.
@MainActor
final class DismissalTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var store: PreferencesStore!

    override func setUpWithError() throws {
        suiteName = "com.startmenu.dismissal.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        store = PreferencesStore(defaults: defaults)
    }

    override func tearDownWithError() throws {
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testOpeningApplicationRequestsClose() {
        let launchService = RecordingLaunchService()
        let launcher = makeLauncher(launchService: launchService)
        var closeRequests = 0
        launcher.requestClose = { closeRequests += 1 }

        launcher.open(makeApplication())

        XCTAssertEqual(launchService.launchCount, 1)
        XCTAssertEqual(closeRequests, 1)
    }

    func testSelectingCategoryDoesNotRequestClose() {
        let launcher = makeLauncher()
        var closeRequests = 0
        launcher.requestClose = { closeRequests += 1 }

        launcher.activate(.category(.utilities, apps: [makeApplication()]))

        XCTAssertEqual(launcher.navigation, .group(.utilities))
        XCTAssertEqual(closeRequests, 0)
    }

    func testPinningDoesNotRequestClose() {
        let launcher = makeLauncher()
        var closeRequests = 0
        launcher.requestClose = { closeRequests += 1 }

        launcher.togglePin(makeApplication())

        XCTAssertEqual(closeRequests, 0)
        XCTAssertEqual(launcher.pinnedBundleIdentifiers, ["com.test.app"])
    }

    func testEscapeAtRootRequestsClose() {
        let launcher = makeLauncher()
        var closeRequests = 0
        launcher.requestClose = { closeRequests += 1 }

        launcher.handle(.escape)

        XCTAssertEqual(closeRequests, 1)
    }

    func testEscapeInsideCategoryOnlyNavigatesBack() {
        let launcher = makeLauncher()
        var closeRequests = 0
        launcher.requestClose = { closeRequests += 1 }

        launcher.navigation = .group(.utilities)
        launcher.handle(.escape)

        XCTAssertEqual(launcher.navigation, .main)
        XCTAssertEqual(closeRequests, 0)
    }

    func testEscapeDuringSearchClearsQueryWithoutClosing() {
        let launcher = makeLauncher()
        var closeRequests = 0
        launcher.requestClose = { closeRequests += 1 }
        launcher.searchText = "test"

        launcher.handle(.escape)

        XCTAssertEqual(launcher.searchText, "")
        XCTAssertEqual(closeRequests, 0)
    }

    func testSubmitOpensSelectedSearchResult() {
        let launchService = RecordingLaunchService()
        let application = makeApplication()
        let launcher = makeLauncher(
            discoveryService: StubDiscoveryService(applications: [application]),
            launchService: launchService
        )
        launcher.load()
        launcher.searchText = "test"

        launcher.handle(.submit)

        XCTAssertEqual(launchService.launchCount, 1)
    }

    func testArrowCommandsMoveSelectionDuringSearch() {
        let applications = [
            makeApplication(name: "Test One", bundleIdentifier: "com.test.one"),
            makeApplication(name: "Test Two", bundleIdentifier: "com.test.two")
        ]
        let launcher = makeLauncher(
            discoveryService: StubDiscoveryService(applications: applications)
        )
        launcher.load()
        launcher.searchText = "test"

        launcher.handle(.right)

        XCTAssertEqual(launcher.grid.selectedEntry?.id, "app:com.test.two")
    }

    func testOpeningFolderRequestsClose() {
        let folderService = RecordingFolderService()
        let folders = FolderShortcutsViewModel(service: folderService, preferencesStore: store)
        var closeRequests = 0
        folders.requestClose = { closeRequests += 1 }

        folders.open(makeShortcut())

        XCTAssertEqual(folderService.openCount, 1)
        XCTAssertEqual(closeRequests, 1)
    }

    func testAddingFolderDoesNotRequestClose() {
        let folderService = RecordingFolderService()
        let folders = FolderShortcutsViewModel(service: folderService, preferencesStore: store)
        var closeRequests = 0
        folders.requestClose = { closeRequests += 1 }

        folders.addFolder(at: URL(fileURLWithPath: "/tmp/Added", isDirectory: true))

        XCTAssertEqual(closeRequests, 0)
        XCTAssertEqual(folders.customShortcuts.count, 1)
    }

    // MARK: - Helpers

    private func makeLauncher(
        discoveryService: ApplicationDiscovering = EmptyDiscoveryService(),
        launchService: ApplicationLaunching = RecordingLaunchService()
    ) -> LauncherViewModel {
        LauncherViewModel(
            discoveryService: discoveryService,
            launchService: launchService,
            preferencesStore: store
        )
    }

    private func makeApplication(
        name: String = "Test",
        bundleIdentifier: String = "com.test.app"
    ) -> InstalledApplication {
        InstalledApplication(
            name: name,
            url: URL(fileURLWithPath: "/Applications/Test.app"),
            bundleIdentifier: bundleIdentifier,
            rawCategories: [],
            group: .other
        )
    }

    private func makeShortcut() -> FolderShortcut {
        FolderShortcut(id: "custom", kind: .custom, name: "Folder", bookmarkData: Data())
    }
}

private struct EmptyDiscoveryService: ApplicationDiscovering {
    func discoverApplications() -> [InstalledApplication] { [] }
}

private struct StubDiscoveryService: ApplicationDiscovering {
    let applications: [InstalledApplication]

    func discoverApplications() -> [InstalledApplication] { applications }
}

private final class RecordingLaunchService: ApplicationLaunching {
    private(set) var launchCount = 0

    func launch(_ application: InstalledApplication, completion: @escaping () -> Void) {
        launchCount += 1
        completion()
    }
}

private final class RecordingFolderService: FolderShortcutServicing {
    private(set) var openCount = 0

    func url(for shortcut: FolderShortcut) -> URL? {
        URL(fileURLWithPath: "/tmp/Folder")
    }

    func open(_ shortcut: FolderShortcut) {
        openCount += 1
    }

    func reveal(_ shortcut: FolderShortcut) {}

    func makeCustomShortcut(from url: URL) throws -> FolderShortcut {
        FolderShortcut(id: UUID().uuidString, kind: .custom, name: url.lastPathComponent)
    }

    func refresh(_ shortcut: FolderShortcut) -> FolderShortcut? { shortcut }
}
