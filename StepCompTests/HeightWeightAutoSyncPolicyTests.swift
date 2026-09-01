//
//  HeightWeightAutoSyncPolicyTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class HeightWeightAutoSyncPolicyTests: XCTestCase {
    func testDisplayDefaultsAreNotTreatedAsUnset() {
        XCTAssertFalse(HeightWeightAutoSyncPolicy.isMissingStoredMeasurement(175))
        XCTAssertFalse(HeightWeightAutoSyncPolicy.isMissingStoredMeasurement(68))
        XCTAssertTrue(HeightWeightAutoSyncPolicy.isMissingStoredMeasurement(0))
        XCTAssertFalse(HeightWeightAutoSyncPolicy.shouldAutoLoad(storedHeight: 175, storedWeight: 68))
        XCTAssertTrue(HeightWeightAutoSyncPolicy.shouldAutoLoad(storedHeight: 0, storedWeight: 0))
        XCTAssertTrue(HeightWeightAutoSyncPolicy.shouldAutoLoad(storedHeight: 182, storedWeight: 0))
        XCTAssertFalse(HeightWeightAutoSyncPolicy.shouldAutoLoad(storedHeight: 182, storedWeight: 90))
    }

    func testHeightOnlyHealthKitLoadDoesNotInventWeight() {
        let payload = HeightWeightAutoSyncPolicy.profileWritePayload(
            loadedHeight: 182,
            loadedWeight: nil
        )
        XCTAssertEqual(payload.height, 182)
        XCTAssertNil(payload.weight)
    }

    func testPartialProfileUpdatePreservesExistingWeight() {
        let merged = HeightWeightAutoSyncPolicy.mergedProfileValues(
            incomingHeight: 182,
            incomingWeight: nil,
            existingHeight: 170,
            existingWeight: 81
        )
        XCTAssertEqual(merged.height, 182)
        XCTAssertEqual(merged.weight, 81)
    }
}
