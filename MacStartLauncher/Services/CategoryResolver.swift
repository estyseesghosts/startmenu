import Foundation

/// Maps lower-level Apple application categories into the launcher's
/// Tahoe-style groups.
///
/// This type is deliberately isolated so Apple can change category behavior
/// without forcing changes through the UI.
struct CategoryResolver {
    private let categoryToGroup: [ApplicationCategory: CategoryGroup]

    init() {
        var map: [ApplicationCategory: CategoryGroup] = [:]
        for group in CategoryGroup.allCases {
            for category in group.sourceCategories {
                map[category] = group
            }
        }
        self.categoryToGroup = map
    }

    /// Resolves a single parsed category.
    func group(for category: ApplicationCategory) -> CategoryGroup {
        categoryToGroup[category] ?? .other
    }

    /// Resolves raw metadata values in the order Apple supplied them.
    ///
    /// The first category that maps to a known group wins. Unknown values are
    /// ignored so a later, meaningful category can still be used.
    func group(forRawCategories rawCategories: [String]) -> CategoryGroup {
        for raw in rawCategories {
            let category = ApplicationCategory(metadataValue: raw)
            guard category != .other else { continue }
            if let group = categoryToGroup[category] {
                return group
            }
        }
        return .other
    }
}
