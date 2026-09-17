//
//  CaloriePlanMeasurementPersistenceTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class CaloriePlanMeasurementPersistenceTests: XCTestCase {
    func testUpdatePlanWithoutStoredOrEditedMeasurementsPersistsNothing() {
        let result = CaloriePlanMeasurementPersistence.measurementsToPersist(
            heightCm: 178,
            weightKg: 77,
            hadStoredHeight: false,
            hadStoredWeight: false,
            didEditHeight: false,
            didEditWeight: false
        )

        XCTAssertNil(result.height)
        XCTAssertNil(result.weight)
    }

    func testExistingStoredMeasurementsAreWrittenBack() {
        let result = CaloriePlanMeasurementPersistence.measurementsToPersist(
            heightCm: 180,
            weightKg: 80,
            hadStoredHeight: true,
            hadStoredWeight: true,
            didEditHeight: false,
            didEditWeight: false
        )

        XCTAssertEqual(result.height, 180)
        XCTAssertEqual(result.weight, 80)
    }

    func testExplicitHeightEditPersistsOnlyHeight() {
        let result = CaloriePlanMeasurementPersistence.measurementsToPersist(
            heightCm: 179,
            weightKg: 77,
            hadStoredHeight: false,
            hadStoredWeight: false,
            didEditHeight: true,
            didEditWeight: false
        )

        XCTAssertEqual(result.height, 179)
        XCTAssertNil(result.weight)
    }

    func testExplicitWeightEditPersistsOnlyWeight() {
        let result = CaloriePlanMeasurementPersistence.measurementsToPersist(
            heightCm: 178,
            weightKg: 81,
            hadStoredHeight: false,
            hadStoredWeight: false,
            didEditHeight: false,
            didEditWeight: true
        )

        XCTAssertNil(result.height)
        XCTAssertEqual(result.weight, 81)
    }

    func testStoredHeightPlusEditedWeightPersistsBoth() {
        let result = CaloriePlanMeasurementPersistence.measurementsToPersist(
            heightCm: 172,
            weightKg: 70,
            hadStoredHeight: true,
            hadStoredWeight: false,
            didEditHeight: false,
            didEditWeight: true
        )

        XCTAssertEqual(result.height, 172)
        XCTAssertEqual(result.weight, 70)
    }
}
