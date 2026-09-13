import XCTest

final class LauncherLayoutTests: XCTestCase {
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

    func testLauncherShowsSearchField() {
        XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: 10))
    }

    func testLauncherShowsAddFolderButton() {
        XCTAssertTrue(app.buttons["Add Folder"].waitForExistence(timeout: 10))
    }

    func testLauncherShowsStandardFolders() {
        for name in ["Home", "Documents", "Desktop", "Downloads"] {
            XCTAssertTrue(
                app.buttons[name].waitForExistence(timeout: 10),
                "Missing standard folder: \(name)"
            )
        }
    }

    func testLauncherShowsPinnedAndCategoriesSections() {
        XCTAssertTrue(app.staticTexts["Pinned"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Categories"].waitForExistence(timeout: 10))
    }
}
