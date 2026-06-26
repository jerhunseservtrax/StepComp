//
//  WorkoutSetTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class WorkoutSetTests: XCTestCase {
    func testLegacyDecodedSetDefaultsToTotalWeightMode() throws {
        let legacyJSON = """
        {
          "id": "00000000-0000-0000-0000-000000000001",
          "setNumber": 1,
          "weight": 20,
          "reps": 10,
          "isCompleted": true
        }
        """

        let set = try JSONDecoder().decode(WorkoutSet.self, from: Data(legacyJSON.utf8))

        XCTAssertEqual(set.weightInputMode, .total)
        XCTAssertEqual(set.effectiveWeightForVolume, 20)
    }
}
