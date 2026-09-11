import AppKit

/// Obtains native application icons through `NSWorkspace` and caches them.
///
/// Icons are never extracted from arbitrary PNG resources inside bundles.
@MainActor
final class ApplicationIconService {
    private let cache = NSCache<NSString, NSImage>()

    func icon(for url: URL) -> NSImage {
        let key = url.path as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 64, height: 64)
        cache.setObject(icon, forKey: key)
        return icon
    }

    func icon(for application: InstalledApplication) -> NSImage {
        icon(for: application.url)
    }

    func folderIcon(for url: URL) -> NSImage {
        icon(for: url)
    }

    func symbolImage(named name: String) -> NSImage? {
        NSImage(systemSymbolName: name, accessibilityDescription: nil)
    }
}
