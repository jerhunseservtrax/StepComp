//
//  WeightViewModelLogoutCleanupTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class WeightViewModelLogoutCleanupTests: XCTestCase {
    @MainActor
    func testClearAllLocalUserStateRemovesWeightEntriesFromMemory() {
        WeightViewModel.clearAllLocalUserState()
        defer { WeightViewModel.clearAllLocalUserState() }

        WeightViewModel.shared.entries = [
            WeightEntry(date: Date(), weightKg: 82, source: .manual)
        ]
        WeightViewModel.shared.latestWeight = 82

        WeightViewModel.clearAllLocalUserState()

        XCTAssertTrue(
            WeightViewModel.shared.entries.isEmpty,
            "Logout cleanup must not retain the previous user's weight entries in memory."
        )
        XCTAssertNil(WeightViewModel.shared.latestWeight)
    }
}
