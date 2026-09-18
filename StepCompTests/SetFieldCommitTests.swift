//
//  SetFieldCommitTests.swift
//  FitComp Tests
//
//  Locks in number-pad commit routing: typed weight/reps must apply to
//  the field being edited (field.setId), not whatever SetRow handled the tap.
//

import XCTest
@testable import StepComp

final class SetFieldCommitTests: XCTestCase {
    private let set1Id = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private let set2Id = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    private let exercise1Id = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
    private let exercise2Id = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!

    func testWeightCommitTargetsFieldSetNotAnotherSet() {
        let session = makeSession()
        let field = SetFieldIdentifier(setId: set1Id, fieldType: .weight)

        let update = SetFieldCommit.resolve(
            session: session,
            field: field,
            text: "135",
            convertWeightToStorage: { $0 },
            clearOnEmpty: false
        )

        XCTAssertEqual(update?.setId, set1Id)
        XCTAssertEqual(update?.exerciseId, exercise1Id)
        XCTAssertEqual(update?.weight, 135)
        XCTAssertEqual(update?.reps, 8)
        XCTAssertNotEqual(update?.setId, set2Id)
    }

    func testRepsCommitTargetsFieldSetNotAnotherSet() {
        let session = makeSession()
        let field = SetFieldIdentifier(setId: set1Id, fieldType: .reps)

        let update = SetFieldCommit.resolve(
            session: session,
            field: field,
            text: "12",
            convertWeightToStorage: { $0 },
            clearOnEmpty: false
        )

        XCTAssertEqual(update?.setId, set1Id)
        XCTAssertEqual(update?.exerciseId, exercise1Id)
        XCTAssertEqual(update?.weight, 100)
        XCTAssertEqual(update?.reps, 12)
    }

    func testCrossExerciseCommitUsesFieldExercise() {
        let session = makeSession()
        let field = SetFieldIdentifier(setId: set1Id, fieldType: .weight)

        let update = SetFieldCommit.resolve(
            session: session,
            field: field,
            text: "185",
            convertWeightToStorage: { $0 },
            clearOnEmpty: false
        )

        XCTAssertEqual(update?.exerciseId, exercise1Id)
        XCTAssertNotEqual(update?.exerciseId, exercise2Id)
        XCTAssertEqual(update?.weight, 185)
    }

    func testSwitchingFieldsDoesNotClearOnEmptyBuffer() {
        let session = makeSession()
        let field = SetFieldIdentifier(setId: set1Id, fieldType: .weight)

        let update = SetFieldCommit.resolve(
            session: session,
            field: field,
            text: "",
            convertWeightToStorage: { $0 },
            clearOnEmpty: false
        )

        XCTAssertNil(update)
    }

    func testDoneClearsWeightWhenBufferEmpty() {
        let session = makeSession()
        let field = SetFieldIdentifier(setId: set1Id, fieldType: .weight)

        let update = SetFieldCommit.resolve(
            session: session,
            field: field,
            text: "",
            convertWeightToStorage: { $0 },
            clearOnEmpty: true
        )

        XCTAssertEqual(update?.setId, set1Id)
        XCTAssertNil(update?.weight)
        XCTAssertEqual(update?.reps, 8)
    }

    func testAppliesWeightConversionToFieldSet() {
        let session = makeSession()
        let field = SetFieldIdentifier(setId: set2Id, fieldType: .weight)

        let update = SetFieldCommit.resolve(
            session: session,
            field: field,
            text: "225",
            convertWeightToStorage: { $0 / 2.20462 },
            clearOnEmpty: false
        )

        XCTAssertEqual(update?.setId, set2Id)
        XCTAssertEqual(update?.exerciseId, exercise2Id)
        XCTAssertEqual(update?.weight ?? 0, 225 / 2.20462, accuracy: 0.0001)
        XCTAssertEqual(update?.reps, 5)
    }

    private func makeSession() -> WorkoutSession {
        let set1 = WorkoutSet(id: set1Id, setNumber: 1, weight: 100, reps: 8)
        let set2 = WorkoutSet(id: set2Id, setNumber: 1, weight: 60, reps: 5)
        let exercise1 = WorkoutExercise(
            id: exercise1Id,
            exercise: Exercise(name: "Bench Press", targetMuscles: "Chest"),
            sets: [set1]
        )
        let exercise2 = WorkoutExercise(
            id: exercise2Id,
            exercise: Exercise(name: "Row", targetMuscles: "Back"),
            sets: [set2]
        )
        return WorkoutSession(
            workoutId: UUID(),
            workoutName: "Push",
            exercises: [exercise1, exercise2]
        )
    }
}
