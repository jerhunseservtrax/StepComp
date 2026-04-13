//
//  StepCompUITests.swift
//  FitComp UI Tests
//

import XCTest

final class StepCompUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testAppLaunchesSuccessfully() throws {
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
    }
}
