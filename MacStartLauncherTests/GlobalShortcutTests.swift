import Carbon.HIToolbox
import XCTest
@testable import MacStartLauncher

final class GlobalShortcutTests: XCTestCase {
    func testDefaultShortcutIsF18() {
        let shortcut = LauncherShortcut.f18

        XCTAssertEqual(shortcut.name, "F18")
        XCTAssertEqual(shortcut.carbonKeyCode, UInt32(kVK_F18))
    }

    func testDefaultShortcutMatchesF18HIDUsage() {
        XCTAssertEqual(LauncherShortcut.f18.hidUsage, 0x70000006D)
    }
}
