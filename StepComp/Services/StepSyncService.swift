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

#if os(iOS)
import UIKit
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
        
        // Check if we have a valid session before trying to sync
        // This prevents 401 errors when session is still being restored
        do {
            let session = try await supabase.auth.session
            guard !session.user.id.uuidString.isEmpty else {
                print("⚠️ No valid session, skipping step sync")
                return
            }
        } catch {
            print("⚠️ Session not available, skipping step sync: \(error.localizedDescription)")
            return
        }
        
        do {
            // Get today's steps from HealthKit
            let todaySteps = try await healthKitService.getSteps(for: Date())
            
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
    /// Payload for Edge Function
    private struct SyncStepsPayload: Codable {
        let day: String
        let steps: Int
        let device_id: String
        
        enum CodingKeys: String, CodingKey {
            case day
            case steps
            case device_id
        }
    }
    
    /// Sync steps via Edge Function (with rate limiting and validation)
    /// This is the ONLY way steps should be written to the database
    private func syncStepsViaEdgeFunction(
        steps: Int,
        day: String
    ) async throws {
        let deviceId = await getDeviceIdentifier()
        
        // Prepare payload (Codable struct)
        let payload = SyncStepsPayload(
            day: day,
            steps: steps,
            device_id: deviceId
        )
        
        struct EdgeFunctionResponse: Decodable {
            let success: Bool
            let data: EdgeData?
            let error: String?
            
            struct EdgeData: Decodable {
                let is_suspicious: Bool?
            }
        }
        
        // Call Edge Function and decode JSON response
        // Handle 401 errors by refreshing session and retrying (Instagram pattern)
        do {
            let response: EdgeFunctionResponse = try await supabase.functions
                .invoke("sync-steps", options: FunctionInvokeOptions(body: payload))
            
            if response.success {
                print("✅ Edge Function sync successful")
                if let isSuspicious = response.data?.is_suspicious, isSuspicious {
                    print("⚠️ Steps flagged as suspicious - under review")
                }
            } else if let errorMessage = response.error {
                print("❌ Edge Function error: \(errorMessage)")
                throw NSError(
                    domain: "StepSyncError",
                    code: 400,
                    userInfo: [NSLocalizedDescriptionKey: errorMessage]
                )
            }
        } catch {
            let errorDescription = error.localizedDescription.lowercased()
            
            // Handle 401 (Unauthorized) - try to refresh session, NOT logout
            if errorDescription.contains("401") || errorDescription.contains("unauthorized") {
                print("⚠️ Got 401 - attempting session refresh...")
                let refreshed = await AuthService.shared.refreshSessionOn401()
                
                if refreshed {
                    // Retry the sync with refreshed session
                    print("🔄 Session refreshed, retrying sync...")
                    
                    do {
                        let retryResponse: EdgeFunctionResponse = try await supabase.functions
                            .invoke("sync-steps", options: FunctionInvokeOptions(body: payload))
                        if retryResponse.success {
                            print("✅ Edge Function sync successful after refresh")
                        }
                    } catch {
                        print("⚠️ Edge Function retry failed, using RPC fallback...")
                        // Fall back to RPC when Edge Function consistently fails
                        try await syncStepsViaRPCFallback(steps: steps, day: day, deviceId: deviceId)
                    }
                } else {
                    // Refresh failed - user will be logged out by AuthService
                    print("❌ Session refresh failed - user will be logged out")
                }
                return
            }
            
            // Handle 404 (Edge Function not deployed) gracefully
            if errorDescription.contains("404") || errorDescription.contains("not found") {
                print("⚠️ Edge Function 'sync-steps' not deployed. Steps will sync via RPC fallback.")
                // Fallback: Call RPC directly (less secure but works)
                try await syncStepsViaRPCFallback(steps: steps, day: day, deviceId: deviceId)
            } else {
                throw error
            }
        }
    }
    
    /// Get device identifier for fraud detection
    private func getDeviceIdentifier() async -> String {
        #if os(iOS)
        return await MainActor.run {
            UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        }
        #else
        return "unknown"
        #endif
    }
    
    /// Fallback: Sync steps via RPC if Edge Function is not deployed
    private func syncStepsViaRPCFallback(steps: Int, day: String, deviceId: String) async throws {
        print("🔄 Using RPC fallback for step sync")
        _ = try await supabase.rpc("sync_daily_steps", params: [
            "p_day": day,
            "p_steps": String(steps),
            "p_source": "healthkit",
            "p_device_id": deviceId,
            "p_ip": nil, // PostgreSQL inet type requires valid IP or NULL
            "p_user_agent": "iOS"
        ]).execute()
        print("✅ Steps synced via RPC fallback")
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
