import SwiftUI

/// The left pane: pinned applications, category folders, category contents,
/// search results, and the search field.
struct AppPaneView: View {
    @Environment(AppEnvironment.self) private var environment

    private var launcher: LauncherViewModel { environment.launcher }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            content
            LauncherSearchField()
                .padding(.top, 12)
        }
    }

    @ViewBuilder
    private var header: some View {
        if let title = launcher.navigationTitle {
            HStack(spacing: 6) {
                Button {
                    launcher.navigation = .main
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(title)
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                }
                .buttonStyle(HoverButtonStyle(cornerRadius: 7))
                .accessibilityIdentifier("backToCategories")

                Spacer()
            }
            .padding(.bottom, 12)
        } else {
            HStack {
                Text("Start")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.bottom, 12)
        }
    }

    @ViewBuilder
    private var content: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Group {
                    if launcher.isSearching {
                        if launcher.grid.entries.isEmpty {
                            EmptyCategoryView(
                                title: "No Results",
                                message: "No applications match “\(launcher.searchText)”."
                            )
                        } else {
                            AppGridView(
                                entries: launcher.grid.entries,
                                selectedID: launcher.grid.selectedEntry?.id
                            )
                        }
                    } else {
                        switch launcher.navigation {
                        case .main:
                            VStack(alignment: .leading, spacing: 18) {
                                PinnedAppsView()
                                CategoryGridView()
                            }
                        case .group(let group):
                            CategoryContentsView(
                                group: group,
                                applications: launcher.applications(in: group),
                                selectedID: launcher.grid.selectedEntry?.id
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)
            }
            .onChange(of: launcher.grid.selectedEntry?.id) { _, id in
                guard let id else { return }
                withAnimation(.easeOut(duration: 0.15)) {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
        }
    }
}
