//
//  WorkoutEditBufferTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class WorkoutEditBufferTests: XCTestCase {
    private var originalUnitSystem: UnitSystem!

    override func setUp() {
        super.setUp()
        originalUnitSystem = UnitPreferenceManager.shared.unitSystem
        UnitPreferenceManager.shared.unitSystem = .metric
    }

    override func tearDown() {
        UnitPreferenceManager.shared.unitSystem = originalUnitSystem
        super.tearDown()
    }

    func testEditBufferSeedsExistingWeightAndReps() {
        let set = WorkoutSet(setNumber: 1, weight: 42.5, reps: 8)

        XCTAssertEqual(
            workoutEditBufferText(for: set, fieldType: .weight, unitManager: UnitPreferenceManager.shared),
            "42.5"
        )
        XCTAssertEqual(
            workoutEditBufferText(for: set, fieldType: .reps, unitManager: UnitPreferenceManager.shared),
            "8"
        )
    }

    func testEditBufferIsEmptyOnlyWhenStoredValueIsEmpty() {
        let set = WorkoutSet(setNumber: 1)

        XCTAssertEqual(
            workoutEditBufferText(for: set, fieldType: .weight, unitManager: UnitPreferenceManager.shared),
            ""
        )
        XCTAssertEqual(
            workoutEditBufferText(for: set, fieldType: .reps, unitManager: UnitPreferenceManager.shared),
            ""
        )
    }
}
