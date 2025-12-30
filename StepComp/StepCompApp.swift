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
    @State private var showSplash = true
    @StateObject private var authService = AuthService()
    
    var body: some Scene {
        WindowGroup {
            if showSplash {
                SplashScreenView {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showSplash = false
                    }
                }
                .transition(.opacity)
            } else {
                RootView()
                    .transition(.opacity)
                    .environmentObject(authService)
                    .onOpenURL { url in
                        // Handle OAuth callback at app level
                        // This ensures callbacks are handled even if SignInView is not visible
                        Task {
                            await handleOAuthCallback(url: url)
                        }
                    }
            }
        }
    }
    
    #if canImport(Supabase)
    private func handleOAuthCallback(url: URL) async {
        print("🔵 App-level callback received: \(url)")
        
        // Check if this is a password reset callback
        if url.absoluteString.contains("type=recovery") || url.absoluteString.contains("recovery") {
            print("🔵 Password reset callback detected")
            // Post notification to show password reset screen
            NotificationCenter.default.post(
                name: NSNotification.Name("PasswordResetCallback"),
                object: nil,
                userInfo: ["url": url]
            )
            return
        }
        
        // Process OAuth callback with Supabase
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
