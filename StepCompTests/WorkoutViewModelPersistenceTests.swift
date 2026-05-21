//
//  WorkoutViewModelPersistenceTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class WorkoutViewModelPersistenceTests: XCTestCase {
    @MainActor
    func testReconcilePreservesUndecodableActiveWorkoutDraft() {
        let draftKey = "active_workout_draft"
        let previousDraft = UserDefaults.standard.data(forKey: draftKey)
        let invalidDraft = Data("not-json".utf8)
        UserDefaults.standard.set(invalidDraft, forKey: draftKey)
        defer {
            if let previousDraft {
                UserDefaults.standard.set(previousDraft, forKey: draftKey)
            } else {
                UserDefaults.standard.removeObject(forKey: draftKey)
            }
        }

        let viewModel = WorkoutViewModel.shared
        viewModel.currentSession = nil

        viewModel.reconcileActiveWorkoutState()

        XCTAssertEqual(UserDefaults.standard.data(forKey: draftKey), invalidDraft)
    }
}
