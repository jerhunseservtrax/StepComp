//
//  FoodLogViewModel.swift
//  FitComp
//

import Foundation
import Combine
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class FoodLogViewModel: ObservableObject {
    static let shared = FoodLogViewModel()

    @Published private(set) var entries: [FoodLogEntry] = []
    @Published private(set) var cachedFoods: [FoodItem] = []
    @Published var isSearching = false
    @Published var searchResults: [NutritionItem] = []
    @Published var errorMessage: String?
    @Published var scanStatus: PhotoScanStatus = .idle

    enum PhotoScanStatus: Equatable {
        case idle
        case scanning
        case foundItems
        case noTextDetected
    }

    private let storageKey = "food_log_entries"
    private let cachedFoodsKey = "food_log_cached_foods"
    private let maxCachedFoods = 30
    private let fatSecretService = FatSecretFoodService.shared
    private let usdaService = USDAFoodService.shared
    private let calorieService = CalorieNinjasService.shared
    private let metricsStore = ComprehensiveMetricsStore.shared
    private var searchGeneration = FoodSearchGeneration()

    private init() {
        loadEntries()
        loadCachedFoods()
        syncNutritionLogsToMetrics()
    }

    // MARK: - Daily Summary

    var todaySummary: DailyNutritionSummary {
        let today = Calendar.current.startOfDay(for: Date())
        let todayEntries = entries.filter {
            Calendar.current.isDate($0.loggedAt, inSameDayAs: today)
        }
        return DailyNutritionSummary(
            date: today,
            totalCalories: todayEntries.reduce(0) { $0 + $1.totalCalories },
            totalProteinG: todayEntries.reduce(0) { $0 + $1.totalProteinG },
            totalCarbsG: todayEntries.reduce(0) { $0 + $1.totalCarbsG },
            totalFatG: todayEntries.reduce(0) { $0 + $1.totalFatG },
            mealCount: todayEntries.count
        )
    }

    func entriesForDate(_ date: Date) -> [FoodLogEntry] {
        entries.filter { Calendar.current.isDate($0.loggedAt, inSameDayAs: date) }
            .sorted { $0.loggedAt > $1.loggedAt }
    }

    var todayEntries: [FoodLogEntry] {
        entriesForDate(Date())
    }

    var todayEntriesByMeal: [MealType: [FoodLogEntry]] {
        Dictionary(grouping: todayEntries, by: \.mealType)
    }

    var recentMealEntries: [FoodLogEntry] {
        entries
            .sorted { $0.loggedAt > $1.loggedAt }
            .filter { !$0.items.isEmpty }
            .prefix(15)
            .map { $0 }
    }

    // MARK: - API Lookup

    func clearSearchResults() {
        _ = searchGeneration.begin()
        isSearching = false
        searchResults = []
        errorMessage = nil
    }

    func searchFood(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let token = searchGeneration.begin()
        guard !trimmed.isEmpty else {
            _ = publishSearchResults([], token: token, errorMessage: nil)
            if searchGeneration.isCurrent(token) {
                isSearching = false
            }
            return
        }
        isSearching = true
        errorMessage = nil
        do {
            var results: [NutritionItem] = []
            do {
                results = try await fatSecretService.searchFoods(query: trimmed)
            } catch {
                results = []
            }
            guard publishSearchResults(results, token: token) else { return }
            if results.isEmpty {
                do {
                    results = try await usdaService.searchFoods(query: trimmed)
                } catch {
                    results = []
                }
                guard publishSearchResults(results, token: token) else { return }
            }
            if results.isEmpty {
                results = try await calorieService.lookupNutrition(query: trimmed)
                guard publishSearchResults(results, token: token) else { return }
            }
            if results.isEmpty {
                guard publishSearchResults([], token: token, errorMessage: "No results found for \"\(trimmed)\"") else { return }
            }
        } catch {
            _ = publishSearchResults([], token: token, errorMessage: error.localizedDescription)
        }
        if searchGeneration.isCurrent(token) {
            isSearching = false
        }
    }

    func searchFoodByBarcode(_ barcode: String) async {
        let trimmed = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let token = searchGeneration.begin()
        isSearching = true
        errorMessage = nil
        do {
            var results: [NutritionItem] = []
            do {
                results = try await fatSecretService.searchByBarcode(upc: trimmed)
            } catch {
                results = []
            }
            guard publishSearchResults(results, token: token) else { return }
            if results.isEmpty {
                do {
                    results = try await usdaService.searchByUPC(upc: trimmed)
                } catch {
                    results = []
                }
                guard publishSearchResults(results, token: token) else { return }
            }
            if results.isEmpty {
                results = try await calorieService.lookupNutritionByBarcode(trimmed)
                guard publishSearchResults(results, token: token) else { return }
            }
            if results.isEmpty {
                guard publishSearchResults([], token: token, errorMessage: "No product found for barcode \(trimmed).") else { return }
            }
        } catch {
            _ = publishSearchResults([], token: token, errorMessage: error.localizedDescription)
        }
        if searchGeneration.isCurrent(token) {
            isSearching = false
        }
    }

    #if canImport(UIKit)
    /// Two-step scan: try OCR text extraction from the image first (works for menus,
    /// receipts, recipe cards). If nothing is detected, signal that the user should
    /// describe what they see so we can use the text API instead.
    func scanImage(_ image: UIImage) async {
        let token = searchGeneration.begin()
        scanStatus = .scanning
        isSearching = true
        errorMessage = nil

        do {
            let items = try await calorieService.scanImageForNutrition(image: image)
            if items.isEmpty {
                scanStatus = .noTextDetected
                _ = publishSearchResults([], token: token)
            } else {
                if publishSearchResults(items, token: token) {
                    scanStatus = .foundItems
                }
            }
        } catch {
            scanStatus = .noTextDetected
            _ = publishSearchResults([], token: token)
        }
        if searchGeneration.isCurrent(token) {
            isSearching = false
        }
    }

    func resetScanStatus() {
        scanStatus = .idle
    }
    #endif

    @discardableResult
    private func publishSearchResults(
        _ results: [NutritionItem],
        token: UInt,
        errorMessage: String? = nil
    ) -> Bool {
        guard searchGeneration.isCurrent(token) else { return false }
        searchResults = results
        self.errorMessage = errorMessage
        return true
    }

    // MARK: - CRUD

    func addEntry(mealType: MealType, description: String, items: [FoodItem], photo: UIImage?) {
        var photoFileName: String?
        if let photo {
            photoFileName = savePhoto(photo)
        }

        let entry = FoodLogEntry(
            id: UUID(),
            mealType: mealType,
            description: description,
            items: items,
            photoFileName: photoFileName,
            loggedAt: Date()
        )
        entries.insert(entry, at: 0)
        cacheSelectedFoods(items)
        saveEntries()
        syncNutritionLogsToMetrics()
        syncEntryToSupabaseMetrics(entry)
    }

    func cacheSelectedFoods(_ items: [FoodItem]) {
        guard !items.isEmpty else { return }
        var updated = cachedFoods

        for item in items {
            let key = cacheKey(for: item)
            if let existingIndex = updated.firstIndex(where: { cacheKey(for: $0) == key }) {
                updated.remove(at: existingIndex)
            }

            let cachedItem = FoodItem(
                id: UUID(),
                name: item.name,
                sourceKey: item.sourceKey,
                calories: item.calories,
                proteinG: item.proteinG,
                carbsG: item.carbsG,
                fatG: item.fatG,
                servingSizeG: item.servingSizeG,
                consumedWeightG: item.consumedWeightG ?? item.servingSizeG,
                fiberG: item.fiberG,
                sugarG: item.sugarG
            )
            updated.insert(cachedItem, at: 0)
        }

        if updated.count > maxCachedFoods {
            updated = Array(updated.prefix(maxCachedFoods))
        }

        cachedFoods = updated
        saveCachedFoods()
    }

    func deleteEntry(_ entry: FoodLogEntry) {
        if let photoName = entry.photoFileName {
            deletePhoto(named: photoName)
        }
        entries.removeAll { $0.id == entry.id }
        saveEntries()
        syncNutritionLogsToMetrics()
    }

    // MARK: - Photo Storage

    #if canImport(UIKit)
    func loadPhoto(named fileName: String) -> UIImage? {
        let url = photoDirectory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
    #endif

    private var photoDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("MealPhotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    #if canImport(UIKit)
    private func savePhoto(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.7) else { return nil }
        let name = "\(UUID().uuidString).jpg"
        let url = photoDirectory.appendingPathComponent(name)
        do {
            try data.write(to: url)
            return name
        } catch {
            print("Failed to save meal photo: \(error)")
            return nil
        }
    }
    #endif

    private func deletePhoto(named fileName: String) {
        let url = photoDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Persistence

    private func saveEntries() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func loadEntries() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([FoodLogEntry].self, from: data) else { return }
        entries = decoded
    }

    private func saveCachedFoods() {
        guard let data = try? JSONEncoder().encode(cachedFoods) else { return }
        UserDefaults.standard.set(data, forKey: cachedFoodsKey)
    }

    private func loadCachedFoods() {
        guard let data = UserDefaults.standard.data(forKey: cachedFoodsKey),
              let decoded = try? JSONDecoder().decode([FoodItem].self, from: data) else { return }
        cachedFoods = decoded
    }

    private func cacheKey(for item: FoodItem) -> String {
        if let sourceKey = item.sourceKey, !sourceKey.isEmpty {
            return sourceKey
        }
        return [
            item.name.lowercased(),
            String(format: "%.3f", item.calories),
            String(format: "%.3f", item.servingSizeG),
            String(format: "%.3f", item.proteinG),
            String(format: "%.3f", item.carbsG),
            String(format: "%.3f", item.fatG)
        ].joined(separator: "|")
    }

    private func syncNutritionLogsToMetrics() {
        let logs = entries.map { entry in
            NutritionLog(
                id: entry.id,
                loggedAt: entry.loggedAt,
                calories: Int(entry.totalCalories.rounded()),
                proteinG: Int(entry.totalProteinG.rounded()),
                carbsG: Int(entry.totalCarbsG.rounded()),
                fatG: Int(entry.totalFatG.rounded()),
                waterMl: 0
            )
        }
        metricsStore.replaceNutritionLogs(logs)
    }

    private func syncEntryToSupabaseMetrics(_ entry: FoodLogEntry) {
        let log = NutritionLog(
            id: entry.id,
            loggedAt: entry.loggedAt,
            calories: Int(entry.totalCalories.rounded()),
            proteinG: Int(entry.totalProteinG.rounded()),
            carbsG: Int(entry.totalCarbsG.rounded()),
            fatG: Int(entry.totalFatG.rounded()),
            waterMl: 0
        )
        Task.detached(priority: .utility) {
            await MetricsService.shared.syncNutritionLog(log)
        }
    }
}
