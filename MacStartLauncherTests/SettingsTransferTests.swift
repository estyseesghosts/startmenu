import XCTest
@testable import MacStartLauncher

@MainActor
final class SettingsTransferTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var store: PreferencesStore!
    private var folderService: FolderService!
    private var service: SettingsTransferService!
    private var temporaryDirectories: [URL] = []

    override func setUpWithError() throws {
        suiteName = "com.startmenu.settings.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        store = PreferencesStore(defaults: defaults)
        folderService = FolderService(bookmarkStore: SettingsStubBookmarkStore())
        service = SettingsTransferService(
            preferencesStore: store,
            folderService: folderService
        )
    }

    override func tearDownWithError() throws {
        defaults.removePersistentDomain(forName: suiteName)
        for directory in temporaryDirectories {
            try? FileManager.default.removeItem(at: directory)
        }
    }

    func testRoundTripPreservesOrderAndFolderNames() throws {
        let projects = try makeDirectory(named: "Projects")
        let archive = try makeDirectory(named: "Archive")
        let preferences = LauncherPreferences(
            pinnedBundleIdentifiers: ["com.apple.Safari", "com.apple.Terminal"],
            additionalFolders: [
                try folderService.makeCustomShortcut(from: projects),
                try folderService.makeCustomShortcut(from: archive)
            ]
        )

        let data = try service.exportData(from: preferences)
        store.save(LauncherPreferences())

        let result = try service.importData(
            data,
            knownBundleIdentifiers: ["com.apple.Safari", "com.apple.Terminal"]
        )
        let loaded = store.load()

        XCTAssertEqual(loaded.pinnedBundleIdentifiers, ["com.apple.Safari", "com.apple.Terminal"])
        XCTAssertEqual(loaded.additionalFolders.map(\.name), ["Projects", "Archive"])
        XCTAssertEqual(result.pinnedApplications, 2)
        XCTAssertEqual(result.pinnedFolders, 2)
        XCTAssertFalse(result.hasWarnings)
    }

    func testExportDoesNotIncludeStandardShortcuts() throws {
        let data = try service.exportData(from: LauncherPreferences())

        let export = try service.decode(data)

        XCTAssertTrue(export.layout.pinnedFolders.isEmpty)
        XCTAssertTrue(export.layout.pinnedApplications.isEmpty)
        XCTAssertEqual(export.format, SettingsExportV1.formatIdentifier)
        XCTAssertEqual(export.schemaVersion, 1)
    }

    func testMalformedDataThrowsDecodingFailure() throws {
        XCTAssertThrowsError(try service.importData(Data("not json".utf8), knownBundleIdentifiers: [])) {
            XCTAssertEqual($0 as? SettingsTransferError, .decodingFailed)
        }
    }

    func testUnknownFormatIsRejected() throws {
        let data = try encode(exportData(format: "com.other.settings"))

        XCTAssertThrowsError(try service.importData(data, knownBundleIdentifiers: [])) {
            XCTAssertEqual($0 as? SettingsTransferError, .unsupportedFormat("com.other.settings"))
        }
    }

    func testFutureSchemaVersionIsRejected() throws {
        let data = try encode(exportData(schemaVersion: 99))

        XCTAssertThrowsError(try service.importData(data, knownBundleIdentifiers: [])) {
            XCTAssertEqual($0 as? SettingsTransferError, .unsupportedSchemaVersion(99))
        }
    }

    func testTooManyApplicationsIsRejected() throws {
        let applications = (0..<13).map { "com.example.\($0)" }
        let data = try encode(exportData(applications: applications))

        XCTAssertThrowsError(try service.importData(data, knownBundleIdentifiers: [])) {
            XCTAssertEqual($0 as? SettingsTransferError, .tooManyApplications(13))
        }
    }

    func testMissingApplicationsAreReportedNotFatal() throws {
        let data = try encode(exportData(applications: ["com.apple.Safari", "com.gone.Missing"]))

        let result = try service.importData(data, knownBundleIdentifiers: ["com.apple.Safari"])

        XCTAssertEqual(store.load().pinnedBundleIdentifiers, ["com.apple.Safari", "com.gone.Missing"])
        XCTAssertEqual(result.missingApplications, ["com.gone.Missing"])
    }

    func testMissingFoldersAreReportedNotFatal() throws {
        let missingPath = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .path
        let data = try encode(exportData(folders: [.init(name: "Gone", path: missingPath)]))

        let result = try service.importData(data, knownBundleIdentifiers: [])

        XCTAssertEqual(result.pinnedFolders, 0)
        XCTAssertEqual(result.missingFolders, [missingPath])
        XCTAssertTrue(store.load().additionalFolders.isEmpty)
    }

    func testDuplicateFolderPathsAreRemoved() throws {
        let directory = try makeDirectory(named: "Shared")
        let folder = SettingsExportV1.Layout.Folder(name: "Shared", path: directory.path)
        let data = try encode(exportData(folders: [folder, folder]))

        let result = try service.importData(data, knownBundleIdentifiers: [])

        XCTAssertEqual(result.pinnedFolders, 1)
    }

    func testImportReplacesExistingLayout() throws {
        store.save(LauncherPreferences(
            pinnedBundleIdentifiers: ["com.old.App"],
            additionalFolders: []
        ))
        let data = try encode(exportData(applications: ["com.new.App"]))

        _ = try service.importData(data, knownBundleIdentifiers: ["com.new.App"])

        XCTAssertEqual(store.load().pinnedBundleIdentifiers, ["com.new.App"])
    }

    func testDisplayPathUsesTildeInsideHome() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        XCTAssertEqual(service.displayPath(for: home), "~")
        XCTAssertEqual(
            service.displayPath(for: home.appendingPathComponent("Projects")),
            "~/Projects"
        )
        XCTAssertEqual(service.displayPath(for: URL(fileURLWithPath: "/Volumes/Archive")), "/Volumes/Archive")
    }

    func testPathURLExpandsTildeAndRejectsRelativePaths() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        XCTAssertEqual(service.pathURL(for: "~")?.path, home.path)
        XCTAssertEqual(service.pathURL(for: "~/Projects")?.path, home.appendingPathComponent("Projects").path)
        XCTAssertNil(service.pathURL(for: "relative/path"))
    }

    // MARK: - Helpers

    private func makeDirectory(named name: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        temporaryDirectories.append(directory)
        return directory
    }

    private func exportData(
        format: String = SettingsExportV1.formatIdentifier,
        schemaVersion: Int = SettingsExportV1.currentSchemaVersion,
        applications: [String] = [],
        folders: [SettingsExportV1.Layout.Folder] = []
    ) -> SettingsExportV1 {
        SettingsExportV1(
            format: format,
            schemaVersion: schemaVersion,
            exportedAt: Date(),
            appVersion: "1.0",
            layout: SettingsExportV1.Layout(
                pinnedApplications: applications,
                pinnedFolders: folders
            )
        )
    }

    private func encode(_ export: SettingsExportV1) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(export)
    }
}

private final class SettingsStubBookmarkStore: BookmarkStoring {
    func makeBookmark(for url: URL) throws -> Data {
        Data(url.path.utf8)
    }

    func resolve(_ bookmarkData: Data) throws -> ResolvedBookmark {
        ResolvedBookmark(
            url: URL(fileURLWithPath: String(decoding: bookmarkData, as: UTF8.self)),
            isStale: false
        )
    }
}
