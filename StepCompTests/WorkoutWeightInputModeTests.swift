//
//  WorkoutWeightInputModeTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

@MainActor
final class WorkoutWeightInputModeTests: XCTestCase {
    func testLegacyDumbbellSessionsRemainTotalWeightModeOnLoad() throws {
        UserDefaults.standard.removeObject(forKey: "completed_workout_sessions")
        UserDefaults.standard.removeObject(forKey: "set_weight_mode_per_side_backfill_v1")
        UserDefaults.standard.set(true, forKey: "weights_migrated_to_kg_v1")

        let sessionId = UUID()
        let workoutId = UUID()
        let exerciseId = UUID()
        let workoutExerciseId = UUID()
        let setId = UUID()
        let startTime = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let endTime = startTime.addingTimeInterval(3_600)

        let legacySession: [String: Any] = [
            "id": sessionId.uuidString,
            "workoutId": workoutId.uuidString,
            "workoutName": "Push Day",
            "startTime": startTime.timeIntervalSinceReferenceDate,
            "endTime": endTime.timeIntervalSinceReferenceDate,
            "exercises": [
                [
                    "id": workoutExerciseId.uuidString,
                    "exercise": [
                        "id": exerciseId.uuidString,
                        "name": "Dumbbell Bench Press",
                        "targetMuscles": "Chest, Triceps"
                    ],
                    "sets": [
                        [
                            "id": setId.uuidString,
                            "setNumber": 1,
                            "weight": 50.0,
                            "reps": 10,
                            "isCompleted": true
                        ]
                    ]
                ]
            ]
        ]

        let data = try JSONSerialization.data(withJSONObject: [legacySession])
        UserDefaults.standard.set(data, forKey: "completed_workout_sessions")

        let viewModel = WorkoutViewModel.shared
        let set = try XCTUnwrap(viewModel.completedSessions.first?.exercises.first?.sets.first)

        XCTAssertEqual(set.weightInputMode, .total)
        XCTAssertEqual(viewModel.completedSessions.first?.totalVolume, 500.0)
    }
}
