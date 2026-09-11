import Foundation

protocol ApplicationDiscovering {
    func discoverApplications() -> [InstalledApplication]
}

/// Finds launchable `.app` bundles and builds a stable `[InstalledApplication]`.
///
/// Spotlight metadata supplements a shallow scan of the standard application
/// locations. Embedded helpers (`.app` bundles living inside another bundle)
/// and background-only bundles are never treated as installed applications.
final class ApplicationDiscoveryService: ApplicationDiscovering {
    private let roots: [URL]
    private let metadataService: ApplicationMetadataProviding
    private let spotlight: SpotlightSearching
    private let resolver: CategoryResolver
    private let fileManager: FileManager

    init(
        roots: [URL] = ApplicationDiscoveryService.defaultRoots(),
        metadataService: ApplicationMetadataProviding = ApplicationMetadataService(),
        spotlight: SpotlightSearching = SpotlightApplicationSearch(),
        resolver: CategoryResolver = CategoryResolver(),
        fileManager: FileManager = .default
    ) {
        self.roots = roots
        self.metadataService = metadataService
        self.spotlight = spotlight
        self.resolver = resolver
        self.fileManager = fileManager
    }

    static func defaultRoots() -> [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            URL(fileURLWithPath: "/System/Applications", isDirectory: true),
            home.appendingPathComponent("Applications", isDirectory: true)
        ]
    }

    func discoverApplications() -> [InstalledApplication] {
        var candidates: [URL] = []
        candidates.append(contentsOf: scannedBundleURLs())
        candidates.append(contentsOf: spotlight.applicationBundleURLs(in: roots))

        var bestByBundleIdentifier: [String: (rank: Int, application: InstalledApplication)] = [:]

        for url in candidates {
            guard !isEmbedded(url) else { continue }
            guard let application = makeApplication(from: url) else { continue }

            let rank = rootRank(for: url)
            if let existing = bestByBundleIdentifier[application.bundleIdentifier] {
                if rank < existing.rank {
                    bestByBundleIdentifier[application.bundleIdentifier] = (rank, application)
                }
            } else {
                bestByBundleIdentifier[application.bundleIdentifier] = (rank, application)
            }
        }

        return bestByBundleIdentifier.values
            .map(\.application)
            .sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
    }

    private func makeApplication(from url: URL) -> InstalledApplication? {
        let metadata = metadataService.metadata(for: url)

        guard let bundleIdentifier = metadata.bundleIdentifier, !bundleIdentifier.isEmpty else {
            return nil
        }
        guard !metadata.isBackgroundOnly else { return nil }
        if let packageType = metadata.packageType, packageType != "APPL" {
            return nil
        }

        let name = metadata.displayName ?? url.deletingPathExtension().lastPathComponent
        let group = resolver.group(forRawCategories: metadata.rawCategories)

        return InstalledApplication(
            name: name,
            url: url,
            bundleIdentifier: bundleIdentifier,
            rawCategories: metadata.rawCategories,
            group: group
        )
    }

    /// Top level of each root plus exactly one level of subdirectories, without
    /// descending into packages.
    private func scannedBundleURLs() -> [URL] {
        var result: [URL] = []
        for root in roots {
            guard let entries = try? fileManager.contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else {
                continue
            }

            for entry in entries {
                if isApplicationBundle(entry) {
                    result.append(entry)
                } else if isDirectory(entry),
                          let children = try? fileManager.contentsOfDirectory(
                              at: entry,
                              includingPropertiesForKeys: [.isDirectoryKey],
                              options: [.skipsHiddenFiles, .skipsPackageDescendants]
                          ) {
                    result.append(contentsOf: children.filter(isApplicationBundle))
                }
            }
        }
        return result
    }

    private func isApplicationBundle(_ url: URL) -> Bool {
        url.pathExtension.lowercased() == "app"
    }

    private func isDirectory(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
    }

    /// True when the bundle lives inside another `.app` bundle.
    private func isEmbedded(_ url: URL) -> Bool {
        url.pathComponents.dropLast().contains { $0.hasSuffix(".app") }
    }

    private func rootRank(for url: URL) -> Int {
        let path = url.standardizedFileURL.path
        for (index, root) in roots.enumerated() {
            let rootPath = root.standardizedFileURL.path
            if path.hasPrefix(rootPath + "/") || path == rootPath {
                return index
            }
        }
        return roots.count
    }
}
