import XCTest
@testable import MacStartLauncher

final class ApplicationDiscoveryTests: XCTestCase {
    private var temporaryDirectory: URL!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let temporaryDirectory {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }
    }

    func testDiscoversApplicationsDirectlyInRoot() throws {
        let root = try makeDirectory(named: "Root")
        _ = try makeApplication(named: "Alpha", in: root)
        _ = try makeApplication(named: "Beta", in: root)

        let applications = makeService(roots: [root]).discoverApplications()

        XCTAssertEqual(applications.map(\.name).sorted(), ["Alpha", "Beta"])
    }

    func testDiscoversApplicationsInOneSubdirectory() throws {
        let root = try makeDirectory(named: "Root")
        let utilities = try makeDirectory(named: "Utilities", in: root)
        _ = try makeApplication(named: "Gamma", in: utilities)

        let applications = makeService(roots: [root]).discoverApplications()

        XCTAssertEqual(applications.map(\.name), ["Gamma"])
    }

    func testDeduplicatesByBundleIdentifierPreferringEarlierRoot() throws {
        let primary = try makeDirectory(named: "Primary")
        let secondary = try makeDirectory(named: "Secondary")
        _ = try makeApplication(named: "Duplicate", in: primary)
        _ = try makeApplication(named: "Duplicate", in: secondary)

        let applications = makeService(roots: [primary, secondary]).discoverApplications()

        XCTAssertEqual(applications.count, 1)
        XCTAssertEqual(applications.first?.url.deletingLastPathComponent().lastPathComponent, "Primary")
    }

    func testIgnoresEmbeddedHelperBundles() throws {
        let root = try makeDirectory(named: "Root")
        let host = try makeApplication(named: "Host", in: root)
        let helper = host
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("Helpers", isDirectory: true)
            .appendingPathComponent("Helper.app", isDirectory: true)
        try FileManager.default.createDirectory(at: helper, withIntermediateDirectories: true)

        let service = makeService(roots: [root], spotlightURLs: [helper])
        let applications = service.discoverApplications()

        XCTAssertEqual(applications.map(\.name), ["Host"])
    }

    func testIgnoresBackgroundOnlyBundles() throws {
        let root = try makeDirectory(named: "Root")
        _ = try makeApplication(named: "Hidden", in: root)
        _ = try makeApplication(named: "Visible", in: root)

        let service = makeService(roots: [root]) { url in
            let name = url.deletingPathExtension().lastPathComponent
            return ApplicationMetadata(
                displayName: name,
                bundleIdentifier: "com.test.\(name.lowercased())",
                rawCategories: [],
                isBackgroundOnly: name == "Hidden",
                packageType: "APPL"
            )
        }

        XCTAssertEqual(service.discoverApplications().map(\.name), ["Visible"])
    }

    func testIgnoresNonApplicationPackageTypes() throws {
        let root = try makeDirectory(named: "Root")
        _ = try makeApplication(named: "Framework", in: root)

        let service = makeService(roots: [root]) { url in
            ApplicationMetadata(
                displayName: "Framework",
                bundleIdentifier: "com.test.framework",
                rawCategories: [],
                isBackgroundOnly: false,
                packageType: "FMWK"
            )
        }

        XCTAssertTrue(service.discoverApplications().isEmpty)
    }

    func testSortsByNameCaseInsensitively() throws {
        let root = try makeDirectory(named: "Root")
        _ = try makeApplication(named: "zebra", in: root)
        _ = try makeApplication(named: "Apple", in: root)

        let applications = makeService(roots: [root]).discoverApplications()

        XCTAssertEqual(applications.map(\.name), ["Apple", "zebra"])
    }

    func testMissingRootIsIgnored() {
        let missing = temporaryDirectory.appendingPathComponent("DoesNotExist", isDirectory: true)
        let applications = makeService(roots: [missing]).discoverApplications()
        XCTAssertTrue(applications.isEmpty)
    }

    // MARK: - Helpers

    private func makeDirectory(named name: String, in parent: URL? = nil) throws -> URL {
        let base = parent ?? temporaryDirectory!
        let url = base.appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @discardableResult
    private func makeApplication(named name: String, in directory: URL) throws -> URL {
        let url = directory.appendingPathComponent("\(name).app", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func defaultMetadata(for url: URL) -> ApplicationMetadata {
        let name = url.deletingPathExtension().lastPathComponent
        return ApplicationMetadata(
            displayName: name,
            bundleIdentifier: "com.test.\(name.lowercased())",
            rawCategories: [],
            isBackgroundOnly: false,
            packageType: "APPL"
        )
    }

    private func makeService(
        roots: [URL],
        spotlightURLs: [URL] = [],
        metadata: ((URL) -> ApplicationMetadata)? = nil
    ) -> ApplicationDiscoveryService {
        let handler = metadata ?? defaultMetadata(for:)
        return ApplicationDiscoveryService(
            roots: roots,
            metadataService: StubMetadataService(handler: handler),
            spotlight: StubSpotlight(urls: spotlightURLs),
            resolver: CategoryResolver()
        )
    }
}

private final class StubMetadataService: ApplicationMetadataProviding {
    private let handler: (URL) -> ApplicationMetadata

    init(handler: @escaping (URL) -> ApplicationMetadata) {
        self.handler = handler
    }

    func metadata(for url: URL) -> ApplicationMetadata {
        handler(url)
    }
}

private struct StubSpotlight: SpotlightSearching {
    var urls: [URL] = []

    func applicationBundleURLs(in roots: [URL]) -> [URL] {
        urls
    }
}
