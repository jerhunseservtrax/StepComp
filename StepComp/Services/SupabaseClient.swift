//
//  SupabaseClient.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation

// MARK: - Supabase Configuration

enum SupabaseConfig {
    // Supabase project configuration
    // Get these from: https://app.supabase.com/project/YOUR_PROJECT/settings/api
    static let supabaseURL = "https://cwrirmowykxajumjokjj.supabase.co"
    static let supabaseAnonKey = "sb_publishable_sfIAdMwGWCg81LZo_HuNVA_BnMXHA-A"
    
    // OAuth Configuration
    static let googleClientID = "704127110518-fcj9p8s8na0oo9h5e4rv93b7victn1ge.apps.googleusercontent.com"
    static let appBundleID = "JE.StepComp"
    
    // OAuth Redirect URL (for OAuth callbacks)
    // IMPORTANT: This must match the redirect URL configured in Supabase Dashboard
    // For Supabase OAuth, use the Supabase callback URL, not a custom scheme
    static var oauthRedirectURL: URL {
        // Supabase OAuth uses its own callback URL
        // The app will receive the callback via the custom URL scheme
        URL(string: "\(appBundleID.lowercased())://auth-callback")!
    }
    
    // Supabase OAuth callback URL (configured in Supabase Dashboard)
    static var supabaseOAuthCallbackURL: String {
        "https://cwrirmowykxajumjokjj.supabase.co/auth/v1/callback"
    }
}

// MARK: - Supabase Client Singleton
// NOTE: Uncomment after adding Supabase Swift Package
// In Xcode: File → Add Package Dependencies → https://github.com/supabase/supabase-swift

#if canImport(Supabase)
import Supabase

let supabase: SupabaseClient = {
    guard let url = URL(string: SupabaseConfig.supabaseURL) else {
        fatalError("Invalid Supabase URL")
    }
    
    // Note: The warning about initial session emission is expected behavior in current SDK version
    // We handle expired sessions in checkSupabaseSession() by checking session validity
    return SupabaseClient(
        supabaseURL: url,
        supabaseKey: SupabaseConfig.supabaseAnonKey
    )
}()
#else
// Placeholder when Supabase package is not added
// The app will use mock authentication until Supabase is configured
#endif

