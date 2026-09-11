import AppKit
import Combine
import SwiftUI

/// The launcher search field. Typing filters applications immediately.
struct LauncherSearchField: View {
    @Environment(AppEnvironment.self) private var environment
    @FocusState private var isFocused: Bool

    var body: some View {
        @Bindable var launcher = environment.launcher

        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            TextField("Search apps", text: $launcher.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($isFocused)

            if launcher.isSearching {
                Button {
                    launcher.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .help("Clear search")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.06))
        )
        .onAppear { isFocused = true }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            isFocused = true
        }
    }
}
