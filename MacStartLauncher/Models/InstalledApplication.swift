import Foundation

/// A launchable application discovered on the machine.
///
/// Identity is the bundle identifier, not the file path, so an application can
/// move while keeping the same identity for pin persistence.
struct InstalledApplication: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let url: URL
    let bundleIdentifier: String
    let rawCategories: [String]
    let group: CategoryGroup

    init(
        name: String,
        url: URL,
        bundleIdentifier: String,
        rawCategories: [String],
        group: CategoryGroup
    ) {
        self.id = bundleIdentifier
        self.name = name
        self.url = url
        self.bundleIdentifier = bundleIdentifier
        self.rawCategories = rawCategories
        self.group = group
    }
}
