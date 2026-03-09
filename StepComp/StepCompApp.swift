//
//  StepCompApp.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine
#if canImport(Supabase)
import Supabase
#endif

@main
struct StepCompApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    // Note: AuthService.shared is accessed lazily to avoid blocking app launch
    @ObservedObject private var authService = AuthService.shared
    
    init() {
        // Setup global fonts first (synchronous, fast)
        #if os(iOS)
        AppFontConfiguration.setupGlobalFonts()
        #endif
        
        // Initialize notification managers in background to avoid blocking launch
        // This prevents the app from freezing if notification APIs are slow
        Task.detached(priority: .utility) {
            _ = await MainActor.run { StepGoalNotificationService.shared }
            _ = await MainActor.run { NotificationManager.shared }
            try? await NotificationManager.shared.requestAuthorization()
        }
        
        // Sync any locally-saved workout sessions and weight entries that
        // haven't been pushed to Supabase yet (handles offline catch-up).
        Task.detached(priority: .utility) {
            await MetricsService.shared.syncAllLocalData()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
                .onOpenURL { url in
                    print("============================================================")
                    print("============================================================")
                    
                    // Handle deep links (friend invites, OAuth, etc.)
                    DeepLinkRouter.shared.handle(url: url)
                    
                    // Handle OAuth callback at app level
                    // This ensures callbacks are handled even if SignInView is not visible
                    Task {
                        await handleOAuthCallback(url: url)
                    }
                }
        }
    }
    
    #if canImport(Supabase)
    private func handleOAuthCallback(url: URL) async {
        
        print("🔵 App-level callback received: \(url)")
        
        // Check if this is a password reset callback
        // Supabase password reset URLs contain type=recovery or access_token with type=recovery
        let urlString = url.absoluteString
        if urlString.contains("type=recovery") || urlString.contains("reset-password") {
            print("🔑 Password reset callback detected")
            // Let DeepLinkRouter handle it (it will set pendingPasswordResetURL)
            // No need to post notification - RootView observes DeepLinkRouter directly
            return
        }
        
        
        // Process OAuth callback with Supabase (for Apple/Google sign-in)
        // The Supabase SDK should automatically handle the callback URL
        // We just need to check for the session
        do {
            // Wait a moment for Supabase to process the callback
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            
            // Check if session was established
            let session = try await supabase.auth.session
            print("✅ OAuth session established at app level: \(session.user.id)")
            
            // Refresh auth service session
            authService.checkSupabaseSession()
        } catch {
            print("❌ [H9] Error getting session: \(error.localizedDescription)")
            
            print("⚠️ Error processing OAuth callback at app level: \(error.localizedDescription)")
            print("⚠️ Error details: \(error)")
        }
    }
    #else
    private func handleOAuthCallback(url: URL) async {
        // Supabase not available - do nothing
    }
    #endif
}
