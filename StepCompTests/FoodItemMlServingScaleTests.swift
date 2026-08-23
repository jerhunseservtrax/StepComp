//
//  FoodItemMlServingScaleTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class FoodItemMlServingScaleTests: XCTestCase {
    func testMilliliterBarcodeServingScalesFromCanMassNotAssumed100g() {
        let soda = NutritionItem(
            name: "cola",
            calories: 140,
            servingSizeG: 355,
            fatTotalG: 0,
            fatSaturatedG: 0,
            proteinG: 0,
            sodiumMg: 0,
            potassiumMg: 0,
            cholesterolMg: 0,
            carbohydratesTotalG: 39,
            fiberG: 0,
            sugarG: 39
        )

        let logged = FoodItem(from: soda, consumedWeightG: 100)

        XCTAssertEqual(logged.calories, 140.0 * (100.0 / 355.0), accuracy: 0.05)
        XCTAssertEqual(logged.carbsG, 39.0 * (100.0 / 355.0), accuracy: 0.05)
        XCTAssertEqual(logged.sugarG, 39.0 * (100.0 / 355.0), accuracy: 0.05)
    }
}
