import Foundation

/// Small, persisted launcher configuration.
///
/// Core Data or SwiftData would be unnecessary here; a single stored model is
/// enough for the first version's scope.
struct LauncherPreferences: Codable, Equatable, Sendable {
    static let maxPinnedApplications = 12

    var pinnedBundleIdentifiers: [String]
    var additionalFolders: [FolderShortcut]

    init(
        pinnedBundleIdentifiers: [String] = [],
        additionalFolders: [FolderShortcut] = []
    ) {
        self.pinnedBundleIdentifiers = pinnedBundleIdentifiers
        self.additionalFolders = additionalFolders
    }

    /// Whether another pin can be added.
    var canPinMore: Bool {
        pinnedBundleIdentifiers.count < Self.maxPinnedApplications
    }
}
