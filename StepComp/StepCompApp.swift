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
    @ObservedObject private var authService = AuthService.shared
    
    init() {
        // Initialize notification managers
        _ = StepGoalNotificationService.shared
        _ = NotificationManager.shared
        
        // Request notification permissions on first launch
        Task {
            try? await NotificationManager.shared.requestAuthorization()
        }
        
        // Setup global fonts (rounded typography matching reference UI)
        #if os(iOS)
        AppFontConfiguration.setupGlobalFonts()
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
                .onOpenURL { url in
                    // #region agent log
                    print("============================================================")
                    print("🔍 [H9] ===== onOpenURL CALLED =====")
                    print("🔍 [H9] Full URL: \(url.absoluteString)")
                    print("🔍 [H9] URL scheme: \(url.scheme ?? "nil")")
                    print("🔍 [H9] URL host: \(url.host() ?? "nil")")
                    print("🔍 [H9] URL path: \(url.path())")
                    print("🔍 [H9] URL query: \(url.query() ?? "nil")")
                    print("🔍 [H9] URL fragment: \(url.fragment() ?? "nil")")
                    print("============================================================")
                    // #endregion
                    
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
        // #region agent log
        print("🔍 [H9] handleOAuthCallback called with: \(url.absoluteString)")
        // #endregion
        
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
        
        // #region agent log
        print("🔍 [H9] Not a password reset - attempting OAuth session check")
        // #endregion
        
        // Process OAuth callback with Supabase (for Apple/Google sign-in)
        // The Supabase SDK should automatically handle the callback URL
        // We just need to check for the session
        do {
            // Wait a moment for Supabase to process the callback
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // #region agent log
            print("🔍 [H9] Checking for Supabase session...")
            // #endregion
            
            // Check if session was established
            let session = try await supabase.auth.session
            print("✅ OAuth session established at app level: \(session.user.id)")
            
            // Refresh auth service session
            authService.checkSupabaseSession()
        } catch {
            // #region agent log
            print("❌ [H9] Error getting session: \(error.localizedDescription)")
            // #endregion
            
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
