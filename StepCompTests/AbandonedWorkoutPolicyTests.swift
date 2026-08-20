import XCTest
@testable import StepComp

final class AbandonedWorkoutPolicyTests: XCTestCase {
    func testSixHourRunningSessionShouldPause() {
        XCTAssertTrue(
            AbandonedWorkoutPolicy.shouldAutoPause(
                elapsed: AbandonedWorkoutPolicy.threshold,
                isPaused: false,
                alreadyAutoPaused: false
            )
        )
    }

    func testSubThresholdSessionKeepsRunning() {
        XCTAssertFalse(
            AbandonedWorkoutPolicy.shouldAutoPause(
                elapsed: AbandonedWorkoutPolicy.threshold - 1,
                isPaused: false,
                alreadyAutoPaused: false
            )
        )
    }

    func testAlreadyPausedSessionIsNotRePaused() {
        XCTAssertFalse(
            AbandonedWorkoutPolicy.shouldAutoPause(
                elapsed: 12 * 3600,
                isPaused: true,
                alreadyAutoPaused: false
            )
        )
    }

    func testExplicitResumeAfterAutoPauseCanContinue() {
        XCTAssertFalse(
            AbandonedWorkoutPolicy.shouldAutoPause(
                elapsed: 12 * 3600,
                isPaused: false,
                alreadyAutoPaused: true
            )
        )
    }
}
