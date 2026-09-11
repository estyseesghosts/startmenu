import AppKit
import SwiftUI

/// Keyboard commands the launcher understands.
enum LauncherKeyCommand {
    case escape
    case submit
    case up
    case down
    case left
    case right
}

/// A borderless panel that can become key so the search field works.
@MainActor
final class LauncherPanel: NSPanel {
    var keyCommandHandler: ((LauncherKeyCommand) -> Bool)?
    var allowsMainWindow = false

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { allowsMainWindow }

    override func keyDown(with event: NSEvent) {
        if let command = Self.command(for: event), keyCommandHandler?(command) == true {
            return
        }
        super.keyDown(with: event)
    }

    override func cancelOperation(_ sender: Any?) {
        _ = keyCommandHandler?(.escape)
    }

    private static func command(for event: NSEvent) -> LauncherKeyCommand? {
        switch event.keyCode {
        case 53: return .escape
        case 36, 76: return .submit
        case 123: return .left
        case 124: return .right
        case 125: return .down
        case 126: return .up
        default: return nil
        }
    }
}

/// Owns the unusual window behavior for the launcher.
///
/// It creates the `NSPanel`, selects the display containing the pointer,
/// positions the window above the Dock, handles dismissal, and returns keyboard
/// focus to the previous application.
@MainActor
final class LauncherPanelController: NSObject, NSWindowDelegate {
    private static let preferredSize = NSSize(width: 860, height: 620)
    private static let margin: CGFloat = 12

    private let environment: AppEnvironment
    private let panel: LauncherPanel
    private let isUITesting: Bool

    private var previousApplication: NSRunningApplication?
    private var localMonitor: Any?
    private var globalMonitor: Any?
    private var activationObserver: NSObjectProtocol?

    init(environment: AppEnvironment) {
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-uiTesting")
        let styleMask: NSWindow.StyleMask = isUITesting
            ? [.titled, .closable, .resizable]
            : [.borderless]

        self.environment = environment
        self.isUITesting = isUITesting
        self.panel = LauncherPanel(
            contentRect: NSRect(origin: .zero, size: Self.preferredSize),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        super.init()

        configurePanel()
    }

    private func configurePanel() {
        panel.isOpaque = isUITesting
        panel.backgroundColor = isUITesting ? .windowBackgroundColor : .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.isMovableByWindowBackground = false
        panel.becomesKeyOnlyIfNeeded = false
        panel.hidesOnDeactivate = false
        panel.animationBehavior = .utilityWindow
        panel.delegate = self
        panel.allowsMainWindow = isUITesting
        if isUITesting {
            panel.title = "Start"
        }
        panel.contentView = NSHostingView(
            rootView: LauncherRootView().environment(environment)
        )
        panel.keyCommandHandler = { [weak environment] command in
            environment?.launcher.handle(command)
            return true
        }
    }

    func toggle() {
        if panel.isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        previousApplication = NSWorkspace.shared.frontmostApplication
        environment.launcher.load()
        environment.folders.refreshCustomShortcuts()
        positionOnActiveScreen()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        installEventMonitors()
        installActivationObserver()
    }

    func hide() {
        removeEventMonitors()
        removeActivationObserver()
        panel.orderOut(nil)

        if let previousApplication,
           previousApplication != NSRunningApplication.current,
           !previousApplication.isTerminated {
            previousApplication.activate(options: [])
        }
        previousApplication = nil
    }

    // MARK: - Positioning

    private func positionOnActiveScreen() {
        guard let screen = activeScreen() else { return }

        let visible = screen.visibleFrame
        let width = min(Self.preferredSize.width, max(320, visible.width - 2 * Self.margin))
        let height = min(Self.preferredSize.height, max(320, visible.height - 2 * Self.margin))
        let size = NSSize(width: width, height: height)

        panel.setContentSize(size)
        panel.setFrameOrigin(
            NSPoint(x: visible.minX + Self.margin, y: visible.minY + Self.margin)
        )
    }

    private func activeScreen() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first {
            NSMouseInRect(mouseLocation, $0.frame, false)
        } ?? NSScreen.main
    }

    // MARK: - Dismissal

    private func installEventMonitors() {
        removeEventMonitors()
        guard !isUITesting else { return }

        localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            guard let self else { return event }
            if event.window !== self.panel, NSApp.modalWindow == nil {
                self.hide()
            }
            return event
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            guard NSApp.modalWindow == nil else { return }
            self?.hide()
        }
    }

    private func removeEventMonitors() {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        localMonitor = nil
        globalMonitor = nil
    }

    private func installActivationObserver() {
        removeActivationObserver()
        guard !isUITesting else { return }
        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self, self.panel.isVisible else { return }
            guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
                return
            }
            if application.bundleIdentifier != Bundle.main.bundleIdentifier {
                self.hide()
            }
        }
    }

    private func removeActivationObserver() {
        if let activationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(activationObserver)
        }
        activationObserver = nil
    }

    // MARK: - NSWindowDelegate

    func windowDidResignKey(_ notification: Notification) {
        guard !isUITesting else { return }
        if panel.isVisible, NSApp.modalWindow == nil, !NSApp.isActive {
            hide()
        }
    }
}
