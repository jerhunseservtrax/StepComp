//
//  WeightViewModel.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 2/23/26.
//

import Foundation
import Combine
#if os(iOS)
import HealthKit
#endif

@MainActor
class WeightViewModel: ObservableObject {
    static let shared = WeightViewModel()
    
    @Published var entries: [WeightEntry] = []
    @Published var latestWeight: Double?
    
    private let userDefaultsKey = "weight_entries"
    private let healthKitService: HealthKitService
    
    private init() {
        self.healthKitService = HealthKitService()
        loadEntries()
        
        // Sync with HealthKit on init
        Task {
            await syncWithHealthKit()
        }
    }
    
    // MARK: - Public Methods
    
    func addEntry(weightKg: Double, date: Date, source: WeightEntry.WeightSource) {
        let entry = WeightEntry(date: date, weightKg: weightKg, source: source)
        entries.append(entry)
        entries.sort { $0.date > $1.date } // Newest first
        updateLatestWeight()
        saveEntries()
        
        // Write to HealthKit if manual entry
        if source == .manual {
            Task {
                await writeToHealthKit(weightKg: weightKg, date: date)
            }
        }
        
        // Sync to Supabase in the background
        let entryToSync = entry
        Task.detached(priority: .utility) {
            await MetricsService.shared.syncWeightEntry(entryToSync)
        }
    }
    
    func deleteEntry(id: UUID) {
        entries.removeAll { $0.id == id }
        updateLatestWeight()
        saveEntries()
    }
    
    func getEntriesForGraph(days: Int = 90) -> [WeightEntry] {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return entries.filter { $0.date >= cutoffDate }.sorted { $0.date < $1.date }
    }
    
    // MARK: - HealthKit Integration
    
    func syncWithHealthKit() async {
        guard healthKitService.isAuthorized else {
            print("⚠️ HealthKit not authorized, skipping sync")
            return
        }
        
        do {
            if let healthKitWeight = try await healthKitService.getWeight() {
                // Check if we need to add this as a new entry
                let today = Calendar.current.startOfDay(for: Date())
                let hasEntryToday = entries.contains { entry in
                    Calendar.current.isDate(entry.date, inSameDayAs: today)
                }
                
                if !hasEntryToday {
                    let entry = WeightEntry(
                        date: Date(),
                        weightKg: healthKitWeight,
                        source: .healthKit
                    )
                    entries.append(entry)
                    entries.sort { $0.date > $1.date }
                    updateLatestWeight()
                    saveEntries()
                    print("✅ Synced weight from HealthKit: \(healthKitWeight) kg")
                }
            }
        } catch {
            print("❌ Failed to sync with HealthKit: \(error)")
        }
    }
    
    private func writeToHealthKit(weightKg: Double, date: Date) async {
        #if os(iOS)
        guard healthKitService.isAuthorized else { return }
        
        // Use the new saveWeight function we'll add to HealthKitService
        do {
            try await healthKitService.saveWeight(weightKg: weightKg, date: date)
            print("✅ Saved weight to HealthKit: \(weightKg) kg")
        } catch {
            print("❌ Failed to save weight to HealthKit: \(error)")
        }
        #endif
    }
    
    // MARK: - Persistence
    
    private func saveEntries() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([WeightEntry].self, from: data) {
            entries = decoded.sorted { $0.date > $1.date }
            updateLatestWeight()
        }
    }
    
    private func updateLatestWeight() {
        latestWeight = entries.first?.weightKg
    }
}
