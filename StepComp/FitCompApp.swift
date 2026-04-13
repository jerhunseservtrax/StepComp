//
//  FitCompApp.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine
#if canImport(Supabase)
import Supabase
#endif

@main
struct FitCompApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    // Note: AuthService.shared is accessed lazily to avoid blocking app launch
    @ObservedObject private var authService = AuthService.shared
    
    init() {
        // Setup global fonts first (synchronous, fast)
        #if os(iOS)
        AppFontConfiguration.setupGlobalFonts()
        #endif
        CrashReportingService.configure()
        
        // Initialize notification managers in background to avoid blocking launch
        // This prevents the app from freezing if notification APIs are slow
        Task.detached(priority: .utility) {
            _ = await MainActor.run { StepGoalNotificationService.shared }
            _ = await MainActor.run { NotificationManager.shared }
            try? await NotificationManager.shared.requestAuthorization()
        }
        
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
                .onOpenURL { url in
                    print("============================================================")
                    print("============================================================")
                    
                    #if canImport(Supabase)
                    // Supabase must handle OAuth/password-reset deep links to persist sessions correctly.
                    supabase.auth.handle(url)
                    #endif
                    
                    // Handle deep links (friend invites, OAuth, etc.)
                    DeepLinkRouter.shared.handle(url: url)
                }
        }
    }
}
