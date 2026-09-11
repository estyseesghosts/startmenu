import AppKit
import CoreServices

/// Raw metadata read from an application bundle.
struct ApplicationMetadata {
    let displayName: String?
    let bundleIdentifier: String?
    let rawCategories: [String]
    let isBackgroundOnly: Bool
    let packageType: String?
}

protocol ApplicationMetadataProviding {
    func metadata(for url: URL) -> ApplicationMetadata
}

/// Reads the application display name, bundle identifier, and category
/// information from the bundle and from public Spotlight metadata.
final class ApplicationMetadataService: ApplicationMetadataProviding {
    func metadata(for url: URL) -> ApplicationMetadata {
        let bundle = Bundle(url: url)

        let displayName = (bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String)

        var rawCategories: [String] = []
        if let declared = bundle?.object(forInfoDictionaryKey: "LSApplicationCategoryType") as? String {
            rawCategories.append(declared)
        }
        if let item = NSMetadataItem(url: url),
           let spotlight = item.value(forAttribute: kMDItemApplicationCategories as String) as? [String] {
            rawCategories.append(contentsOf: spotlight)
        }

        let isBackgroundOnly = (bundle?.object(forInfoDictionaryKey: "LSBackgroundOnly") as? Bool) ?? false
        let packageType = bundle?.object(forInfoDictionaryKey: "CFBundlePackageType") as? String

        return ApplicationMetadata(
            displayName: displayName,
            bundleIdentifier: bundle?.bundleIdentifier,
            rawCategories: rawCategories,
            isBackgroundOnly: isBackgroundOnly,
            packageType: packageType
        )
    }
}
