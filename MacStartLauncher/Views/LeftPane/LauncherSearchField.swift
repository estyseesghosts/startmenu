import AppKit
import SwiftUI

/// The standalone launcher search field.
///
/// It wraps a native `NSSearchField` so the control keeps macOS search metrics
/// and behavior (magnifier, clear button, immediate filtering). Its visual
/// surface is supplied by the surrounding glass component, so the field itself
/// is borderless rather than drawing a second pill.
struct LauncherSearchField: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        @Bindable var launcher = environment.launcher

        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            SearchField(
                text: $launcher.searchText,
                onKeyCommand: launcher.handle
            )
            .frame(maxWidth: .infinity)
        }
            .padding(.horizontal, 14)
    }
}

private struct SearchField: NSViewRepresentable {
    @Binding var text: String
    let onKeyCommand: (LauncherKeyCommand) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onKeyCommand: onKeyCommand)
    }

    func makeNSView(context: Context) -> NSSearchField {
        let field = FocusedSearchField()
        field.placeholderString = "Search applications"
        field.setAccessibilityIdentifier("launcherSearchField")
        field.font = .systemFont(ofSize: 13)
        field.isBezeled = false
        field.drawsBackground = false
        field.backgroundColor = .clear
        field.focusRingType = .none
        field.sendsSearchStringImmediately = true
        (field.cell as? NSSearchFieldCell)?.searchButtonCell = nil
        field.delegate = context.coordinator
        field.target = context.coordinator
        field.action = #selector(Coordinator.handleAction(_:))
        field.keyCommandHandler = { [weak coordinator = context.coordinator] command in
            coordinator?.onKeyCommand(command)
        }
        context.coordinator.startObserving(field: field)
        return field
    }

    func updateNSView(_ field: NSSearchField, context: Context) {
        context.coordinator.onKeyCommand = onKeyCommand
        if field.stringValue != text {
            field.stringValue = text
        }
    }

    final class Coordinator: NSObject, NSSearchFieldDelegate {
        @Binding var text: String
        var onKeyCommand: (LauncherKeyCommand) -> Void
        private var observer: NSObjectProtocol?

        init(
            text: Binding<String>,
            onKeyCommand: @escaping (LauncherKeyCommand) -> Void
        ) {
            self._text = text
            self.onKeyCommand = onKeyCommand
        }

        func startObserving(field: NSSearchField) {
            observer = NotificationCenter.default.addObserver(
                forName: NSWindow.didBecomeKeyNotification,
                object: nil,
                queue: .main
            ) { [weak field] _ in
                guard let field, field.window?.isKeyWindow == true else { return }
                field.window?.makeFirstResponder(field)
            }
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSSearchField else { return }
            text = field.stringValue
        }

        func control(
            _ control: NSControl,
            textView: NSTextView,
            doCommandBy commandSelector: Selector
        ) -> Bool {
            switch commandSelector {
            case #selector(NSResponder.moveLeft(_:)):
                onKeyCommand(.left)
            case #selector(NSResponder.moveRight(_:)):
                onKeyCommand(.right)
            case #selector(NSResponder.moveUp(_:)):
                onKeyCommand(.up)
            case #selector(NSResponder.moveDown(_:)):
                onKeyCommand(.down)
            case #selector(NSResponder.insertNewline(_:)):
                onKeyCommand(.submit)
            case #selector(NSResponder.cancelOperation(_:)):
                onKeyCommand(.escape)
            default:
                return false
            }
            return true
        }

        @objc func handleAction(_ sender: NSSearchField) {
            text = sender.stringValue
        }

        deinit {
            if let observer {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}

/// A search field that takes keyboard focus as soon as it is placed in a key
/// window, so the launcher is ready to type into the moment it opens.
private final class FocusedSearchField: NSSearchField {
    var keyCommandHandler: ((LauncherKeyCommand) -> Void)?

    override func keyDown(with event: NSEvent) {
        if let command = LauncherKeyCommand.from(event: event) {
            keyCommandHandler?(command)
            return
        }
        super.keyDown(with: event)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window, window.isKeyWindow else { return }
        window.makeFirstResponder(self)
    }
}
