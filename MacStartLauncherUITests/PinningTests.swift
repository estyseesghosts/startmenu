import XCTest

final class PinningTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    func testApplicationContextMenuOffersPinOrUnpin() throws {
        let field = app.textFields["Search apps"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.click()
        field.typeText("Safari")

        let tile = app.buttons["Safari"]
        guard tile.waitForExistence(timeout: 5) else {
            throw XCTSkip("Safari is not discoverable in this environment.")
        }

        tile.rightClick()

        let pin = app.menuItems["Pin to Launcher"]
        let unpin = app.menuItems["Unpin from Launcher"]
        XCTAssertTrue(
            pin.waitForExistence(timeout: 3) || unpin.waitForExistence(timeout: 3),
            "Expected a pin or unpin context menu item."
        )
    }
}
