import Foundation
import Observation

/// One cell in a launcher grid.
enum AppGridEntry: Identifiable, Hashable {
    case application(InstalledApplication)
    case category(CategoryGroup, apps: [InstalledApplication])

    var id: String {
        switch self {
        case .application(let application):
            return "app:\(application.id)"
        case .category(let group, _):
            return "category:\(group.id)"
        }
    }

    var application: InstalledApplication? {
        if case .application(let application) = self {
            return application
        }
        return nil
    }

    var categoryGroup: CategoryGroup? {
        if case .category(let group, _) = self {
            return group
        }
        return nil
    }
}

/// Owns the entries of the currently visible grid and the keyboard selection.
@MainActor
@Observable
final class AppGridViewModel {
    static let columnCount = 4

    private(set) var entries: [AppGridEntry] = []
    var selectedIndex: Int?

    var selectedEntry: AppGridEntry? {
        guard let selectedIndex, entries.indices.contains(selectedIndex) else { return nil }
        return entries[selectedIndex]
    }

    func replaceEntries(_ newEntries: [AppGridEntry], preferredSelectionID: String? = nil) {
        entries = newEntries

        guard !newEntries.isEmpty else {
            selectedIndex = nil
            return
        }

        if let preferredSelectionID,
           let index = newEntries.firstIndex(where: { $0.id == preferredSelectionID }) {
            selectedIndex = index
        } else if let selectedIndex, newEntries.indices.contains(selectedIndex) {
            self.selectedIndex = selectedIndex
        } else {
            selectedIndex = 0
        }
    }

    func select(_ entry: AppGridEntry) {
        guard let index = entries.firstIndex(of: entry) else { return }
        selectedIndex = index
    }

    func moveSelection(horizontal: Int, vertical: Int) {
        guard !entries.isEmpty else {
            selectedIndex = nil
            return
        }

        var target = selectedIndex ?? 0
        if horizontal != 0 {
            target += horizontal
        }
        if vertical != 0 {
            target += vertical * Self.columnCount
        }
        selectedIndex = min(max(target, 0), entries.count - 1)
    }

    func resetSelection() {
        selectedIndex = entries.isEmpty ? nil : 0
    }
}
