//
//  VirtualPetUITests.swift
//  VirtualPetUITests
//
//  Created by 冯卓 on 2026/1/26.
//

import XCTest

final class VirtualPetUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testCompanionResponds() throws {
#if os(iOS)
        XCUIDevice.shared.orientation = .portrait
#endif
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["菲比"].waitForExistence(timeout: 3))

        let responseButton = app.buttons["叫她一声"]
        XCTAssertTrue(responseButton.exists)

        let character = app.buttons["菲比"]
        XCTAssertTrue(character.waitForExistence(timeout: 3))
        responseButton.tap()

        XCTAssertEqual(character.value as? String, "开心地啾比")
    }

    @MainActor
    func testRepeatedCallKeepsChirpReaction() throws {
#if os(iOS)
        XCUIDevice.shared.orientation = .portrait
#endif
        let app = XCUIApplication()
        app.launch()

        let responseButton = app.buttons["叫她一声"]
        let character = app.buttons["菲比"]
        XCTAssertTrue(responseButton.waitForExistence(timeout: 3))
        XCTAssertTrue(character.waitForExistence(timeout: 3))

        responseButton.tap()
        responseButton.tap()

        XCTAssertEqual(character.value as? String, "开心地啾比")
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
