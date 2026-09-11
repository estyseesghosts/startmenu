import SwiftUI

/// Shown when a category or search produces no applications.
struct EmptyCategoryView: View {
    let title: String
    let message: String
    var symbolName: String = "magnifyingglass"

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbolName)
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.system(size: 13, weight: .medium))
            Text(message)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
