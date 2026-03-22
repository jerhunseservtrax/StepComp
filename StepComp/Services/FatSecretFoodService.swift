//
//  FatSecretFoodService.swift
//  FitComp
//

import Foundation

enum FatSecretConfig {
    static let functionName = SupabaseConfig.fatSecretEdgeFunctionName
    static let fallbackFunctionNames = [
        "fatsecret-proxy",
        "fatsecret",
        "nutrition-fatsecret"
    ]
}

enum FatSecretError: LocalizedError {
    case emptyResponse
    case unsupportedResponse

    var errorDescription: String? {
        switch self {
        case .emptyResponse:
            return "No foods returned from FatSecret."
        case .unsupportedResponse:
            return "FatSecret response format is not supported."
        }
    }
}

@MainActor
final class FatSecretFoodService {
    static let shared = FatSecretFoodService()
    private init() {}

    func searchFoods(query: String, pageSize: Int = 25) async throws -> [NutritionItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let payload: [String: Any] = [
            "mode": "search",
            "query": trimmed,
            "maxResults": min(max(pageSize, 1), 50)
        ]

        return try await lookupWithFunctionFallback(payload: payload)
    }

    func searchByBarcode(upc: String) async throws -> [NutritionItem] {
        let normalized = upc.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return [] }

        let payload: [String: Any] = [
            "mode": "barcode",
            "barcode": normalized
        ]

        return try await lookupWithFunctionFallback(payload: payload)
    }

    private func lookupWithFunctionFallback(payload: [String: Any]) async throws -> [NutritionItem] {
        let functionNames = [FatSecretConfig.functionName] + FatSecretConfig.fallbackFunctionNames
        var seen = Set<String>()
        var lastError: Error?

        for functionName in functionNames where seen.insert(functionName).inserted {
            do {
                let data = try await EdgeFunctionService.shared.postData(functionName: functionName, payload: payload)
                let items = try decodeNutritionItems(from: data)
                if !items.isEmpty {
                    return items
                }
                lastError = FatSecretError.emptyResponse
            } catch EdgeFunctionError.badStatus(404) {
                lastError = EdgeFunctionError.badStatus(404)
                continue
            } catch {
                lastError = error
                throw error
            }
        }

        throw lastError ?? FatSecretError.emptyResponse
    }

    private func decodeNutritionItems(from data: Data) throws -> [NutritionItem] {
        let decoder = JSONDecoder()

        if let direct = try? decoder.decode(NutritionResponse.self, from: data) {
            return direct.items
        }

        let envelope = try decoder.decode(FatSecretResponseEnvelope.self, from: data)
        if !envelope.items.isEmpty {
            return envelope.items
        }
        if !envelope.foods.isEmpty {
            return envelope.foods.compactMap(\.asNutritionItem)
        }
        if let single = envelope.food {
            return [single].compactMap(\.asNutritionItem)
        }

        throw FatSecretError.unsupportedResponse
    }
}

private struct FatSecretResponseEnvelope: Decodable {
    let items: [NutritionItem]
    let foods: [FatSecretFoodPayload]
    let food: FatSecretFoodPayload?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = (try? container.decode([NutritionItem].self, forKey: .items)) ?? []
        foods = (try? container.decode([FatSecretFoodPayload].self, forKey: .foods)) ?? []
        food = try? container.decode(FatSecretFoodPayload.self, forKey: .food)
    }

    enum CodingKeys: String, CodingKey {
        case items
        case foods
        case food
    }
}

private struct FatSecretFoodPayload: Decodable {
    let id: String?
    let name: String
    let servingSizeG: Double
    let calories: Double
    let proteinG: Double
    let carbohydratesTotalG: Double
    let fatTotalG: Double
    let fatSaturatedG: Double
    let sodiumMg: Double
    let potassiumMg: Double
    let cholesterolMg: Double
    let fiberG: Double
    let sugarG: Double

    var asNutritionItem: NutritionItem? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }
        return NutritionItem(
            name: trimmedName.lowercased(),
            calories: calories,
            servingSizeG: max(servingSizeG, 1),
            fatTotalG: fatTotalG,
            fatSaturatedG: fatSaturatedG,
            proteinG: proteinG,
            sodiumMg: sodiumMg,
            potassiumMg: potassiumMg,
            cholesterolMg: cholesterolMg,
            carbohydratesTotalG: carbohydratesTotalG,
            fiberG: fiberG,
            sugarG: sugarG
        )
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)

        id = container.decodeStringIfPresent(["id", "food_id", "foodId"])
        name = container.decodeString(["name", "food_name", "foodName"], defaultValue: "")
        servingSizeG = container.decodeDouble(["serving_size_g", "servingSizeG", "serving_size"], defaultValue: 100)
        calories = container.decodeDouble(["calories", "energy_kcal", "kcal"], defaultValue: 0)
        proteinG = container.decodeDouble(["protein_g", "protein"], defaultValue: 0)
        carbohydratesTotalG = container.decodeDouble(["carbohydrates_total_g", "carbs_g", "carbohydrate_g", "carbs"], defaultValue: 0)
        fatTotalG = container.decodeDouble(["fat_total_g", "fat_g", "fat"], defaultValue: 0)
        fatSaturatedG = container.decodeDouble(["fat_saturated_g", "saturated_fat_g"], defaultValue: 0)
        sodiumMg = container.decodeDouble(["sodium_mg", "sodium"], defaultValue: 0)
        potassiumMg = container.decodeDouble(["potassium_mg", "potassium"], defaultValue: 0)
        cholesterolMg = container.decodeDouble(["cholesterol_mg", "cholesterol"], defaultValue: 0)
        fiberG = container.decodeDouble(["fiber_g", "fibre_g", "fiber"], defaultValue: 0)
        sugarG = container.decodeDouble(["sugar_g", "sugars_g", "sugar"], defaultValue: 0)
    }
}

private struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}

private extension KeyedDecodingContainer where K == DynamicCodingKey {
    func decodeString(_ keys: [String], defaultValue: String) -> String {
        for key in keys {
            let codingKey = DynamicCodingKey(stringValue: key)!
            if let value = try? decode(String.self, forKey: codingKey) {
                return value
            }
        }
        return defaultValue
    }

    func decodeStringIfPresent(_ keys: [String]) -> String? {
        for key in keys {
            let codingKey = DynamicCodingKey(stringValue: key)!
            if let value = try? decodeIfPresent(String.self, forKey: codingKey) {
                return value
            }
        }
        return nil
    }

    func decodeDouble(_ keys: [String], defaultValue: Double) -> Double {
        for key in keys {
            let codingKey = DynamicCodingKey(stringValue: key)!
            if let value = try? decode(Double.self, forKey: codingKey) {
                return value
            }
            if let intValue = try? decode(Int.self, forKey: codingKey) {
                return Double(intValue)
            }
            if let stringValue = try? decode(String.self, forKey: codingKey),
               let value = Double(stringValue.replacingOccurrences(of: ",", with: ".")) {
                return value
            }
        }
        return defaultValue
    }
}
