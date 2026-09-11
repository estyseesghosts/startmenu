import SwiftUI

/// A plain button style that adds a restrained hover and pressed surface.
///
/// The row behind floating controls stays transparent; only the selected or
/// pressed control draws its own filled surface.
struct HoverButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 8

    func makeBody(configuration: Configuration) -> some View {
        HoverBackground(configuration: configuration, cornerRadius: cornerRadius)
    }

    private struct HoverBackground: View {
        let configuration: Configuration
        let cornerRadius: CGFloat
        @State private var isHovering = false

        var body: some View {
            configuration.label
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(fillColor)
                )
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .onHover { isHovering = $0 }
        }

        private var fillColor: Color {
            if configuration.isPressed {
                return Color.primary.opacity(0.14)
            }
            return isHovering ? Color.primary.opacity(0.08) : .clear
        }
    }
}
