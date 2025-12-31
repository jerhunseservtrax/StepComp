//
//  FriendsService.swift
//  StepComp
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

    func searchPublicProfiles(query: String, myUserId: String) async throws -> [Profile] {
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

        let res: [Profile] = try await builder.limit(30).execute().value
        return res
        #else
        return []
        #endif
    }

    // MARK: - Friendships

    func listMyFriendships(myUserId: String) async throws -> [Friendship] {
        #if canImport(Supabase)
        let res: [Friendship] = try await supabase
            .from("friendships")
            .select("id,requester_id,addressee_id,status")
            .or("requester_id.eq.\(myUserId),addressee_id.eq.\(myUserId)")
            .execute()
            .value
        return res
        #else
        return []
        #endif
    }

    func sendFriendRequest(to targetUserId: String, myUserId: String) async throws -> String? {
        #if canImport(Supabase)
        // Insert and return the friendship ID
        let response: [Friendship] = try await supabase
            .from("friendships")
            .insert([
                "requester_id": myUserId,
                "addressee_id": targetUserId,
                "status": "pending"
            ])
            .select("id")
            .execute()
            .value
        return response.first?.id
        #else
        return nil
        #endif
    }

    func acceptRequest(friendshipId: String) async throws {
        #if canImport(Supabase)
        _ = try await supabase
            .from("friendships")
            .update(["status": "accepted"])
            .eq("id", value: friendshipId)
            .execute()
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
