//
//  SupabaseUser.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation

// MARK: - Supabase Auth User (from Supabase SDK)
// This represents the authenticated user from Supabase Auth

struct SupabaseAuthUser: Codable {
    let id: String
    let email: String?
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
    }
}

// MARK: - Database Profile (from Supabase Database)
// This represents the user profile stored in the profiles table

struct UserProfile: Codable, Identifiable {
    let id: String // id from profiles table (references auth.users(id))
    var username: String // Unique username (e.g., @username)
    var firstName: String?
    var lastName: String?
    var avatar: String?
    var avatarUrl: String? // New field for avatar_url
    var displayName: String? // New field for display_name
    var isPremium: Bool
    var height: Int? // Height in cm
    var weight: Int? // Weight in kg
    var email: String? // Email from profiles table
    var publicProfile: Bool // New field for public_profile
    var totalSteps: Int? // Total steps since joining the app
    var dailyStepGoal: Int? // Daily step goal
    
    enum CodingKeys: String, CodingKey {
        case id // Now uses 'id' instead of 'user_id' to match new schema
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case avatar
        case avatarUrl = "avatar_url"
        case displayName = "display_name"
        case isPremium = "is_premium"
        case height
        case weight
        case email
        case publicProfile = "public_profile"
        case totalSteps = "total_steps"
        case dailyStepGoal = "daily_step_goal"
    }
    
    // Custom initializer with default values
    init(
        id: String,
        username: String,
        firstName: String? = nil,
        lastName: String? = nil,
        avatar: String? = nil,
        avatarUrl: String? = nil,
        displayName: String? = nil,
        isPremium: Bool = false,
        height: Int? = nil,
        weight: Int? = nil,
        email: String? = nil,
        publicProfile: Bool = false,
        totalSteps: Int? = nil,
        dailyStepGoal: Int? = nil
    ) {
        self.id = id
        self.username = username
        self.firstName = firstName
        self.lastName = lastName
        self.avatar = avatar
        self.avatarUrl = avatarUrl
        self.displayName = displayName
        self.isPremium = isPremium
        self.height = height
        self.weight = weight
        self.email = email
        self.publicProfile = publicProfile
        self.totalSteps = totalSteps
        self.dailyStepGoal = dailyStepGoal
    }
}

