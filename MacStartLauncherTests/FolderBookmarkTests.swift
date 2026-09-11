import XCTest
@testable import MacStartLauncher

final class FolderBookmarkTests: XCTestCase {
    func testStandardHomeShortcutResolvesToHomeDirectory() throws {
        let service = FolderService(bookmarkStore: StubBookmarkStore())
        let home = FolderShortcut(id: "home", kind: .home, name: "Home")

        let url = try XCTUnwrap(service.url(for: home))

        XCTAssertEqual(
            url.standardizedFileURL,
            FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL
        )
    }

    func testCustomShortcutResolvesThroughBookmark() throws {
        let bookmarkStore = StubBookmarkStore(
            resolve: { _ in ResolvedBookmark(url: URL(fileURLWithPath: "/tmp/bookmarked"), isStale: false) }
        )
        let service = FolderService(bookmarkStore: bookmarkStore)
        let shortcut = FolderShortcut(
            id: "custom",
            kind: .custom,
            name: "Bookmarked",
            bookmarkData: Data("bookmark".utf8)
        )

        let url = try XCTUnwrap(service.url(for: shortcut))

        XCTAssertEqual(url.path, "/tmp/bookmarked")
    }

    func testCustomShortcutWithoutBookmarkDoesNotResolve() {
        let service = FolderService(bookmarkStore: StubBookmarkStore())
        let shortcut = FolderShortcut(id: "custom", kind: .custom, name: "Missing")

        XCTAssertNil(service.url(for: shortcut))
    }

    func testMakeCustomShortcutStoresBookmarkAndName() throws {
        let service = FolderService(bookmarkStore: StubBookmarkStore())
        let url = URL(fileURLWithPath: "/tmp/Projects", isDirectory: true)

        let shortcut = try service.makeCustomShortcut(from: url)

        XCTAssertEqual(shortcut.kind, .custom)
        XCTAssertEqual(shortcut.name, "Projects")
        XCTAssertEqual(shortcut.bookmarkData, Data("/tmp/Projects".utf8))
    }

    func testRefreshRegeneratesStaleBookmark() throws {
        let bookmarkStore = StubBookmarkStore(
            resolve: { _ in ResolvedBookmark(url: URL(fileURLWithPath: "/tmp/moved"), isStale: true) }
        )
        let service = FolderService(bookmarkStore: bookmarkStore)
        let shortcut = FolderShortcut(
            id: "custom",
            kind: .custom,
            name: "Old",
            bookmarkData: Data("/tmp/old".utf8)
        )

        let updated = try XCTUnwrap(service.refresh(shortcut))

        XCTAssertEqual(updated.name, "moved")
        XCTAssertEqual(updated.bookmarkData, Data("/tmp/moved".utf8))
    }

    func testRefreshKeepsFreshBookmark() throws {
        let bookmarkStore = StubBookmarkStore(
            resolve: { _ in ResolvedBookmark(url: URL(fileURLWithPath: "/tmp/current"), isStale: false) }
        )
        let service = FolderService(bookmarkStore: bookmarkStore)
        let shortcut = FolderShortcut(
            id: "custom",
            kind: .custom,
            name: "Current",
            bookmarkData: Data("/tmp/current".utf8)
        )

        XCTAssertEqual(service.refresh(shortcut), shortcut)
    }

    func testRefreshReturnsNilWhenResolutionFails() {
        let bookmarkStore = StubBookmarkStore(
            resolve: { _ in throw NSError(domain: "test", code: 1) }
        )
        let service = FolderService(bookmarkStore: bookmarkStore)
        let shortcut = FolderShortcut(
            id: "custom",
            kind: .custom,
            name: "Gone",
            bookmarkData: Data("stale".utf8)
        )

        XCTAssertNil(service.refresh(shortcut))
    }

    func testLiveSecurityScopedBookmarkRoundTrip() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = SecurityScopedBookmarkStore()
        let data = try store.makeBookmark(for: directory)
        let resolved = try store.resolve(data)

        XCTAssertEqual(resolved.url.standardizedFileURL, directory.standardizedFileURL)
    }
}

private final class StubBookmarkStore: BookmarkStoring {
    private let makeBookmarkHandler: (URL) throws -> Data
    private let resolveHandler: (Data) throws -> ResolvedBookmark

    init(
        makeBookmark: @escaping (URL) throws -> Data = { Data($0.path.utf8) },
        resolve: @escaping (Data) throws -> ResolvedBookmark = {
            ResolvedBookmark(url: URL(fileURLWithPath: String(decoding: $0, as: UTF8.self)), isStale: false)
        }
    ) {
        self.makeBookmarkHandler = makeBookmark
        self.resolveHandler = resolve
    }

    func makeBookmark(for url: URL) throws -> Data {
        try makeBookmarkHandler(url)
    }

    func resolve(_ bookmarkData: Data) throws -> ResolvedBookmark {
        try resolveHandler(bookmarkData)
    }
}
