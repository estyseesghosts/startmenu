import Foundation

/// The versioned, external representation of a launcher layout.
///
/// This deliberately does **not** mirror `LauncherPreferences`. The persisted
/// model stores security-scoped bookmark bytes and generated UUIDs, which are
/// implementation details that must not leak into a human-readable transfer
/// file. Exporting instead records bundle identifiers and portable folder
/// paths, and importing rebuilds fresh bookmarks through `FolderService`.
struct SettingsExportV1: Codable, Equatable, Sendable {
    static let formatIdentifier = "com.startmenu.settings"
    static let currentSchemaVersion = 1
    static let maxPinnedApplications = 12

    struct Layout: Codable, Equatable, Sendable {
        struct Folder: Codable, Equatable, Sendable {
            var name: String
            var path: String
        }

        var pinnedApplications: [String]
        var pinnedFolders: [Folder]
    }

    var format: String
    var schemaVersion: Int
    var exportedAt: Date
    var appVersion: String?
    var layout: Layout

    init(
        format: String = SettingsExportV1.formatIdentifier,
        schemaVersion: Int = SettingsExportV1.currentSchemaVersion,
        exportedAt: Date = Date(),
        appVersion: String? = nil,
        layout: Layout
    ) {
        self.format = format
        self.schemaVersion = schemaVersion
        self.exportedAt = exportedAt
        self.appVersion = appVersion
        self.layout = layout
    }
}

/// The outcome of validating and applying an imported settings file.
struct SettingsImportResult: Equatable, Sendable {
    var pinnedApplications: Int
    var pinnedFolders: Int
    /// Bundle identifiers that were imported but are not installed locally.
    var missingApplications: [String]
    /// Folder paths that could not be resolved or no longer exist.
    var missingFolders: [String]

    var hasWarnings: Bool {
        !missingApplications.isEmpty || !missingFolders.isEmpty
    }
}

/// Errors surfaced while reading or validating an import file.
enum SettingsTransferError: Error, LocalizedError, Equatable {
    case unsupportedFormat(String)
    case unsupportedSchemaVersion(Int)
    case tooManyApplications(Int)
    case invalidFolderPath(String)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let format):
            return "This file is not a Start settings file (found “\(format)”)."
        case .unsupportedSchemaVersion(let version):
            return "This settings file uses schema version \(version), which this version of Start cannot read."
        case .tooManyApplications(let count):
            return "This settings file pins \(count) applications, but the maximum is \(SettingsExportV1.maxPinnedApplications)."
        case .invalidFolderPath(let path):
            return "“\(path)” is not a valid folder path."
        case .decodingFailed:
            return "The settings file could not be read."
        }
    }
}
