import SwiftUI

/// The root Liquid Glass surface that combines the left and right panes.
struct LauncherRootView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            AppPaneView()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.trailing, 16)

            Divider()
                .overlay(Color.primary.opacity(0.06))

            FolderPaneView()
                .frame(width: 240)
                .padding(.leading, 16)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .glassLauncherBackground()
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
}
