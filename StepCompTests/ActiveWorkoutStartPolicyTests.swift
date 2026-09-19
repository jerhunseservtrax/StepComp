//
//  ActiveWorkoutStartPolicyTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class ActiveWorkoutStartPolicyTests: XCTestCase {
    func testAllowsStartWhenNoActiveSession() {
        XCTAssertTrue(ActiveWorkoutStartPolicy.canStartNewWorkout(hasActiveSession: false))
    }

    func testBlocksStartWhenActiveSessionExists() {
        XCTAssertFalse(ActiveWorkoutStartPolicy.canStartNewWorkout(hasActiveSession: true))
    }
}
