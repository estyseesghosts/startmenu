import Foundation
import Observation

/// A resolved category folder and its member applications.
struct CategoryOverview: Identifiable, Hashable {
    let group: CategoryGroup
    let apps: [InstalledApplication]

    var id: String { group.id }
}

/// Owns the left-pane data, search, and navigation for one launcher session.
@MainActor
@Observable
final class LauncherViewModel {
    enum Navigation: Equatable {
        case main
        case group(CategoryGroup)
    }

    private let discoveryService: ApplicationDiscovering
    private let launchService: ApplicationLaunching
    private let preferencesStore: PreferencesStoring
    private let resolver: CategoryResolver

    let grid: AppGridViewModel

    private(set) var applications: [InstalledApplication] = []
    private(set) var pinnedBundleIdentifiers: [String] = []
    private(set) var isLoaded = false

    var searchText: String = "" {
        didSet { rebuildEntries() }
    }

    var navigation: Navigation = .main {
        didSet { rebuildEntries() }
    }

    /// Invoked when the launcher should dismiss itself.
    var requestClose: (() -> Void)?

    init(
        discoveryService: ApplicationDiscovering,
        launchService: ApplicationLaunching,
        preferencesStore: PreferencesStoring,
        resolver: CategoryResolver = CategoryResolver(),
        grid: AppGridViewModel? = nil
    ) {
        self.discoveryService = discoveryService
        self.launchService = launchService
        self.preferencesStore = preferencesStore
        self.resolver = resolver
        self.grid = grid ?? AppGridViewModel()
        self.pinnedBundleIdentifiers = preferencesStore.load().pinnedBundleIdentifiers
    }

    // MARK: - Derived data

    var pinnedApplications: [InstalledApplication] {
        let byIdentifier = Dictionary(uniqueKeysWithValues: applications.map { ($0.id, $0) })
        return pinnedBundleIdentifiers.compactMap { byIdentifier[$0] }
    }

    var categoryOverviews: [CategoryOverview] {
        let grouped = Dictionary(grouping: applications, by: \.group)
        return CategoryGroup.allCases.compactMap { group in
            guard let apps = grouped[group], !apps.isEmpty else { return nil }
            return CategoryOverview(group: group, apps: apps)
        }
    }

    var navigationTitle: String? {
        if case .group(let group) = navigation {
            return group.displayName
        }
        return nil
    }

    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canPinMore: Bool {
        pinnedBundleIdentifiers.count < LauncherPreferences.maxPinnedApplications
    }

    func applications(in group: CategoryGroup) -> [InstalledApplication] {
        applications.filter { $0.group == group }
    }

    func isPinned(_ application: InstalledApplication) -> Bool {
        pinnedBundleIdentifiers.contains(application.id)
    }

    // MARK: - Loading

    func load() {
        applications = discoveryService.discoverApplications()
        removeStalePins()
        isLoaded = true
        rebuildEntries()
    }

    func refresh() {
        load()
    }

    private func removeStalePins() {
        let knownIdentifiers = Set(applications.map(\.id))
        let cleaned = pinnedBundleIdentifiers.filter { knownIdentifiers.contains($0) }
        guard cleaned != pinnedBundleIdentifiers else { return }
        pinnedBundleIdentifiers = cleaned
        persistPins()
    }

    // MARK: - Entry composition

    private func rebuildEntries() {
        if isSearching {
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matches = applications.filter {
                $0.name.localizedCaseInsensitiveContains(query)
                    || $0.bundleIdentifier.localizedCaseInsensitiveContains(query)
            }
            grid.replaceEntries(matches.map(AppGridEntry.application))
            return
        }

        switch navigation {
        case .main:
            var entries = pinnedApplications.map(AppGridEntry.application)
            entries.append(contentsOf: categoryOverviews.map {
                AppGridEntry.category($0.group, apps: $0.apps)
            })
            grid.replaceEntries(entries)
        case .group(let group):
            let apps = applications(in: group)
            grid.replaceEntries(apps.map(AppGridEntry.application))
        }
    }

    // MARK: - Activation

    func activateSelected() {
        guard let entry = grid.selectedEntry else { return }
        activate(entry)
    }

    func activate(_ entry: AppGridEntry) {
        switch entry {
        case .application(let application):
            open(application)
        case .category(let group, _):
            navigation = .group(group)
        }
    }

    func open(_ application: InstalledApplication) {
        launchService.launch(application) { [weak self] in
            self?.requestClose?()
        }
    }

    // MARK: - Navigation

    func goBack() {
        if isSearching {
            searchText = ""
            return
        }
        if case .group = navigation {
            navigation = .main
        }
    }

    func handle(_ command: LauncherKeyCommand) {
        switch command {
        case .escape:
            if isSearching {
                searchText = ""
            } else if case .group = navigation {
                navigation = .main
            } else {
                requestClose?()
            }
        case .submit:
            activateSelected()
        case .up:
            grid.moveSelection(horizontal: 0, vertical: -1)
        case .down:
            grid.moveSelection(horizontal: 0, vertical: 1)
        case .left:
            grid.moveSelection(horizontal: -1, vertical: 0)
        case .right:
            grid.moveSelection(horizontal: 1, vertical: 0)
        }
    }

    // MARK: - Pinning

    func pin(_ application: InstalledApplication) {
        guard !isPinned(application), canPinMore else { return }
        pinnedBundleIdentifiers.append(application.id)
        persistPins()
        rebuildEntries()
    }

    func unpin(_ application: InstalledApplication) {
        guard isPinned(application) else { return }
        pinnedBundleIdentifiers.removeAll { $0 == application.id }
        persistPins()
        rebuildEntries()
    }

    func togglePin(_ application: InstalledApplication) {
        isPinned(application) ? unpin(application) : pin(application)
    }

    func movePin(id: String, before targetID: String) {
        guard id != targetID,
              let source = pinnedBundleIdentifiers.firstIndex(of: id),
              let target = pinnedBundleIdentifiers.firstIndex(of: targetID) else {
            return
        }
        pinnedBundleIdentifiers.remove(at: source)
        let insertionIndex = source < target ? target - 1 : target
        pinnedBundleIdentifiers.insert(id, at: insertionIndex)
        persistPins()
        rebuildEntries()
    }

    private func persistPins() {
        var preferences = preferencesStore.load()
        preferences.pinnedBundleIdentifiers = Array(
            pinnedBundleIdentifiers.prefix(LauncherPreferences.maxPinnedApplications)
        )
        pinnedBundleIdentifiers = preferences.pinnedBundleIdentifiers
        preferencesStore.save(preferences)
    }
}
