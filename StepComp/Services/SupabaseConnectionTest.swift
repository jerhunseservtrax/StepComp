//
//  SupabaseConnectionTest.swift
//  StepComp
//
//  Created for testing Supabase connection
//

import Foundation
import Combine // Required for @Published and ObservableObject

#if canImport(Supabase)
import Supabase

@MainActor
class SupabaseConnectionTest: ObservableObject {
    @Published var connectionStatus: ConnectionStatus = .notStarted
    @Published var errorMessage: String?
    @Published var testResults: [TestResult] = []
    
    enum ConnectionStatus {
        case notStarted
        case testing
        case connected
        case failed
    }
    
    struct TestResult {
        let testName: String
        let success: Bool
        let message: String
        let timestamp: Date
    }
    
    func testConnection() async {
        connectionStatus = .testing
        errorMessage = nil
        testResults = []
        
        // Test 1: Check if Supabase client is initialized (it's always initialized if we're in this block)
        await addTestResult(
            name: "Client Initialization",
            success: true,
            message: "Supabase client initialized"
        )
        
        // Test 2: Check Supabase URL
        let urlTest = SupabaseConfig.supabaseURL.contains("YOUR_PROJECT") == false
        await addTestResult(
            name: "URL Configuration",
            success: urlTest,
            message: urlTest ? "Supabase URL is configured" : "Supabase URL not configured (still has placeholder)"
        )
        
        // Test 3: Check API Key
        let keyTest = SupabaseConfig.supabaseAnonKey.contains("YOUR_ANON_KEY") == false
        await addTestResult(
            name: "API Key Configuration",
            success: keyTest,
            message: keyTest ? "API Key is configured" : "API Key not configured (still has placeholder)"
        )
        
        // Test 4: Try to get auth session (will fail if not authenticated, but connection should work)
        do {
            let session = try await supabase.auth.session
            // session is non-optional, so we check if it has a valid user ID
            let hasValidSession = !session.user.id.uuidString.isEmpty
            await addTestResult(
                name: "Auth Connection",
                success: true,
                message: hasValidSession ? "Connected to Supabase Auth (session exists)" : "Connected to Supabase Auth (no active session)"
            )
        } catch {
            await addTestResult(
                name: "Auth Connection",
                success: false,
                message: "Auth connection failed: \(error.localizedDescription)"
            )
        }
        
        // Test 5: Try a simple database query (test if tables exist)
        do {
            // Try to query profiles table (will fail if table doesn't exist, but connection should work)
            let _: [String] = try await supabase
                .from("profiles")
                .select("user_id")
                .limit(1)
                .execute()
                .value
            
            await addTestResult(
                name: "Database Connection",
                success: true,
                message: "Successfully connected to database (profiles table accessible)"
            )
        } catch {
            let errorMsg = error.localizedDescription
            if errorMsg.contains("relation") && errorMsg.contains("does not exist") {
                await addTestResult(
                    name: "Database Connection",
                    success: true,
                    message: "Connected to database, but 'profiles' table doesn't exist yet (this is OK - you need to create tables)"
                )
            } else {
                await addTestResult(
                    name: "Database Connection",
                    success: false,
                    message: "Database connection failed: \(errorMsg)"
                )
            }
        }
        
        // Determine overall status
        let allTestsPassed = testResults.allSatisfy { $0.success }
        connectionStatus = allTestsPassed ? .connected : .failed
        
        if !allTestsPassed {
            errorMessage = "Some tests failed. Check individual test results."
        }
    }
    
    private func addTestResult(name: String, success: Bool, message: String) async {
        let result = TestResult(
            testName: name,
            success: success,
            message: message,
            timestamp: Date()
        )
        testResults.append(result)
        
        // Small delay for UI updates
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }
}

#else
// Mock implementation when Supabase is not available
import Combine // Required for @Published and ObservableObject

@MainActor
class SupabaseConnectionTest: ObservableObject {
    @Published var connectionStatus: ConnectionStatus = .notStarted
    @Published var errorMessage: String?
    @Published var testResults: [TestResult] = []
    
    enum ConnectionStatus {
        case notStarted
        case testing
        case connected
        case failed
    }
    
    struct TestResult {
        let testName: String
        let success: Bool
        let message: String
        let timestamp: Date
    }
    
    func testConnection() async {
        connectionStatus = .testing
        errorMessage = "Supabase Swift package is not installed. Please add it via Swift Package Manager."
        
        testResults = [
            TestResult(
                testName: "Supabase Package",
                success: false,
                message: "Supabase Swift package not found. Add it via: File → Add Package Dependencies → https://github.com/supabase/supabase-swift",
                timestamp: Date()
            )
        ]
        
        connectionStatus = .failed
    }
}
#endif

