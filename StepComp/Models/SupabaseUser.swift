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
    let id: String // user_id from profiles table
    var username: String // Unique username (e.g., @username)
    var firstName: String?
    var lastName: String?
    var avatar: String?
    var isPremium: Bool
    var height: Int? // Height in cm
    var weight: Int? // Weight in kg
    
    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case avatar
        case isPremium = "is_premium"
        case height
        case weight
    }
}

