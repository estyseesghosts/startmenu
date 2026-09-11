import XCTest

final class NavigationTests: XCTestCase {
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

    func testSearchingForUnknownApplicationShowsEmptyState() {
        let field = app.textFields["Search apps"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.click()
        field.typeText("zzzz-definitely-not-installed")

        XCTAssertTrue(app.staticTexts["No Results"].waitForExistence(timeout: 5))
    }

    func testEscapeClearsSearchBeforeDismissing() {
        let field = app.textFields["Search apps"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.click()
        field.typeText("zzzz-definitely-not-installed")
        XCTAssertTrue(app.staticTexts["No Results"].waitForExistence(timeout: 5))

        app.typeKey(.escape, modifierFlags: [])

        XCTAssertFalse(app.staticTexts["No Results"].exists)
        XCTAssertTrue(field.exists)
    }

    func testSelectingCategoryShowsBackControl() throws {
        let categoryTiles = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "Developer Tools")
        )
        guard categoryTiles.count > 0 else {
            throw XCTSkip("No Developer Tools category is present on this machine.")
        }

        categoryTiles.firstMatch.click()

        XCTAssertTrue(
            app.buttons["backToCategories"].waitForExistence(timeout: 5)
        )
    }
}
