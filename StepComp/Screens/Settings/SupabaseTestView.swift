//
//  SupabaseTestView.swift
//  StepComp
//
//  Test view for Supabase connection
//

import SwiftUI

struct SupabaseTestView: View {
    @StateObject private var testService = SupabaseConnectionTest()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Status Header
                    statusHeader
                    
                    // Test Button
                    Button(action: {
                        Task {
                            await testService.testConnection()
                        }
                    }) {
                        HStack {
                            if testService.connectionStatus == .testing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text(testService.connectionStatus == .testing ? "Testing..." : "Test Connection")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            testService.connectionStatus == .connected ? Color.green :
                            testService.connectionStatus == .failed ? Color.red :
                            Color.blue
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(testService.connectionStatus == .testing)
                    .padding(.horizontal)
                    
                    // Test Results
                    if !testService.testResults.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Test Results")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(Array(testService.testResults.enumerated()), id: \.offset) { index, result in
                                TestResultRow(result: result)
                            }
                        }
                        .padding(.top)
                    }
                    
                    // Error Message
                    if let errorMessage = testService.errorMessage {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Error")
                                    .font(.headline)
                            }
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Configuration Info
                    configurationInfo
                }
                .padding(.vertical)
            }
            .navigationTitle("Supabase Test")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var statusHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        testService.connectionStatus == .connected ? Color.green.opacity(0.2) :
                        testService.connectionStatus == .failed ? Color.red.opacity(0.2) :
                        testService.connectionStatus == .testing ? Color.blue.opacity(0.2) :
                        Color.gray.opacity(0.2)
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: statusIcon)
                    .font(.system(size: 40))
                    .foregroundColor(statusColor)
            }
            
            Text(statusText)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(statusSubtext)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var statusIcon: String {
        switch testService.connectionStatus {
        case .connected:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        case .testing:
            return "arrow.triangle.2.circlepath"
        case .notStarted:
            return "questionmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch testService.connectionStatus {
        case .connected:
            return .green
        case .failed:
            return .red
        case .testing:
            return .blue
        case .notStarted:
            return .gray
        }
    }
    
    private var statusText: String {
        switch testService.connectionStatus {
        case .connected:
            return "Connected"
        case .failed:
            return "Connection Failed"
        case .testing:
            return "Testing..."
        case .notStarted:
            return "Not Tested"
        }
    }
    
    private var statusSubtext: String {
        switch testService.connectionStatus {
        case .connected:
            return "Your Supabase connection is working correctly"
        case .failed:
            return "Some tests failed. Check the results below."
        case .testing:
            return "Testing your Supabase connection..."
        case .notStarted:
            return "Tap 'Test Connection' to verify your setup"
        }
    }
    
    private var configurationInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Configuration")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "Supabase URL", value: SupabaseConfig.supabaseURL)
                InfoRow(label: "API Key", value: String(SupabaseConfig.supabaseAnonKey.prefix(20)) + "...")
                InfoRow(
                    label: "Supabase Enabled",
                    value: "Check AuthService.swift (useSupabase flag)"
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

struct TestResultRow: View {
    let result: SupabaseConnectionTest.TestResult
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(result.success ? .green : .red)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(result.testName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(result.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(result.success ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .textSelection(.enabled)
        }
    }
}

#Preview {
    SupabaseTestView()
}

