import SwiftUI

/// A four-column grid that renders application and category entries.
struct AppGridView: View {
    static let columnCount = 4
    static let columns: [GridItem] = Array(
        repeating: GridItem(.flexible(), spacing: 10, alignment: .top),
        count: columnCount
    )

    let entries: [AppGridEntry]
    let selectedID: String?

    var body: some View {
        LazyVGrid(columns: Self.columns, alignment: .leading, spacing: 10) {
            ForEach(entries) { entry in
                switch entry {
                case .application(let application):
                    AppTile(application: application, isSelected: selectedID == entry.id)
                        .id(entry.id)
                case .category(let group, let apps):
                    CategoryTile(
                        overview: CategoryOverview(group: group, apps: apps),
                        isSelected: selectedID == entry.id
                    )
                    .id(entry.id)
                }
            }
        }
    }
}
