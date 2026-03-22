//
//  SupabaseClient.swift
//  FitComp
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
    static let appBundleID = "JE.FitComp"
    static let calorieNinjasEdgeFunctionName = "nutrition-proxy"
    static let fatSecretEdgeFunctionName = "fatsecret-proxy"
    static let exerciseDBEdgeFunctionName = "exercise-gif-proxy"
    
    // OAuth Redirect URL (for OAuth callbacks)
    // IMPORTANT: This must match the URL scheme registered in Info.plist
    // The URL scheme "fitcomp" is registered in Xcode under Info → URL Types
    static var oauthRedirectURL: URL {
        // Must match the scheme in Info.plist URL Types
        URL(string: "fitcomp://auth-callback")!
    }
    
    // Supabase OAuth callback URL (configured in Supabase Dashboard)
    static var supabaseOAuthCallbackURL: String {
        "https://cwrirmowykxajumjokjj.supabase.co/auth/v1/callback"
    }

    static var edgeFunctionsBaseURL: URL {
        URL(string: "\(supabaseURL)/functions/v1")!
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
    
    return SupabaseClient(
        supabaseURL: url,
        supabaseKey: SupabaseConfig.supabaseAnonKey,
        options: .init(
            auth: .init(
                emitLocalSessionAsInitialSession: true
            )
        )
    )
}()
#else
// Placeholder when Supabase package is not added
// The app will use mock authentication until Supabase is configured
#endif

