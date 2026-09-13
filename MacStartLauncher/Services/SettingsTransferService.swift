import AppKit
import UniformTypeIdentifiers

/// Owns the JSON settings file format and the Open/Save panels used to read and
/// write it.
///
/// Import is deliberately a **replace layout** operation: a valid file is
/// decoded, fully validated, its folders resolved into fresh bookmarks, and the
/// resulting `LauncherPreferences` saved exactly once. Missing applications or
/// folders are reported rather than aborting the whole import.
@MainActor
final class SettingsTransferService {
    private let preferencesStore: PreferencesStoring
    private let folderService: FolderShortcutServicing
    private let fileManager: FileManager

    private lazy var encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    init(
        preferencesStore: PreferencesStoring,
        folderService: FolderShortcutServicing,
        fileManager: FileManager = .default
    ) {
        self.preferencesStore = preferencesStore
        self.folderService = folderService
        self.fileManager = fileManager
    }

    var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    // MARK: - Panels

    /// Presents a save panel and writes the current layout as JSON.
    @discardableResult
    func exportSettings() -> URL? {
        let preferences = preferencesStore.load()
        guard let data = try? exportData(from: preferences) else { return nil }

        let panel = NSSavePanel()
        panel.title = "Export Settings"
        panel.message = "Choose where to save your Start layout."
        panel.nameFieldStringValue = "Start Settings.json"
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    /// Presents an open panel, validates the selection, and replaces the
    /// current layout. Returns `nil` when the user cancels.
    @discardableResult
    func importSettings(knownBundleIdentifiers: Set<String>) throws -> SettingsImportResult? {
        let panel = NSOpenPanel()
        panel.title = "Import Settings"
        panel.message = "Choose a Start settings file to import."
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        let data = try Data(contentsOf: url)
        return try importData(data, knownBundleIdentifiers: knownBundleIdentifiers)
    }

    // MARK: - Pure transfer

    func exportData(from preferences: LauncherPreferences, date: Date = Date()) throws -> Data {
        let export = makeExport(from: preferences, date: date)
        return try encoder.encode(export)
    }

    func makeExport(from preferences: LauncherPreferences, date: Date = Date()) -> SettingsExportV1 {
        let folders = preferences.additionalFolders.compactMap { shortcut -> SettingsExportV1.Layout.Folder? in
            guard let url = folderService.url(for: shortcut) else { return nil }
            return SettingsExportV1.Layout.Folder(
                name: shortcut.name,
                path: displayPath(for: url)
            )
        }

        return SettingsExportV1(
            exportedAt: date,
            appVersion: appVersion,
            layout: SettingsExportV1.Layout(
                pinnedApplications: preferences.pinnedBundleIdentifiers,
                pinnedFolders: folders
            )
        )
    }

    func decode(_ data: Data) throws -> SettingsExportV1 {
        do {
            return try decoder.decode(SettingsExportV1.self, from: data)
        } catch {
            throw SettingsTransferError.decodingFailed
        }
    }

    func validate(_ export: SettingsExportV1) throws {
        guard export.format == SettingsExportV1.formatIdentifier else {
            throw SettingsTransferError.unsupportedFormat(export.format)
        }
        guard export.schemaVersion == SettingsExportV1.currentSchemaVersion else {
            throw SettingsTransferError.unsupportedSchemaVersion(export.schemaVersion)
        }
        guard export.layout.pinnedApplications.count <= SettingsExportV1.maxPinnedApplications else {
            throw SettingsTransferError.tooManyApplications(export.layout.pinnedApplications.count)
        }
        for folder in export.layout.pinnedFolders {
            guard pathURL(for: folder.path) != nil else {
                throw SettingsTransferError.invalidFolderPath(folder.path)
            }
        }
    }

    /// Applies an already-decoded file, saving the new layout once.
    func importData(
        _ data: Data,
        knownBundleIdentifiers: Set<String>
    ) throws -> SettingsImportResult {
        let export = try decode(data)
        try validate(export)
        return try apply(export, knownBundleIdentifiers: knownBundleIdentifiers)
    }

    private func apply(
        _ export: SettingsExportV1,
        knownBundleIdentifiers: Set<String>
    ) throws -> SettingsImportResult {
        var seenPaths = Set<String>()
        var shortcuts: [FolderShortcut] = []
        var missingFolders: [String] = []

        for folder in export.layout.pinnedFolders {
            guard let url = pathURL(for: folder.path) else {
                missingFolders.append(folder.path)
                continue
            }

            let normalizedPath = url.standardizedFileURL.path
            guard seenPaths.insert(normalizedPath).inserted else { continue }

            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
                  isDirectory.boolValue,
                  var shortcut = try? folderService.makeCustomShortcut(from: url) else {
                missingFolders.append(folder.path)
                continue
            }

            if !folder.name.isEmpty {
                shortcut.name = folder.name
            }
            shortcuts.append(shortcut)
        }

        var seenApplications = Set<String>()
        let applications = export.layout.pinnedApplications.filter { identifier in
            !identifier.isEmpty && seenApplications.insert(identifier).inserted
        }
        let limitedApplications = Array(
            applications.prefix(SettingsExportV1.maxPinnedApplications)
        )

        let preferences = LauncherPreferences(
            pinnedBundleIdentifiers: limitedApplications,
            additionalFolders: shortcuts
        )
        preferencesStore.save(preferences)

        let missingApplications = limitedApplications.filter {
            !knownBundleIdentifiers.contains($0)
        }

        return SettingsImportResult(
            pinnedApplications: limitedApplications.count,
            pinnedFolders: shortcuts.count,
            missingApplications: missingApplications,
            missingFolders: missingFolders
        )
    }

    // MARK: - Paths

    func displayPath(for url: URL) -> String {
        let home = fileManager.homeDirectoryForCurrentUser.path
        let path = url.standardizedFileURL.path
        if path == home { return "~" }
        if path.hasPrefix(home + "/") {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }

    func pathURL(for path: String) -> URL? {
        let expanded: String
        if path == "~" {
            expanded = fileManager.homeDirectoryForCurrentUser.path
        } else if path.hasPrefix("~/") {
            expanded = fileManager.homeDirectoryForCurrentUser.path + String(path.dropFirst(1))
        } else if path.hasPrefix("/") {
            expanded = path
        } else {
            return nil
        }
        return URL(fileURLWithPath: expanded, isDirectory: true)
    }
}
