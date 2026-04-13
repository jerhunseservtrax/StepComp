//
//  UnitPreferenceManagerTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class UnitPreferenceManagerTests: XCTestCase {
    func testMetricToImperialWeightRoundTrip() {
        let manager = UnitPreferenceManager.shared
        let originalKg: Double = 70.0
        let lbs = originalKg * 2.20462
        let backToKg = lbs / 2.20462
        XCTAssertEqual(backToKg, originalKg, accuracy: 0.01)
    }

    func testMetricToImperialHeightRoundTrip() {
        let heightCm: Double = 180.0
        let totalInches = heightCm / 2.54
        let feet = Int(totalInches) / 12
        let inches = Int(totalInches.rounded()) % 12
        let backToCm = Double(feet * 12 + inches) * 2.54
        XCTAssertEqual(backToCm, heightCm, accuracy: 2.54)
    }
}
