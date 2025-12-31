//
//  HealthKitTestView.swift
//  StepComp
//
//  Test view for HealthKit connection
//

import SwiftUI
import Combine
#if os(iOS)
import HealthKit
#endif

struct HealthKitTestView: View {
    @EnvironmentObject var healthKitService: HealthKitService
    @State private var todaySteps: Int = 0
    @State private var isLoadingSteps: Bool = false
    @State private var testResults: [TestResult] = []
    @State private var errorMessage: String?
    
    struct TestResult: Identifiable {
        let id = UUID()
        let testName: String
        let success: Bool
        let message: String
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Status Header
                    statusHeader
                    
                    // Authorization Section
                    authorizationSection
                    
                    // Test Steps Reading
                    stepsReadingSection
                    
                    // Test Results
                    if !testResults.isEmpty {
                        testResultsSection
                    }
                    
                    // Error Message
                    if let errorMessage = errorMessage {
                        errorSection(message: errorMessage)
                    }
                    
                    // Configuration Info
                    configurationInfo
                }
                .padding(.vertical)
            }
            .navigationTitle("HealthKit Test")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                runInitialTests()
            }
        }
    }
    
    private var statusHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(statusBackgroundColor)
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
    
    private var authorizationSection: some View {
        VStack(spacing: 16) {
            Text("Authorization")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Current Status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Status")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(authorizationStatusText)
                        .font(.headline)
                        .foregroundColor(authorizationStatusColor)
                }
                
                Spacer()
                
                if !healthKitService.isAuthorized {
                    Button(action: {
                        Task {
                            await requestAuthorization()
                        }
                    }) {
                        HStack {
                            Image(systemName: "lock.open.fill")
                            Text("Request Access")
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Check Status Button
            Button(action: {
                healthKitService.checkAuthorizationStatus()
                runInitialTests()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh Status")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }
    
    private var stepsReadingSection: some View {
        VStack(spacing: 16) {
            Text("Step Reading Test")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if healthKitService.isAuthorized {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Today's Steps")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if isLoadingSteps {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Text("\(todaySteps.formatted()) steps")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Button(action: {
                        Task {
                            await testStepsReading()
                        }
                    }) {
                        HStack {
                            if isLoadingSteps {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "figure.walk")
                            }
                            Text(isLoadingSteps ? "Reading..." : "Read Today's Steps")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoadingSteps)
                }
            } else {
                Text("Authorize HealthKit access to test step reading")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }
    
    private var testResultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Test Results")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(testResults) { result in
                HealthKitTestResultRow(result: result)
            }
        }
    }
    
    private func errorSection(message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Error")
                    .font(.headline)
            }
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var configurationInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Configuration")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(
                    label: "HealthKit Available",
                    value: healthKitService.isHealthKitAvailable ? "Yes" : "No"
                )
                InfoRow(
                    label: "Authorization Status",
                    value: authorizationStatusText
                )
                InfoRow(
                    label: "Is Authorized",
                    value: healthKitService.isAuthorized ? "Yes" : "No"
                )
                #if os(iOS)
                InfoRow(
                    label: "Device Supports HealthKit",
                    value: HKHealthStore.isHealthDataAvailable() ? "Yes" : "No"
                )
                #endif
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Status Helpers
    
    private var statusIcon: String {
        if !healthKitService.isHealthKitAvailable {
            return "xmark.circle.fill"
        } else if healthKitService.isAuthorized {
            return "checkmark.circle.fill"
        } else {
            return "questionmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        if !healthKitService.isHealthKitAvailable {
            return .red
        } else if healthKitService.isAuthorized {
            return .green
        } else {
            return .orange
        }
    }
    
    private var statusBackgroundColor: Color {
        if !healthKitService.isHealthKitAvailable {
            return Color.red.opacity(0.2)
        } else if healthKitService.isAuthorized {
            return Color.green.opacity(0.2)
        } else {
            return Color.orange.opacity(0.2)
        }
    }
    
    private var statusText: String {
        if !healthKitService.isHealthKitAvailable {
            return "Not Available"
        } else if healthKitService.isAuthorized {
            return "Authorized"
        } else {
            return "Not Authorized"
        }
    }
    
    private var statusSubtext: String {
        if !healthKitService.isHealthKitAvailable {
            return "HealthKit is not available on this device or entitlement is missing"
        } else if healthKitService.isAuthorized {
            return "HealthKit is authorized and ready to use"
        } else {
            return "Request authorization to access HealthKit data"
        }
    }
    
    private var authorizationStatusText: String {
        #if os(iOS)
        switch healthKitService.authorizationStatus {
        case .notDetermined:
            return "Not Determined"
        case .sharingDenied:
            return "Denied"
        case .sharingAuthorized:
            return "Authorized"
        @unknown default:
            return "Unknown"
        }
        #else
        return "N/A"
        #endif
    }
    
    private var authorizationStatusColor: Color {
        #if os(iOS)
        switch healthKitService.authorizationStatus {
        case .notDetermined:
            return .orange
        case .sharingDenied:
            return .red
        case .sharingAuthorized:
            return .green
        @unknown default:
            return .gray
        }
        #else
        return .gray
        #endif
    }
    
    // MARK: - Actions
    
    private func runInitialTests() {
        testResults = []
        errorMessage = nil
        
        // Test 1: HealthKit Availability
        let isAvailable = healthKitService.isHealthKitAvailable
        testResults.append(TestResult(
            testName: "HealthKit Available",
            success: isAvailable,
            message: isAvailable ? "HealthKit is available on this device" : "HealthKit is not available (check entitlements)"
        ))
        
        // Test 2: Authorization Status
        healthKitService.checkAuthorizationStatus()
        let isAuthorized = healthKitService.isAuthorized
        testResults.append(TestResult(
            testName: "Authorization Status",
            success: isAuthorized,
            message: isAuthorized ? "HealthKit is authorized" : "HealthKit authorization required"
        ))
    }
    
    private func requestAuthorization() async {
        errorMessage = nil
        do {
            try await healthKitService.requestAuthorization()
            healthKitService.checkAuthorizationStatus()
            runInitialTests()
            
            // If authorized, automatically test step reading
            if healthKitService.isAuthorized {
                await testStepsReading()
            }
        } catch {
            errorMessage = "Authorization failed: \(error.localizedDescription)"
            runInitialTests()
        }
    }
    
    private func testStepsReading() async {
        isLoadingSteps = true
        errorMessage = nil
        
        do {
            let steps = try await healthKitService.getTodaySteps()
            todaySteps = steps
            
            // Add test result
            testResults.append(TestResult(
                testName: "Read Today's Steps",
                success: true,
                message: "Successfully read \(steps.formatted()) steps for today"
            ))
        } catch {
            errorMessage = "Failed to read steps: \(error.localizedDescription)"
            testResults.append(TestResult(
                testName: "Read Today's Steps",
                success: false,
                message: "Error: \(error.localizedDescription)"
            ))
        }
        
        isLoadingSteps = false
    }
}

struct HealthKitTestResultRow: View {
    let result: HealthKitTestView.TestResult
    
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


