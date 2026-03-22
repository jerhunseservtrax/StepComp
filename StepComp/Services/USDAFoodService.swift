//
//  USDAFoodService.swift
//  FitComp
//

import Foundation

enum USDAFoodConfig {
    static let baseURL = URL(string: "https://api.nal.usda.gov/fdc/v1")!
    static let apiKey = "9pCUtDv1MR7nj9aB7GUrJcggSSPhr5wDwaZLm3bd"
}

enum USDAFoodError: LocalizedError {
    case invalidRequest
    case requestFailed
    case invalidResponse
    case noResults

    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return "Could not build USDA request."
        case .requestFailed:
            return "USDA lookup failed. Please try again."
        case .invalidResponse:
            return "Received an invalid USDA response."
        case .noResults:
            return "No matching USDA foods found."
        }
    }
}

private struct FDCSearchRequest: Encodable {
    let query: String
    let pageSize: Int
    let dataType: [String]?
}

private struct FDCSearchResponse: Decodable {
    let totalHits: Int?
    let foods: [FDCFood]
}

private struct FDCFood: Decodable {
    let fdcId: Int
    let description: String
    let dataType: String?
    let gtinUpc: String?
    let brandOwner: String?
    let brandName: String?
    let servingSize: Double?
    let servingSizeUnit: String?
    let foodNutrients: [FDCNutrient]
}

private struct FDCNutrient: Decodable {
    let nutrientId: Int
    let nutrientName: String
    let unitName: String
    let value: Double
}

@MainActor
final class USDAFoodService {
    static let shared = USDAFoodService()
    private init() {}

    func searchFoods(query: String, pageSize: Int = 25) async throws -> [NutritionItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let requestBody = FDCSearchRequest(
            query: trimmed,
            pageSize: min(max(pageSize, 1), 200),
            dataType: nil
        )

        let response: FDCSearchResponse = try await performSearch(requestBody)
        let items = response.foods.compactMap(mapToNutritionItem)
        return locallyRanked(items: items, query: trimmed)
    }

    func searchByUPC(upc: String) async throws -> [NutritionItem] {
        let normalized = upc.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return [] }

        let requestBody = FDCSearchRequest(
            query: normalized,
            pageSize: 10,
            dataType: ["Branded"]
        )

        let response: FDCSearchResponse = try await performSearch(requestBody)

        let exactMatches = response.foods.filter {
            ($0.gtinUpc ?? "").trimmingCharacters(in: .whitespacesAndNewlines) == normalized
        }
        let candidates = exactMatches.isEmpty ? response.foods : exactMatches
        return candidates.compactMap(mapToNutritionItem)
    }

    private func performSearch(_ requestBody: FDCSearchRequest) async throws -> FDCSearchResponse {
        var components = URLComponents(
            url: USDAFoodConfig.baseURL.appendingPathComponent("foods/search"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "api_key", value: USDAFoodConfig.apiKey)]

        guard let url = components?.url else {
            throw USDAFoodError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw USDAFoodError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw USDAFoodError.requestFailed
        }

        return try JSONDecoder().decode(FDCSearchResponse.self, from: data)
    }

    private func mapToNutritionItem(_ food: FDCFood) -> NutritionItem? {
        let name = food.description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }

        let servingSize = food.servingSize ?? 100.0
        let multiplier = max(servingSize, 1) / 100.0
        let nutrients = Dictionary(uniqueKeysWithValues: food.foodNutrients.map { ($0.nutrientId, $0.value) })

        let energy = nutrientValue(id: 1008, nutrients: nutrients) // kcal
        let protein = nutrientValue(id: 1003, nutrients: nutrients) // g
        let fatTotal = nutrientValue(id: 1004, nutrients: nutrients) // g
        let saturatedFat = nutrientValue(id: 1258, nutrients: nutrients) // g
        let carbs = nutrientValue(id: 1005, nutrients: nutrients) // g
        let fiber = nutrientValue(id: 1079, nutrients: nutrients) // g
        let sugar = nutrientValue(id: 2000, nutrients: nutrients) // g
        let sodium = nutrientValue(id: 1093, nutrients: nutrients) // mg
        let potassium = nutrientValue(id: 1092, nutrients: nutrients) // mg
        let cholesterol = nutrientValue(id: 1253, nutrients: nutrients) // mg

        return NutritionItem(
            name: name.lowercased(),
            calories: energy * multiplier,
            servingSizeG: servingSize,
            fatTotalG: fatTotal * multiplier,
            fatSaturatedG: saturatedFat * multiplier,
            proteinG: protein * multiplier,
            sodiumMg: sodium * multiplier,
            potassiumMg: potassium * multiplier,
            cholesterolMg: cholesterol * multiplier,
            carbohydratesTotalG: carbs * multiplier,
            fiberG: fiber * multiplier,
            sugarG: sugar * multiplier
        )
    }

    private func nutrientValue(id: Int, nutrients: [Int: Double]) -> Double {
        nutrients[id] ?? 0
    }

    private func locallyRanked(items: [NutritionItem], query: String) -> [NutritionItem] {
        let normalizedQuery = normalizeForSearch(query)
        guard !normalizedQuery.isEmpty else { return items }

        return items.enumerated()
            .map { index, item in
                (index: index, item: item, score: relevanceScore(name: item.name, query: normalizedQuery))
            }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.index < rhs.index
                }
                return lhs.score > rhs.score
            }
            .map(\.item)
    }

    private func relevanceScore(name: String, query: String) -> Double {
        let normalizedName = normalizeForSearch(name)
        guard !normalizedName.isEmpty else { return 0 }

        var score = 0.0

        if normalizedName == query {
            score += 2000
        } else if normalizedName.hasPrefix(query) {
            score += 1200
        } else if normalizedName.contains(query) {
            score += 700
        }

        let nameTokens = tokenizeForSearch(normalizedName)
        let queryTokens = tokenizeForSearch(query)
        guard !queryTokens.isEmpty else { return score }

        var exactCount = 0
        var prefixCount = 0
        var fuzzyCount = 0
        var fuzzySimilarityTotal = 0.0

        for queryToken in queryTokens {
            if nameTokens.contains(queryToken) {
                exactCount += 1
                continue
            }

            if nameTokens.contains(where: { $0.hasPrefix(queryToken) || queryToken.hasPrefix($0) }) {
                prefixCount += 1
                continue
            }

            if let best = bestFuzzySimilarity(queryToken: queryToken, nameTokens: nameTokens), best > 0 {
                fuzzyCount += 1
                fuzzySimilarityTotal += best
            }
        }

        score += Double(exactCount) * 260
        score += Double(prefixCount) * 180
        score += Double(fuzzyCount) * 120
        score += fuzzySimilarityTotal * 90

        let tokenCoverage = Double(exactCount + prefixCount + fuzzyCount) / Double(queryTokens.count)
        score += tokenCoverage * 300

        if startsWithTokenSequence(nameTokens: nameTokens, queryTokens: queryTokens, allowFuzzy: false) {
            score += 500
        } else if startsWithTokenSequence(nameTokens: nameTokens, queryTokens: queryTokens, allowFuzzy: true) {
            score += 320
        }

        return score
    }

    private func normalizeForSearch(_ text: String) -> String {
        let lowered = text.lowercased()
        let separators = CharacterSet.alphanumerics.inverted
        let cleaned = lowered.unicodeScalars.map { separators.contains($0) ? " " : String($0) }.joined()
        return cleaned.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    private func tokenizeForSearch(_ text: String) -> [String] {
        text.split(whereSeparator: \.isWhitespace).map(String.init)
    }

    private func startsWithTokenSequence(nameTokens: [String], queryTokens: [String], allowFuzzy: Bool) -> Bool {
        guard !queryTokens.isEmpty, nameTokens.count >= queryTokens.count else { return false }

        for index in queryTokens.indices {
            let queryToken = queryTokens[index]
            let nameToken = nameTokens[index]

            if nameToken == queryToken || nameToken.hasPrefix(queryToken) || queryToken.hasPrefix(nameToken) {
                continue
            }

            if allowFuzzy,
               let similarity = fuzzySimilarity(lhs: queryToken, rhs: nameToken),
               similarity >= 0.72 {
                continue
            }

            return false
        }
        return true
    }

    private func bestFuzzySimilarity(queryToken: String, nameTokens: [String]) -> Double? {
        var best: Double?
        for token in nameTokens {
            guard let similarity = fuzzySimilarity(lhs: queryToken, rhs: token) else { continue }
            if best == nil || similarity > best! {
                best = similarity
            }
        }
        return best
    }

    private func fuzzySimilarity(lhs: String, rhs: String) -> Double? {
        let maxLength = max(lhs.count, rhs.count)
        guard maxLength > 0 else { return nil }

        let distance = levenshteinDistance(lhs, rhs)
        let tolerance = min(2, max(1, maxLength / 4))
        guard distance <= tolerance else { return nil }

        return 1.0 - (Double(distance) / Double(maxLength))
    }

    private func levenshteinDistance(_ lhs: String, _ rhs: String) -> Int {
        let left = Array(lhs)
        let right = Array(rhs)

        if left.isEmpty { return right.count }
        if right.isEmpty { return left.count }

        var previous = Array(0...right.count)
        var current = Array(repeating: 0, count: right.count + 1)

        for i in 1...left.count {
            current[0] = i
            for j in 1...right.count {
                let substitutionCost = left[i - 1] == right[j - 1] ? 0 : 1
                current[j] = min(
                    previous[j] + 1,
                    current[j - 1] + 1,
                    previous[j - 1] + substitutionCost
                )
            }
            swap(&previous, &current)
        }

        return previous[right.count]
    }
}
