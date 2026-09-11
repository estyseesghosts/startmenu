import SwiftUI

/// The applications inside one selected category folder.
struct CategoryContentsView: View {
    let group: CategoryGroup
    let applications: [InstalledApplication]
    let selectedID: String?

    var body: some View {
        if applications.isEmpty {
            EmptyCategoryView(
                title: "No Applications",
                message: "No applications were found in \(group.displayName).",
                symbolName: group.symbolName
            )
        } else {
            AppGridView(
                entries: applications.map(AppGridEntry.application),
                selectedID: selectedID
            )
        }
    }
}
