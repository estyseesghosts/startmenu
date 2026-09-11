import XCTest
@testable import MacStartLauncher

final class PreferencesStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUpWithError() throws {
        suiteName = "com.startmenu.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testLoadReturnsDefaultsWhenNothingStored() {
        let store = PreferencesStore(defaults: defaults)
        let preferences = store.load()

        XCTAssertTrue(preferences.pinnedBundleIdentifiers.isEmpty)
        XCTAssertTrue(preferences.additionalFolders.isEmpty)
    }

    func testSaveAndLoadRoundTrip() {
        let store = PreferencesStore(defaults: defaults)
        let custom = FolderShortcut(
            id: UUID().uuidString,
            kind: .custom,
            name: "Projects",
            bookmarkData: Data([0x01, 0x02, 0x03])
        )
        let preferences = LauncherPreferences(
            pinnedBundleIdentifiers: ["com.example.one", "com.example.two"],
            additionalFolders: [custom]
        )

        store.save(preferences)

        XCTAssertEqual(store.load(), preferences)
    }

    func testCorruptDataFallsBackToDefaults() {
        defaults.set(Data([0x00, 0x01, 0x02]), forKey: "com.startmenu.launcher.preferences")

        let preferences = PreferencesStore(defaults: defaults).load()

        XCTAssertEqual(preferences, LauncherPreferences())
    }

    func testMaximumPinnedApplicationsIsTwelve() {
        XCTAssertEqual(LauncherPreferences.maxPinnedApplications, 12)
    }

    func testCanPinMoreReflectsLimit() {
        let full = LauncherPreferences(
            pinnedBundleIdentifiers: (0..<12).map { "com.example.\($0)" }
        )
        XCTAssertFalse(full.canPinMore)

        let partial = LauncherPreferences(pinnedBundleIdentifiers: ["com.example.0"])
        XCTAssertTrue(partial.canPinMore)
    }
}
