//
//  FoodItemServingScaleTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class FoodItemServingScaleTests: XCTestCase {
    func testRestaurantServingScalesFromGramBaseNotAssumed100g() {
        let item = NutritionItem(
            name: "french toast",
            calories: 835,
            servingSizeG: 342,
            fatTotalG: 32.28,
            fatSaturatedG: 0,
            proteinG: 29.41,
            sodiumMg: 0,
            potassiumMg: 0,
            cholesterolMg: 0,
            carbohydratesTotalG: 105.43,
            fiberG: 0,
            sugarG: 0
        )

        let logged = FoodItem(from: item, consumedWeightG: 100)

        XCTAssertEqual(logged.calories, 835.0 * (100.0 / 342.0), accuracy: 0.05)
        XCTAssertEqual(logged.proteinG, 29.41 * (100.0 / 342.0), accuracy: 0.05)
        XCTAssertEqual(logged.carbsG, 105.43 * (100.0 / 342.0), accuracy: 0.05)
        XCTAssertEqual(logged.fatG, 32.28 * (100.0 / 342.0), accuracy: 0.05)
    }

    func testPer100gServingIsUnchangedAt100g() {
        let item = NutritionItem(
            name: "apple",
            calories: 52,
            servingSizeG: 100,
            fatTotalG: 0.17,
            fatSaturatedG: 0,
            proteinG: 0.26,
            sodiumMg: 0,
            potassiumMg: 0,
            cholesterolMg: 0,
            carbohydratesTotalG: 13.81,
            fiberG: 0,
            sugarG: 0
        )

        let logged = FoodItem(from: item, consumedWeightG: 100)
        XCTAssertEqual(logged.calories, 52, accuracy: 0.01)
    }
}
