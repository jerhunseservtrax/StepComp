//
//  FriendsService.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation
import Combine
#if canImport(Supabase)
import Supabase
#endif

@MainActor
final class FriendsService: ObservableObject {
    // MARK: - Profiles

    func setPublicProfile(_ isPublic: Bool, myUserId: String) async throws {
        #if canImport(Supabase)
        _ = try await supabase
            .from("profiles")
            .update(["public_profile": isPublic])
            .eq("id", value: myUserId)
            .execute()
        #endif
    }

    func searchPublicProfiles(query: String, myUserId: String, limit: Int = 30, offset: Int = 0) async throws -> [Profile] {
        #if canImport(Supabase)
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        var builder = supabase
            .from("profiles")
            .select("id,username,display_name,avatar_url,public_profile")
            .eq("public_profile", value: true)
            .neq("id", value: myUserId)

        if !q.isEmpty {
            builder = builder.ilike("username", pattern: "%\(q)%")
        }

        let res: [Profile] = try await RetryUtility.withExponentialBackoff {
            try await builder
                .range(from: offset, to: offset + max(limit - 1, 0))
                .execute()
                .value
        }
        return res
        #else
        return []
        #endif
    }

    // MARK: - Friendships

    func listMyFriendships(myUserId: String, limit: Int = 100, offset: Int = 0) async throws -> [Friendship] {
        #if canImport(Supabase)
        let res: [Friendship] = try await RetryUtility.withExponentialBackoff {
            try await supabase
                .from("friendships")
                .select("id,requester_id,addressee_id,status")
                .or("requester_id.eq.\(myUserId),addressee_id.eq.\(myUserId)")
                .range(from: offset, to: offset + max(limit - 1, 0))
                .execute()
                .value
        }
        return res
        #else
        return []
        #endif
    }

    func sendFriendRequest(to targetUserId: String, myUserId: String) async throws -> String? {
        #if canImport(Supabase)
        // Insert and return the friendship ID
        // We need to select all fields to properly decode the Friendship model
        let response: [Friendship] = try await supabase
            .from("friendships")
            .insert([
                "requester_id": myUserId,
                "addressee_id": targetUserId,
                "status": "pending"
            ])
            .select() // Select all fields, not just id
            .execute()
            .value
        
        guard let friendship = response.first else {
            return nil
        }
        
        // friendship.id is a String (not optional), so we can access it directly
        let friendshipId = friendship.id
        
        // Get requester's (sender's) username for the notification
        // Note: Notification creation is non-blocking - if it fails, we log but still return
        // the friendship ID since the request was successfully created
        do {
            let profiles: [UserProfile] = try await supabase
                .from("profiles")
                .select("username, display_name")
                .eq("id", value: myUserId)
                .execute()
                .value
            
            let requesterUsername = profiles.first?.displayName ?? profiles.first?.username ?? "Someone"
            
            // Create notification for the recipient (targetUserId)
            try await ChallengeNotificationService.shared.createNotification(
                userId: targetUserId,
                type: .friendRequest,
                title: "New Friend Request",
                message: "\(requesterUsername) sent you a friend request",
                relatedId: friendshipId
            )
            
            print("✅ Friend request sent to \(targetUserId) and notification created")
        } catch {
            // Log the error but don't throw - the friend request was successfully created
            print("⚠️ Friend request sent successfully, but failed to create notification: \(error.localizedDescription)")
        }
        
        return friendshipId
        #else
        return nil
        #endif
    }

    func acceptRequest(friendshipId: String) async throws {
        #if canImport(Supabase)
        // First, get the friendship details to find the requester
        let friendships: [Friendship] = try await supabase
            .from("friendships")
            .select()
            .eq("id", value: friendshipId)
            .execute()
            .value
        
        guard let friendship = friendships.first else {
            throw NSError(domain: "Friendship", code: 404, userInfo: [NSLocalizedDescriptionKey: "Friendship not found"])
        }
        
        // Update the friendship status
        _ = try await supabase
            .from("friendships")
            .update(["status": "accepted"])
            .eq("id", value: friendshipId)
            .execute()
        
        // The requester is the person who sent the request (needs notification)
        // The addressee is the person receiving/accepting the request (current user)
        let requesterId = friendship.requesterId
        let accepterId = friendship.addresseeId
        
        // Get accepter's (current user's) username for the notification
        // Note: Notification creation is non-blocking - if it fails, we log but don't throw
        // since the friendship acceptance already succeeded
        do {
            let profiles: [UserProfile] = try await supabase
                .from("profiles")
                .select("username, display_name")
                .eq("id", value: accepterId)
                .execute()
                .value
            
            let accepterUsername = profiles.first?.displayName ?? profiles.first?.username ?? "Someone"
            
            // Send notification to the requester (the person who sent the request)
            try await ChallengeNotificationService.shared.createNotification(
                userId: requesterId,
                type: .friendRequestAccepted,
                title: "Friend Request Accepted! 🎉",
                message: "\(accepterUsername) accepted your friend request",
                relatedId: friendshipId
            )
            
            print("✅ Friend request accepted and notification sent to \(requesterId)")
        } catch {
            // Log the error but don't throw - the friendship acceptance already succeeded
            print("⚠️ Friend request accepted successfully, but failed to create notification: \(error.localizedDescription)")
        }
        #endif
    }

    func removeFriendship(friendshipId: String) async throws {
        #if canImport(Supabase)
        _ = try await supabase
            .from("friendships")
            .delete()
            .eq("id", value: friendshipId)
            .execute()
        #endif
    }

    // MARK: - Invites (RPC)

    func createInviteRPC(expiresInHours: Int = 168) async throws -> InviteCreateResponse {
        #if canImport(Supabase)
        let arr: [InviteCreateResponse] = try await supabase
            .rpc("create_friend_invite", params: ["expires_in_hours": expiresInHours])
            .execute()
            .value
        guard let first = arr.first else {
            throw NSError(domain: "Invite", code: 0, userInfo: [NSLocalizedDescriptionKey: "No invite returned"])
        }
        return first
        #else
        throw NSError(domain: "Invite", code: 0, userInfo: [NSLocalizedDescriptionKey: "Supabase not available"])
        #endif
    }

    func consumeInviteRPC(token: String) async throws -> InviteConsumeResponse {
        #if canImport(Supabase)
        let arr: [InviteConsumeResponse] = try await supabase
            .rpc("consume_friend_invite", params: ["invite_token": token])
            .execute()
            .value
        guard let first = arr.first else {
            throw NSError(domain: "Invite", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid invite token"])
        }
        return first
        #else
        throw NSError(domain: "Invite", code: 0, userInfo: [NSLocalizedDescriptionKey: "Supabase not available"])
        #endif
    }
}

// MARK: - JSONDecoder helper
private extension JSONDecoder {
    static var iso8601: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}
