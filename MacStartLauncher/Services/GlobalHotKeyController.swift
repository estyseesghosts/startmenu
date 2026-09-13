import AppKit
import Carbon.HIToolbox

/// A global keyboard shortcut the launcher can register.
///
/// `hidUsage` records the USB HID usage the key corresponds to, which is the
/// same value macOS uses in its `HIDKeyboardModifierMappingDst` remapping
/// tables. `0x70000006D` is F18.
struct LauncherShortcut: Equatable {
    let name: String
    let carbonKeyCode: UInt32
    let hidUsage: UInt64

    /// The launcher's built-in shortcut: F18.
    static let f18 = LauncherShortcut(
        name: "F18",
        carbonKeyCode: UInt32(kVK_F18),
        hidUsage: 0x70000006D
    )
}

/// Registers the launcher's default global shortcut with the system.
///
/// Carbon hot keys are used instead of a global `NSEvent` keyboard monitor
/// because they fire without the app requesting Accessibility trust.
@MainActor
final class GlobalHotKeyController {
    private static let signature: OSType = 0x5354_4D4E // 'STMN'

    private let shortcut: LauncherShortcut
    private let action: @MainActor () -> Void
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    init(
        shortcut: LauncherShortcut = .f18,
        action: @escaping @MainActor () -> Void
    ) {
        self.shortcut = shortcut
        self.action = action
    }

    /// Registers the shortcut. Returns whether the system accepted it.
    @discardableResult
    func register() -> Bool {
        unregister()

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else { return OSStatus(eventNotHandledErr) }
                let controller = Unmanaged<GlobalHotKeyController>
                    .fromOpaque(userData)
                    .takeUnretainedValue()
                Task { @MainActor in
                    controller.action()
                }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &handlerRef
        )
        guard installStatus == noErr else { return false }

        let hotKeyID = EventHotKeyID(signature: Self.signature, id: 1)
        let registerStatus = RegisterEventHotKey(
            shortcut.carbonKeyCode,
            0,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        return registerStatus == noErr
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let handlerRef {
            RemoveEventHandler(handlerRef)
            self.handlerRef = nil
        }
    }
}
