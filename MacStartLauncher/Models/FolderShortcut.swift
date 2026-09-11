import Foundation

/// A shortcut shown in the right-hand folder pane.
///
/// Standard shortcuts are resolved dynamically from `FileManager`. Custom
/// shortcuts persist a security-scoped bookmark so the architecture has a clean
/// path to App Sandbox support later instead of storing fragile paths.
struct FolderShortcut: Identifiable, Codable, Hashable, Sendable {
    enum Kind: String, Codable, Sendable {
        case home
        case documents
        case desktop
        case downloads
        case custom
    }

    let id: String
    var kind: Kind
    var name: String
    var bookmarkData: Data?

    var isCustom: Bool { kind == .custom }

    init(id: String, kind: Kind, name: String, bookmarkData: Data? = nil) {
        self.id = id
        self.kind = kind
        self.name = name
        self.bookmarkData = bookmarkData
    }

    /// The built-in shortcuts, in the order the framework specifies.
    static func standardShortcuts() -> [FolderShortcut] {
        [
            FolderShortcut(id: Kind.home.rawValue, kind: .home, name: "Home"),
            FolderShortcut(id: Kind.documents.rawValue, kind: .documents, name: "Documents"),
            FolderShortcut(id: Kind.desktop.rawValue, kind: .desktop, name: "Desktop"),
            FolderShortcut(id: Kind.downloads.rawValue, kind: .downloads, name: "Downloads")
        ]
    }
}
