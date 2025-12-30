//
//  HealthKitService.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation
import Combine

#if os(iOS)
import HealthKit
#endif

@MainActor
final class HealthKitService: ObservableObject {
    #if os(iOS)
    private var healthStore: HKHealthStore?
    private var stepCountType: HKQuantityType?
    private var distanceType: HKQuantityType?
    private var activeEnergyType: HKQuantityType?
    private var healthKitInitialized = false
    #endif
    
    @Published var isAuthorized: Bool = false
    #if os(iOS)
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    #else
    @Published var authorizationStatus: Int = 0 // Placeholder for non-iOS
    #endif
    
    var isHealthKitAvailable: Bool {
        #if os(iOS)
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        // Lazy initialization - only try once
        if !healthKitInitialized {
            initializeHealthKit()
        }
        return healthStore != nil && stepCountType != nil
        #else
        return false
        #endif
    }
    
    init() {
        // Don't check authorization in init - wait until needed
        // This prevents crashes if HealthKit entitlement is missing
    }
    
    #if os(iOS)
    private func initializeHealthKit() {
        guard !healthKitInitialized else { return }
        healthKitInitialized = true
        
        // Initialize HealthKit - these don't throw, but we check for nil
        healthStore = HKHealthStore()
        stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)
        distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)
        activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
        
        // If types are nil, HealthKit is not available (likely missing entitlement)
        if stepCountType == nil || distanceType == nil || activeEnergyType == nil {
            healthStore = nil
            stepCountType = nil
            distanceType = nil
            activeEnergyType = nil
            isAuthorized = false
            authorizationStatus = .notDetermined
            return
        }
        
        // Now check authorization status
        checkAuthorizationStatus()
    }
    #endif
    
    func checkAuthorizationStatus() {
        #if os(iOS)
        guard isHealthKitAvailable,
              let healthStore = healthStore,
              let stepCountType = stepCountType else {
            isAuthorized = false
            authorizationStatus = .notDetermined
            return
        }
        
        let status = healthStore.authorizationStatus(for: stepCountType)
        authorizationStatus = status
        isAuthorized = status == .sharingAuthorized
        #else
        // HealthKit not available on this platform
        isAuthorized = false
        authorizationStatus = 0
        #endif
    }
    
    func requestAuthorization() async throws {
        #if os(iOS)
        // Ensure HealthKit is initialized
        if !healthKitInitialized {
            initializeHealthKit()
        }
        
        guard isHealthKitAvailable,
              let healthStore = healthStore,
              let stepCountType = stepCountType,
              let distanceType = distanceType,
              let activeEnergyType = activeEnergyType else {
            // HealthKit not available or entitlement missing - allow app to continue
            isAuthorized = false
            print("⚠️ HealthKit not available - missing entitlement or Info.plist entries")
            return
        }
        
        // Check if Info.plist has required usage descriptions
        // If not, don't request authorization to avoid crash
        let infoPlist = Bundle.main.infoDictionary
        let hasShareDescription = infoPlist?["NSHealthShareUsageDescription"] != nil
        let hasUpdateDescription = infoPlist?["NSHealthUpdateUsageDescription"] != nil
        
        guard hasShareDescription && hasUpdateDescription else {
            print("⚠️ HealthKit usage descriptions missing in Info.plist. Please add NSHealthShareUsageDescription and NSHealthUpdateUsageDescription.")
            isAuthorized = false
            return
        }
        
        let typesToRead: Set<HKObjectType> = [stepCountType, distanceType, activeEnergyType]
        let typesToShare: Set<HKSampleType> = [stepCountType, distanceType, activeEnergyType]
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            checkAuthorizationStatus()
        } catch {
            // Don't throw error - just mark as not authorized so app can continue
            isAuthorized = false
            // Optionally log the error for debugging
            print("⚠️ HealthKit authorization failed: \(error.localizedDescription)")
        }
        #else
        // HealthKit not available on this platform
        isAuthorized = false
        #endif
    }
    
    func getTodaySteps() async throws -> Int {
        #if os(iOS)
        guard isAuthorized,
              let healthStore = healthStore,
              let stepCountType = stepCountType else {
            return 0 // Return 0 if not authorized or HealthKit unavailable
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepCountType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if error != nil {
                    continuation.resume(returning: 0) // Return 0 instead of throwing
                    return
                }
                
                guard let result = result,
                      let sum = result.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                
                let steps = Int(sum.doubleValue(for: HKUnit.count()))
                continuation.resume(returning: steps)
            }
            
            healthStore.execute(query)
        }
        #else
        return 0
        #endif
    }
    
    func getSteps(for date: Date) async throws -> Int {
        #if os(iOS)
        guard isAuthorized,
              let healthStore = healthStore,
              let stepCountType = stepCountType else {
            return 0
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepCountType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if error != nil {
                    continuation.resume(returning: 0)
                    return
                }
                
                guard let result = result,
                      let sum = result.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                
                let steps = Int(sum.doubleValue(for: HKUnit.count()))
                continuation.resume(returning: steps)
            }
            
            healthStore.execute(query)
        }
        #else
        return 0
        #endif
    }
    
    func getSteps(from startDate: Date, to endDate: Date) async throws -> [StepStats] {
        #if os(iOS)
        guard isAuthorized,
              let healthStore = healthStore,
              let stepCountType = stepCountType else {
            return []
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: stepCountType,
                quantitySamplePredicate: predicate,
                anchorDate: startDate,
                intervalComponents: DateComponents(day: 1)
            )
            
            query.initialResultsHandler = { _, results, error in
                if error != nil {
                    continuation.resume(returning: [])
                    return
                }
                
                guard let results = results else {
                    continuation.resume(returning: [])
                    return
                }
                
                var stats: [StepStats] = []
                results.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    let steps = Int(statistics.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0)
                    let stat = StepStats(
                        userId: "", // Will be set by caller
                        date: statistics.startDate,
                        steps: steps
                    )
                    stats.append(stat)
                }
                
                continuation.resume(returning: stats)
            }
            
            healthStore.execute(query)
        }
        #else
        return []
        #endif
    }
}

enum HealthKitError: LocalizedError {
    case notAvailable
    case notAuthorized
    case authorizationFailed(Error)
    case queryFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .notAuthorized:
            return "HealthKit authorization is required"
        case .authorizationFailed(let error):
            return "Authorization failed: \(error.localizedDescription)"
        case .queryFailed(let error):
            return "Query failed: \(error.localizedDescription)"
        }
    }
}

