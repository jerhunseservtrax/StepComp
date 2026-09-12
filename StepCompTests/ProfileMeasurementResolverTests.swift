//
//  ProfileMeasurementResolverTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class ProfileMeasurementResolverTests: XCTestCase {
    func testEmptyFieldsDoNotInventMeasurements() {
        let imperial = ProfileMeasurementResolver.resolvedStorage(
            heightPrimaryText: "",
            heightInchesText: "",
            weightText: "",
            unitSystem: .imperial
        )
        XCTAssertNil(imperial.heightCm)
        XCTAssertNil(imperial.weightKg)

        let metric = ProfileMeasurementResolver.resolvedStorage(
            heightPrimaryText: "",
            heightInchesText: "",
            weightText: "",
            unitSystem: .metric
        )
        XCTAssertNil(metric.heightCm)
        XCTAssertNil(metric.weightKg)
    }

    func testPlaceholderImperialDefaultsAreNotRequiredToPersist() {
        // These are the previous form defaults. Saving a name should not
        // treat them as real measurements unless the user entered them.
        let resolved = ProfileMeasurementResolver.resolvedStorage(
            heightPrimaryText: "",
            heightInchesText: "",
            weightText: "",
            unitSystem: .imperial
        )
        XCTAssertNotEqual(resolved.heightCm, 175)
        XCTAssertNotEqual(resolved.weightKg, 68)
        XCTAssertNil(resolved.heightCm)
        XCTAssertNil(resolved.weightKg)
    }

    func testInvalidOrBlankWeightDoesNotFallBackTo150() {
        let resolved = ProfileMeasurementResolver.resolvedStorage(
            heightPrimaryText: "5",
            heightInchesText: "9",
            weightText: "",
            unitSystem: .imperial
        )
        XCTAssertEqual(resolved.heightCm, 175)
        XCTAssertNil(resolved.weightKg)

        let invalid = ProfileMeasurementResolver.resolvedStorage(
            heightPrimaryText: "",
            heightInchesText: "",
            weightText: "abc",
            unitSystem: .imperial
        )
        XCTAssertNil(invalid.weightKg)
    }

    func testExplicitImperialMeasurementsConvertToStorage() {
        let resolved = ProfileMeasurementResolver.resolvedStorage(
            heightPrimaryText: "5",
            heightInchesText: "9",
            weightText: "150",
            unitSystem: .imperial
        )
        XCTAssertEqual(resolved.heightCm, 175)
        XCTAssertEqual(resolved.weightKg, 68)
    }

    func testExplicitMetricMeasurementsPersistAsEntered() {
        let resolved = ProfileMeasurementResolver.resolvedStorage(
            heightPrimaryText: "180",
            heightInchesText: "",
            weightText: "80",
            unitSystem: .metric
        )
        XCTAssertEqual(resolved.heightCm, 180)
        XCTAssertEqual(resolved.weightKg, 80)
    }

    func testMetricPlaceholderFiveAndOneFiftyAreNotWrittenWhenFieldsEmpty() {
        let resolved = ProfileMeasurementResolver.resolvedStorage(
            heightPrimaryText: "",
            heightInchesText: "9",
            weightText: "",
            unitSystem: .metric
        )
        XCTAssertNil(resolved.heightCm)
        XCTAssertNil(resolved.weightKg)
    }

    func testZeroValuesAreTreatedAsUnset() {
        let resolved = ProfileMeasurementResolver.resolvedStorage(
            heightPrimaryText: "0",
            heightInchesText: "0",
            weightText: "0",
            unitSystem: .imperial
        )
        XCTAssertNil(resolved.heightCm)
        XCTAssertNil(resolved.weightKg)
    }
}
