//
//  CalorieNinjasService.swift
//  FitComp
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum CalorieNinjasConfig {
    static let functionName = SupabaseConfig.calorieNinjasEdgeFunctionName
    static let fallbackFunctionNames = [
        "nutrition-proxy",
        "calorie-ninjas-proxy",
        "calorie-ninjas"
    ]
}

struct NutritionItem: Identifiable, Codable, Hashable {
    var id: String { name + String(calories) }
    let name: String
    let calories: Double
    let servingSizeG: Double
    let fatTotalG: Double
    let fatSaturatedG: Double
    let proteinG: Double
    let sodiumMg: Double
    let potassiumMg: Double
    let cholesterolMg: Double
    let carbohydratesTotalG: Double
    let fiberG: Double
    let sugarG: Double

    enum CodingKeys: String, CodingKey {
        case name
        case calories
        case servingSizeG = "serving_size_g"
        case fatTotalG = "fat_total_g"
        case fatSaturatedG = "fat_saturated_g"
        case proteinG = "protein_g"
        case sodiumMg = "sodium_mg"
        case potassiumMg = "potassium_mg"
        case cholesterolMg = "cholesterol_mg"
        case carbohydratesTotalG = "carbohydrates_total_g"
        case fiberG = "fiber_g"
        case sugarG = "sugar_g"
    }
}

struct NutritionResponse: Codable {
    let items: [NutritionItem]
}

@MainActor
final class CalorieNinjasService {
    static let shared = CalorieNinjasService()
    private init() {}

    func lookupNutrition(query: String) async throws -> [NutritionItem] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        let payload: [String: Any] = ["mode": "query", "query": String(query.prefix(1500))]

        do {
            let response: NutritionResponse = try await postNutritionWithFunctionFallback(payload: payload)
            return response.items
        } catch EdgeFunctionError.badStatus(404) {
            return try await lookupNutritionViaOpenFoodFacts(query: query)
        } catch {
            throw error
        }
    }

    #if canImport(UIKit)
    func scanImageForNutrition(image: UIImage) async throws -> [NutritionItem] {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw CalorieNinjasError.imageConversionFailed
        }
        let base64 = imageData.base64EncodedString()
        let response: NutritionResponse = try await postNutritionWithFunctionFallback(
            payload: ["mode": "image", "imageBase64": base64]
        )
        return response.items
    }
    #endif

    func lookupNutritionByBarcode(_ barcode: String) async throws -> [NutritionItem] {
        let sanitized = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitized.isEmpty else { return [] }

        let payload: [String: Any] = ["mode": "barcode", "barcode": sanitized]

        do {
            let response: NutritionResponse = try await postNutritionWithFunctionFallback(payload: payload)
            if !response.items.isEmpty { return response.items }
        } catch EdgeFunctionError.badStatus(404) {
            // Fall through to Open Food Facts if the function route does not exist.
        } catch {
            // If function call fails for non-404 reasons, still try Open Food Facts as backup.
        }

        return try await lookupBarcodeViaOpenFoodFacts(barcode: sanitized)
    }

    private func postNutritionWithFunctionFallback(
        payload: [String: Any]
    ) async throws -> NutritionResponse {
        let functionNames = [CalorieNinjasConfig.functionName] + CalorieNinjasConfig.fallbackFunctionNames
        var seen = Set<String>()
        var lastError: Error?

        for functionName in functionNames where seen.insert(functionName).inserted {
            do {
                return try await EdgeFunctionService.shared.postJSON(
                    functionName: functionName,
                    payload: payload,
                    decodeAs: NutritionResponse.self
                )
            } catch EdgeFunctionError.badStatus(404) {
                lastError = EdgeFunctionError.badStatus(404)
                continue
            } catch {
                lastError = error
                throw error
            }
        }

        throw lastError ?? EdgeFunctionError.badStatus(404)
    }

    private func lookupNutritionViaOpenFoodFacts(query: String) async throws -> [NutritionItem] {
        var components = URLComponents(string: "https://world.openfoodfacts.org/cgi/search.pl")
        components?.queryItems = [
            URLQueryItem(name: "search_terms", value: query),
            URLQueryItem(name: "search_simple", value: "1"),
            URLQueryItem(name: "action", value: "process"),
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "page_size", value: "20")
        ]

        guard let url = components?.url else { throw CalorieNinjasError.invalidURL }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw CalorieNinjasError.requestFailed
        }

        let decoded = try JSONDecoder().decode(OpenFoodFactsSearchResponse.self, from: data)
        let mapped = decoded.products.compactMap { mapOpenFoodFactsProduct($0) }
        return Array(mapped.prefix(10))
    }

    private func lookupBarcodeViaOpenFoodFacts(barcode: String) async throws -> [NutritionItem] {
        guard let encodedBarcode = barcode.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(encodedBarcode).json") else {
            throw CalorieNinjasError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw CalorieNinjasError.requestFailed
        }

        let decoded = try JSONDecoder().decode(OpenFoodFactsBarcodeResponse.self, from: data)
        guard decoded.status == 1,
              let product = decoded.product,
              let item = mapOpenFoodFactsProduct(product) else {
            throw CalorieNinjasError.barcodeNotFound
        }

        return [item]
    }

    private func mapOpenFoodFactsProduct(_ product: OpenFoodFactsProduct) -> NutritionItem? {
        let rawName = product.productName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !rawName.isEmpty else { return nil }

        let nutriments = product.nutriments
        let servingSize = product.servingQuantity ?? 100
        let caloriesPer100g = nutriments.energyKcal100g ?? nutriments.energyKcal
        let calories = (caloriesPer100g ?? 0) * (servingSize / 100.0)

        return NutritionItem(
            name: rawName.lowercased(),
            calories: calories,
            servingSizeG: servingSize,
            fatTotalG: (nutriments.fat100g ?? 0) * (servingSize / 100.0),
            fatSaturatedG: (nutriments.saturatedFat100g ?? 0) * (servingSize / 100.0),
            proteinG: (nutriments.proteins100g ?? 0) * (servingSize / 100.0),
            sodiumMg: (nutriments.sodium100g ?? 0) * 1000 * (servingSize / 100.0),
            potassiumMg: (nutriments.potassium100g ?? 0) * 1000 * (servingSize / 100.0),
            cholesterolMg: 0,
            carbohydratesTotalG: (nutriments.carbohydrates100g ?? 0) * (servingSize / 100.0),
            fiberG: (nutriments.fiber100g ?? 0) * (servingSize / 100.0),
            sugarG: (nutriments.sugars100g ?? 0) * (servingSize / 100.0)
        )
    }
}

enum CalorieNinjasError: LocalizedError {
    case invalidURL
    case requestFailed
    case imageConversionFailed
    case barcodeNotFound

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .requestFailed: return "Nutrition lookup failed. Please try again."
        case .imageConversionFailed: return "Could not process image."
        case .barcodeNotFound: return "No product found for that barcode."
        }
    }
}

private struct OpenFoodFactsSearchResponse: Decodable {
    let products: [OpenFoodFactsProduct]
}

private struct OpenFoodFactsBarcodeResponse: Decodable {
    let status: Int
    let product: OpenFoodFactsProduct?
}

private struct OpenFoodFactsProduct: Decodable {
    let productName: String?
    let servingQuantity: Double?
    let nutriments: OpenFoodFactsNutriments

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        productName = try container.decodeIfPresent(String.self, forKey: .productName)
        servingQuantity = try container.decodeFlexibleDoubleIfPresent(forKey: .servingQuantity)
        nutriments = try container.decodeIfPresent(OpenFoodFactsNutriments.self, forKey: .nutriments) ?? .empty
    }

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case servingQuantity = "serving_quantity"
        case nutriments
    }
}

private struct OpenFoodFactsNutriments: Decodable {
    let energyKcal100g: Double?
    let energyKcal: Double?
    let fat100g: Double?
    let saturatedFat100g: Double?
    let proteins100g: Double?
    let sodium100g: Double?
    let potassium100g: Double?
    let carbohydrates100g: Double?
    let fiber100g: Double?
    let sugars100g: Double?

    static let empty = OpenFoodFactsNutriments(
        energyKcal100g: nil,
        energyKcal: nil,
        fat100g: nil,
        saturatedFat100g: nil,
        proteins100g: nil,
        sodium100g: nil,
        potassium100g: nil,
        carbohydrates100g: nil,
        fiber100g: nil,
        sugars100g: nil
    )

    init(
        energyKcal100g: Double?,
        energyKcal: Double?,
        fat100g: Double?,
        saturatedFat100g: Double?,
        proteins100g: Double?,
        sodium100g: Double?,
        potassium100g: Double?,
        carbohydrates100g: Double?,
        fiber100g: Double?,
        sugars100g: Double?
    ) {
        self.energyKcal100g = energyKcal100g
        self.energyKcal = energyKcal
        self.fat100g = fat100g
        self.saturatedFat100g = saturatedFat100g
        self.proteins100g = proteins100g
        self.sodium100g = sodium100g
        self.potassium100g = potassium100g
        self.carbohydrates100g = carbohydrates100g
        self.fiber100g = fiber100g
        self.sugars100g = sugars100g
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        energyKcal100g = try container.decodeFlexibleDoubleIfPresent(forKey: .energyKcal100g)
        energyKcal = try container.decodeFlexibleDoubleIfPresent(forKey: .energyKcal)
        fat100g = try container.decodeFlexibleDoubleIfPresent(forKey: .fat100g)
        saturatedFat100g = try container.decodeFlexibleDoubleIfPresent(forKey: .saturatedFat100g)
        proteins100g = try container.decodeFlexibleDoubleIfPresent(forKey: .proteins100g)
        sodium100g = try container.decodeFlexibleDoubleIfPresent(forKey: .sodium100g)
        potassium100g = try container.decodeFlexibleDoubleIfPresent(forKey: .potassium100g)
        carbohydrates100g = try container.decodeFlexibleDoubleIfPresent(forKey: .carbohydrates100g)
        fiber100g = try container.decodeFlexibleDoubleIfPresent(forKey: .fiber100g)
        sugars100g = try container.decodeFlexibleDoubleIfPresent(forKey: .sugars100g)
    }

    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case energyKcal = "energy-kcal"
        case fat100g = "fat_100g"
        case saturatedFat100g = "saturated-fat_100g"
        case proteins100g = "proteins_100g"
        case sodium100g = "sodium_100g"
        case potassium100g = "potassium_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case fiber100g = "fiber_100g"
        case sugars100g = "sugars_100g"
    }
}

private extension KeyedDecodingContainer {
    func decodeFlexibleDoubleIfPresent(forKey key: Key) throws -> Double? {
        if let value = try? decodeIfPresent(Double.self, forKey: key) {
            return value
        }
        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return Double(value)
        }
        if let stringValue = try? decodeIfPresent(String.self, forKey: key) {
            return Double(stringValue.replacingOccurrences(of: ",", with: "."))
        }
        return nil
    }
}
