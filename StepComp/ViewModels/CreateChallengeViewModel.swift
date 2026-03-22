//
//  CreateChallengeViewModel.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation
import SwiftUI
import Combine
#if canImport(Supabase)
import Supabase
import PostgREST
#endif

// MARK: - Challenge Rule Model

enum ChallengeRule: String, CaseIterable, Identifiable, Codable {
    case verifiedSourcesOnly = "verified_sources"
    case dailyStepCap15k = "daily_cap_15k"
    case dailyStepCap25k = "daily_cap_25k"
    case dailyStepCap50k = "daily_cap_50k"
    case syncEvery24h = "sync_24h"
    case syncEvery3Days = "sync_3d"
    case syncWeekly = "sync_weekly"
    case noManualEntry = "no_manual"
    case wearablesOnly = "wearables_only"
    case mustSyncDaily = "must_sync_daily"
    case fairPlay = "fair_play"
    case activeParticipation = "active_participation"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .verifiedSourcesOnly: return "Verified Sources Only"
        case .dailyStepCap15k: return "Daily Cap: 15k Steps"
        case .dailyStepCap25k: return "Daily Cap: 25k Steps"
        case .dailyStepCap50k: return "Daily Cap: 50k Steps"
        case .syncEvery24h: return "Sync Every 24 Hours"
        case .syncEvery3Days: return "Sync Every 3 Days"
        case .syncWeekly: return "Weekly Sync OK"
        case .noManualEntry: return "No Manual Entry"
        case .wearablesOnly: return "Wearables Only"
        case .mustSyncDaily: return "Must Sync Daily"
        case .fairPlay: return "Fair Play Mode"
        case .activeParticipation: return "Active Participation Required"
        }
    }
    
    var subtitle: String {
        switch self {
        case .verifiedSourcesOnly: return "Only steps from verified health apps count"
        case .dailyStepCap15k: return "Maximum 15,000 steps per day count towards total"
        case .dailyStepCap25k: return "Maximum 25,000 steps per day count towards total"
        case .dailyStepCap50k: return "Maximum 50,000 steps per day count towards total"
        case .syncEvery24h: return "Participants must sync data within 24 hours"
        case .syncEvery3Days: return "Participants must sync at least every 3 days"
        case .syncWeekly: return "Participants can sync once per week"
        case .noManualEntry: return "Manually entered steps are not allowed"
        case .wearablesOnly: return "Only wearable device data is accepted"
        case .mustSyncDaily: return "Data must be synced every day to count"
        case .fairPlay: return "Anti-cheat measures enabled"
        case .activeParticipation: return "Inactive users may be removed"
        }
    }
    
    var icon: String {
        switch self {
        case .verifiedSourcesOnly: return "checkmark.shield.fill"
        case .dailyStepCap15k, .dailyStepCap25k, .dailyStepCap50k: return "gauge.medium"
        case .syncEvery24h, .syncEvery3Days, .syncWeekly: return "arrow.triangle.2.circlepath"
        case .noManualEntry: return "hand.raised.slash.fill"
        case .wearablesOnly: return "applewatch"
        case .mustSyncDaily: return "clock.badge.checkmark.fill"
        case .fairPlay: return "shield.checkered"
        case .activeParticipation: return "figure.walk"
        }
    }
    
    var color: Color {
        switch self {
        case .verifiedSourcesOnly: return .blue
        case .dailyStepCap15k: return .green
        case .dailyStepCap25k: return .orange
        case .dailyStepCap50k: return .red
        case .syncEvery24h: return .purple
        case .syncEvery3Days: return .cyan
        case .syncWeekly: return .teal
        case .noManualEntry: return .pink
        case .wearablesOnly: return .indigo
        case .mustSyncDaily: return .mint
        case .fairPlay: return .yellow
        case .activeParticipation: return .brown
        }
    }
    
    // Group rules by category for better organization
    static var dataSourceRules: [ChallengeRule] {
        [.verifiedSourcesOnly, .wearablesOnly, .noManualEntry]
    }
    
    static var dailyCapRules: [ChallengeRule] {
        [.dailyStepCap15k, .dailyStepCap25k, .dailyStepCap50k]
    }
    
    static var syncRules: [ChallengeRule] {
        [.syncEvery24h, .syncEvery3Days, .syncWeekly, .mustSyncDaily]
    }
    
    static var participationRules: [ChallengeRule] {
        [.fairPlay, .activeParticipation]
    }
}

@MainActor
final class CreateChallengeViewModel: ObservableObject {
    @Published var name: String = "Morning Sprinters"
    @Published var description: String = ""
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
    @Published var targetSteps: Int = 10000
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var createdChallenge: Challenge?
    
    // New properties for the redesigned UI
    @Published var selectedDuration: ChallengeDuration = .threeDays
    @Published var customDays: Int = 7 // Default custom days
    @Published var startDateMode: StartDateMode = .today
    @Published var isPrivate: Bool = true
    @Published var isFriendsOnly: Bool = false // Only friends can join
    @Published var selectedParticipants: [String] = [] // User IDs
    @Published var selectedCategory: Challenge.ChallengeCategory? = nil // Category for public challenges
    @Published var selectedRules: Set<ChallengeRule> = [] // Selected rules for the challenge
    @Published var challengeImageData: Data? = nil // Image data for challenge background
    @Published var challengeImageURL: String? = nil // URL after upload to storage
    
    private var challengeService: ChallengeService
    private let creatorId: String
    
    enum ChallengeDuration: Int, CaseIterable, Hashable {
        case oneDay = 1
        case threeDays = 3
        case sevenDays = 7
        case thirtyDays = 30
        case custom
        
        var displayName: String {
            switch self {
            case .oneDay: return "24 Hours"
            case .threeDays: return "3 Days"
            case .sevenDays: return "7 Days"
            case .thirtyDays: return "30 Days"
            case .custom: return "Custom"
            }
        }
    }
    
    enum StartDateMode {
        case today
        case pickDate
    }
    
    init(challengeService: ChallengeService, creatorId: String) {
        self.challengeService = challengeService
        self.creatorId = creatorId
    }
    
    func updateService(_ service: ChallengeService) {
        self.challengeService = service
    }
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        startDate < endDate &&
        targetSteps > 0
    }
    
    var durationInDays: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return max(components.day ?? 0, 1)
    }
    
    func updateDuration(_ duration: ChallengeDuration) {
        selectedDuration = duration
        if duration != .custom {
            let days = duration.rawValue
            endDate = Calendar.current.date(byAdding: .day, value: days, to: startDate) ?? startDate
        } else {
            // For custom, use the customDays value
            endDate = Calendar.current.date(byAdding: .day, value: customDays, to: startDate) ?? startDate
        }
    }
    
    func updateCustomDays(_ days: Int) {
        customDays = max(1, min(days, 365)) // Clamp between 1 and 365 days
        if selectedDuration == .custom {
            endDate = Calendar.current.date(byAdding: .day, value: customDays, to: startDate) ?? startDate
        }
    }
    
    func updateStartDateMode(_ mode: StartDateMode) {
        startDateMode = mode
        if mode == .today {
            startDate = Date()
            updateDuration(selectedDuration) // Recalculate end date
        }
    }
    
    func createChallenge() async {
        guard isValid else {
            errorMessage = "Please fill in all fields correctly"
            print("⚠️ Challenge creation failed: Invalid form data")
            return
        }
        
        // Validate creator ID exists
        guard !creatorId.isEmpty else {
            errorMessage = "Unable to create challenge: User not authenticated"
            print("❌ Challenge creation failed: creatorId is empty")
            print("   This usually means currentUser is nil or user is not properly signed in")
            return
        }
        
        // Validate category is selected for public challenges
        if !isPrivate && selectedCategory == nil {
            errorMessage = "Please select a category for public challenges"
            print("⚠️ Challenge creation failed: No category selected for public challenge")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        print("🚀 Starting challenge creation...")
        print("   Name: \(name)")
        print("   Is Private: \(isPrivate)")
        print("   Is Public: \(!isPrivate)")
        print("   Category: \(selectedCategory?.displayName ?? "None")")
        print("   Creator ID: \(creatorId)")
        
        do {
            // Upload challenge image if provided
            var imageUrl: String? = nil
            if let imageData = challengeImageData {
                print("📸 Uploading challenge image...")
                imageUrl = try await uploadChallengeImage(imageData: imageData)
                print("✅ Challenge image uploaded: \(imageUrl ?? "nil")")
            }
            
            // Include creator and selected participants
            var participantIds = [creatorId]
            participantIds.append(contentsOf: selectedParticipants)
            
            let challenge = Challenge(
                name: name,
                description: description,
                startDate: startDate,
                endDate: endDate,
                targetSteps: targetSteps,
                creatorId: creatorId,
                participantIds: participantIds,
                category: !isPrivate ? selectedCategory : nil, // Only set category for public challenges
                imageUrl: imageUrl
            )
            
            print("📝 Challenge object created: \(challenge.id)")
            
            // isPublic = !isPrivate (if isPrivate is true, then isPublic is false)
            try await challengeService.createChallenge(challenge, isPublic: !isPrivate)
            
            print("✅ Challenge created successfully in database")
            createdChallenge = challenge
        } catch {
            let errorMsg = error.localizedDescription
            print("❌ Challenge creation failed: \(errorMsg)")
            errorMessage = errorMsg
            // Also print the full error for debugging
            #if canImport(Supabase)
            if let supabaseError = error as? PostgrestError {
                print("   Supabase error code: \(supabaseError.code ?? "unknown")")
                print("   Supabase error message: \(supabaseError.message)")
                print("   Supabase error hint: \(supabaseError.hint ?? "none")")
            }
            #endif
        }
        
        isLoading = false
    }
    
    // MARK: - Image Upload
    
    private func uploadChallengeImage(imageData: Data) async throws -> String? {
        #if canImport(Supabase)
        let fileName = "\(UUID().uuidString).jpg"
        let filePath = "challenge-images/\(fileName)"
        
        print("📤 Uploading image to path: \(filePath)")
        
        // Upload to Supabase Storage
        try await supabase
            .storage
            .from("challenges")
            .upload(
                filePath,
                data: imageData,
                options: FileOptions(contentType: "image/jpeg", upsert: false)
            )
        
        // Get public URL
        let publicURL = try supabase
            .storage
            .from("challenges")
            .getPublicURL(path: filePath)
        
        print("✅ Image uploaded successfully: \(publicURL)")
        return publicURL.absoluteString
        #else
        return nil
        #endif
    }
    
    func reset() {
        name = ""
        description = ""
        startDate = Date()
        endDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        targetSteps = 10000
        selectedDuration = .threeDays
        startDateMode = .today
        isPrivate = true
        selectedParticipants = []
        selectedCategory = nil
        selectedRules = []
        challengeImageData = nil
        challengeImageURL = nil
        errorMessage = nil
        createdChallenge = nil
    }
    
    // Helper to get selected rules as array for storage
    var selectedRulesArray: [String] {
        selectedRules.map { $0.rawValue }
    }
}

