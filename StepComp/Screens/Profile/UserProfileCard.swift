//
//  UserProfileCard.swift
//  FitComp
//
//  Modern user profile card with gradient glow effect
//

import SwiftUI
#if canImport(Supabase)
import Supabase
#endif

struct UserProfileCard: View {
    let userId: String
    let currentUserId: String
    @Binding var isPresented: Bool
    
    @State private var profile: UserProfileInfo?
    @State private var isFriend: Bool = false
    @State private var isLoading = true
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    
    var body: some View {
        ZStack {
            // Backdrop blur overlay
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .blur(radius: 20)
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                }
            
            // Card content
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: FitCompColors.primary))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let profile = profile {
                    profileContent(profile: profile)
                } else {
                    errorContent
                }
            }
            .frame(width: 340)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.3), radius: 40, x: 0, y: 20)
            )
            .cornerRadius(24)
        }
        .transition(.asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .scale(scale: 0.95).combined(with: .opacity)
        ))
        .task {
            await loadProfile()
        }
    }
    
    @ViewBuilder
    private func profileContent(profile: UserProfileInfo) -> some View {
        VStack(spacing: 0) {
            // Close button
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                .padding(16)
            }
            
            // Avatar with gradient glow
            ZStack {
                // Gradient glow background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                FitCompColors.primary.opacity(0.8),
                                Color.orange.opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: 20)
                    .frame(width: 120, height: 120)
                
                // Avatar
                AvatarView(
                    displayName: profile.displayName,
                    avatarURL: profile.avatarUrl,
                    size: 112
                )
                .overlay(
                    Circle()
                        .stroke(Color(.systemBackground), lineWidth: 4)
                )
                
                // Online status indicator
                Circle()
                    .fill(Color.green)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color(.systemBackground), lineWidth: 3)
                    )
                    .offset(x: 40, y: 40)
            }
            .padding(.bottom, 16)
            
            // Name and Username
            VStack(spacing: 4) {
                Text(profile.displayName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                if let username = profile.username {
                    Text("@\(username)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 32)
            
            // Stats Grid
            HStack(spacing: 12) {
                // Total Steps Card
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "figure.walk")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
                    
                    Text(formatNumber(profile.totalSteps ?? 0))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("TOTAL STEPS")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(.systemGray5), lineWidth: 1)
                        )
                )
                
                // Daily Goal Card
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(FitCompColors.primary.opacity(0.2))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "flag.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.8, green: 0.7, blue: 0.0))
                    }
                    
                    Text(formatNumber(profile.dailyStepGoal ?? 10000))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("DAILY GOAL")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(.systemGray5), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            
            // Action buttons
            if userId != currentUserId {
                actionButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
        }
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        if isProcessing {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: FitCompColors.primary))
                .frame(height: 50)
        } else if isFriend {
            Button(action: { 
                Task { await unfollowUser() }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "person.fill.badge.minus")
                        .font(.system(size: 16))
                    Text("Unfollow \(profile?.displayName.components(separatedBy: " ").first ?? "User")")
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.2), lineWidth: 1)
                        )
                )
                .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        } else {
            Button(action: {
                Task { await sendFriendRequest() }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "person.fill.badge.plus")
                        .font(.system(size: 16))
                    Text("Add Friend")
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(FitCompColors.primary)
                .foregroundColor(.black)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
    }
    
    @ViewBuilder
    private var errorContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Unable to Load Profile")
                .font(.system(size: 18, weight: .bold))
            
            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: { isPresented = false }) {
                Text("Close")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(FitCompColors.primary)
                    .cornerRadius(12)
            }
        }
        .padding(32)
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            let thousands = Double(number) / 1000.0
            return String(format: "%.0fk", thousands)
        }
        return "\(number)"
    }
    
    // MARK: - Data Loading
    
    private func loadProfile() async {
        isLoading = true
        
        #if canImport(Supabase)
        do {
            let response: UserProfileInfo = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            profile = response
            
            // Check if already friends
            await checkFriendshipStatus()
            
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
        }
        #endif
        
        isLoading = false
    }
    
    private func checkFriendshipStatus() async {
        #if canImport(Supabase)
        do {
            struct FriendshipRecord: Codable {
                let id: String
                let status: String
            }
            
            let friendships: [FriendshipRecord] = try await supabase
                .from("friendships")
                .select("id,status")
                .or("requester_id.eq.\(currentUserId),addressee_id.eq.\(currentUserId)")
                .or("requester_id.eq.\(userId),addressee_id.eq.\(userId)")
                .eq("status", value: "accepted")
                .execute()
                .value
            
            isFriend = !friendships.isEmpty
            
        } catch {
            print("Error checking friendship: \(error.localizedDescription)")
        }
        #endif
    }
    
    private func sendFriendRequest() async {
        isProcessing = true
        
        #if canImport(Supabase)
        do {
            struct FriendRequest: Encodable {
                let requester_id: String
                let addressee_id: String
                let status: String
            }
            
            let request = FriendRequest(
                requester_id: currentUserId,
                addressee_id: userId,
                status: "pending"
            )
            
            // Insert and get the friendship ID
            struct Friendship: Codable {
                let id: String
                let requester_id: String
                let addressee_id: String
                let status: String
            }
            
            let friendships: [Friendship] = try await supabase
                .from("friendships")
                .insert(request)
                .select()
                .execute()
                .value
            
            guard let friendship = friendships.first else {
                throw NSError(domain: "Friendship", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create friendship"])
            }
            
            // Get requester's (sender's) username for the notification
            // Note: Notification creation is non-blocking - if it fails, we log but don't throw
            // since the friend request was successfully created
            do {
                let profiles: [UserProfile] = try await supabase
                    .from("profiles")
                    .select("username, display_name")
                    .eq("id", value: currentUserId)
                    .execute()
                    .value
                
                let requesterUsername = profiles.first?.displayName ?? profiles.first?.username ?? "Someone"
                
                // Create notification for the recipient
                try await ChallengeNotificationService.shared.createNotification(
                    userId: userId,
                    type: .friendRequest,
                    title: "New Friend Request",
                    message: "\(requesterUsername) sent you a friend request",
                    relatedId: friendship.id
                )
            } catch {
                // Log the error but don't throw - the friend request was successfully created
                print("⚠️ Friend request sent successfully, but failed to create notification: \(error.localizedDescription)")
            }
            
            isFriend = true
            
        } catch {
            errorMessage = "Failed to send friend request: \(error.localizedDescription)"
        }
        #endif
        
        isProcessing = false
    }
    
    private func unfollowUser() async {
        isProcessing = true
        
        #if canImport(Supabase)
        do {
            struct FriendshipRecord: Codable {
                let id: String
                let requester_id: String
                let addressee_id: String
            }
            
            let friendships: [FriendshipRecord] = try await supabase
                .from("friendships")
                .select("id,requester_id,addressee_id")
                .or("requester_id.eq.\(currentUserId),addressee_id.eq.\(currentUserId)")
                .or("requester_id.eq.\(userId),addressee_id.eq.\(userId)")
                .execute()
                .value
            
            if let friendship = friendships.first {
                try await supabase
                    .from("friendships")
                    .delete()
                    .eq("id", value: friendship.id)
                    .execute()
                
                isFriend = false
            }
            
        } catch {
            errorMessage = "Failed to unfollow: \(error.localizedDescription)"
        }
        #endif
        
        isProcessing = false
    }
}

// MARK: - Supporting Views

struct UserProfileInfo: Codable {
    let id: String
    let displayName: String
    let username: String?
    let avatarUrl: String?
    let totalSteps: Int?
    let dailyStepGoal: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case username
        case avatarUrl = "avatar_url"
        case totalSteps = "total_steps"
        case dailyStepGoal = "daily_step_goal"
    }
}
