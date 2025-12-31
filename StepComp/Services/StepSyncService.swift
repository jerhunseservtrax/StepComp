//
//  StepSyncService.swift
//  StepComp
//
//  Service to sync HealthKit steps to Supabase via secure Edge Function
//  This ensures backend is source of truth with validation and rate limiting
//

import Foundation
import Combine

#if canImport(Supabase)
import Supabase
#endif

@MainActor
final class StepSyncService: ObservableObject {
    private let healthKitService: HealthKitService
    
    init(healthKitService: HealthKitService) {
        self.healthKitService = healthKitService
    }
    
    /// Sync today's steps from HealthKit to Supabase via Edge Function
    /// Edge Function handles: JWT validation, rate limiting, server-side validation
    func syncTodayStepsToProfile() async {
        #if canImport(Supabase)
        guard healthKitService.isAuthorized else {
            print("⚠️ HealthKit not authorized, skipping step sync")
            return
        }
        
        do {
            // Get today's steps from HealthKit
            let todaySteps = try await healthKitService.getTodaySteps()
            
            print("🔄 Syncing \(todaySteps) steps to backend")
            
            // Call Edge Function (server validates and stores)
            try await syncStepsViaEdgeFunction(
                steps: todaySteps,
                day: ISO8601DateFormatter().string(from: Date())
            )
            
            print("✅ Successfully synced \(todaySteps) steps")
        } catch {
            print("⚠️ Error syncing steps: \(error.localizedDescription)")
        }
        #else
        print("⚠️ Supabase not available, skipping step sync")
        #endif
    }
    
    #if canImport(Supabase)
    /// Sync steps via Edge Function (with rate limiting and validation)
    /// This is the ONLY way steps should be written to the database
    private func syncStepsViaEdgeFunction(
        steps: Int,
        day: String
    ) async throws {
        let deviceId = await getDeviceIdentifier()
        
        // Prepare payload
        let payload: [String: Any] = [
            "day": day,
            "steps": steps,
            "device_id": deviceId
        ]
        
        // Call Edge Function
        // Edge Function will:
        // 1. Validate JWT (get userId from token, not client)
        // 2. Check rate limits (30/min, 4/hour)
        // 3. Validate step count (< 100k, no sudden spikes)
        // 4. Call sync_daily_steps() RPC
        // 5. Return result with fraud detection flags
        let response = try await supabase.functions
            .invoke("sync-steps", options: FunctionInvokeOptions(body: payload))
        
        // Parse response
        if let data = response.data,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            
            if let success = json["success"] as? Bool, success {
                print("✅ Edge Function sync successful")
                
                // Check if flagged as suspicious
                if let data = json["data"] as? [String: Any],
                   let isSuspicious = data["is_suspicious"] as? Bool,
                   isSuspicious {
                    print("⚠️ Steps flagged as suspicious - under review")
                }
            } else if let error = json["error"] as? String {
                print("❌ Edge Function error: \(error)")
                throw NSError(
                    domain: "StepSyncError",
                    code: 400,
                    userInfo: [NSLocalizedDescriptionKey: error]
                )
            }
        }
    }
    
    /// Get device identifier for fraud detection
    private func getDeviceIdentifier() async -> String {
        #if os(iOS)
        import UIKit
        return await UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        #else
        return "unknown"
        #endif
    }
    #endif
    
    /// Sync steps to all active challenges for the user
    /// Note: This happens automatically in sync_daily_steps() RPC
    /// No need to do it manually anymore
    func syncStepsToChallenges(challengeService: ChallengeService) async {
        // This is now handled server-side by sync_daily_steps()
        // The RPC automatically updates challenge_members table
        print("ℹ️ Challenge steps are automatically synced by server")
    }
    
    /// Full sync: profile + challenges
    func syncAll(challengeService: ChallengeService) async {
        await syncTodayStepsToProfile()
        // Challenges are automatically updated by server
    }
}
