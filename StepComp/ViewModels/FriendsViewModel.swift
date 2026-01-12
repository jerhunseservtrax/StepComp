//
//  FriendsViewModel.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation
import Combine
#if canImport(Supabase)
import Supabase
#endif

// MARK: - Debug Logging Helper
private func debugLog(_ location: String, _ message: String, _ data: [String: Any], _ hypothesisId: String) {
    let logEntry: [String: Any] = [
        "location": location,
        "message": message,
        "data": data,
        "timestamp": Int(Date().timeIntervalSince1970 * 1000),
        "sessionId": "debug-session",
        "runId": "run1",
        "hypothesisId": hypothesisId
    ]
    if let logData = try? JSONSerialization.data(withJSONObject: logEntry),
       let logString = String(data: logData, encoding: .utf8) {
        if let fileHandle = FileHandle(forWritingAtPath: "/Users/jefferyerhunse/GitRepos/StepComp/.cursor/debug.log") {
            fileHandle.seekToEndOfFile()
            fileHandle.write(logString.data(using: .utf8)!)
            fileHandle.write("\n".data(using: .utf8)!)
            fileHandle.closeFile()
        } else {
            try? logString.write(toFile: "/Users/jefferyerhunse/GitRepos/StepComp/.cursor/debug.log", atomically: false, encoding: .utf8)
        }
    }
}

@MainActor
final class FriendsViewModel: ObservableObject {
    enum Tab { case friends, discover }

    @Published var selectedTab: Tab = .friends
    @Published var isEditing: Bool = false
    @Published var selectedProfileUserId: String? = nil // For profile card

    @Published var myProfile: Profile?
    @Published var friendships: [Friendship] = []
    @Published var friendItems: [FriendListItem] = []
    
    // Computed property for pending incoming requests
    var pendingRequests: [FriendListItem] {
        friendItems.filter { $0.isIncomingRequest && $0.status == .pending }
    }

    @Published var discoverQuery: String = ""
    @Published var discoverResults: [Profile] = []

    @Published var errorMessage: String?

    private var service: FriendsService
    private var myUserId: String

    init(service: FriendsService, myUserId: String) {
        self.service = service
        self.myUserId = myUserId
    }
    
    func updateService(service: FriendsService, myUserId: String) {
        self.service = service
        self.myUserId = myUserId
    }

    func load() async {
        do {
            try await refreshFriendships()
            try await refreshDiscover()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshFriendships() async throws {
        friendships = try await service.listMyFriendships(myUserId: myUserId)
        friendItems = try await mapToFriendItems(friendships: friendships)
    }

    func refreshDiscover() async throws {
        // Refresh friendships first to get latest status
        try await refreshFriendships()
        // Then refresh discover results
        let allResults = try await service.searchPublicProfiles(query: discoverQuery, myUserId: myUserId)
        
        // Get IDs of users who are already friends (accepted friendships only)
        let friendIds = Set(friendships.compactMap { friendship -> String? in
            if friendship.status == .accepted {
                return friendship.requesterId == myUserId ? friendship.addresseeId : friendship.requesterId
            }
            return nil
        })
        
        // Filter out users who are already friends
        discoverResults = allResults.filter { !friendIds.contains($0.id) }
    }

    func togglePublicProfile(_ isPublic: Bool) async {
        do {
            try await service.setPublicProfile(isPublic, myUserId: myUserId)
            // Reload profile to reflect change
            if var profile = myProfile {
                profile.publicProfile = isPublic
                myProfile = profile
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Invite Links
    
    func createInviteLink() async -> URL? {
        // Return the TestFlight beta link
        let testFlightURL = "https://testflight.apple.com/join/EpWCKHpe"
        
        guard let url = URL(string: testFlightURL) else {
            errorMessage = "Failed to create TestFlight URL"
            return nil
        }
        
        print("✅ Created TestFlight invite link: \(testFlightURL)")
        return url
    }
    
    func consumeInviteToken(_ token: String) async -> Bool {
        do {
            let result = try await service.consumeInviteRPC(token: token)
            print("✅ Invite consumed! Friend request from \(result.inviterUsername)")
            // Refresh friendships to show the new request
            try await refreshFriendships()
            return true
        } catch {
            errorMessage = "Failed to accept invite: \(error.localizedDescription)"
            print("❌ Error consuming invite: \(error)")
            return false
        }
    }
    
    func sendRequest(to profile: Profile) async {
        do {
            // Check if this is a test account (auto-accept)
            let isTestAccount = isTestAccountId(profile.id)
            
            // Send the friend request and get the friendship ID
            if let friendshipId = try await service.sendFriendRequest(to: profile.id, myUserId: myUserId) {
                if isTestAccount {
                    // For test accounts, immediately accept the request
                    try await service.acceptRequest(friendshipId: friendshipId)
                }
                // For real accounts, the request remains pending
            }
            
            try await refreshFriendships()
            try await refreshDiscover()
        } catch {
            let errorMsg = error.localizedDescription
            print("❌ Error sending friend request: \(errorMsg)")
            
            // Check for foreign key constraint error (profile doesn't exist)
            if errorMsg.contains("foreign key constraint") || errorMsg.contains("requester_id_fkey") {
                errorMessage = "Unable to send friend request. Please try signing out and signing back in to refresh your profile."
                print("⚠️ Foreign key constraint error - user profile may not exist in database")
                print("   This usually happens with Apple Sign In if profile creation failed")
                print("   Solution: Sign out and sign back in, or run FIX_APPLE_SIGNIN_PROFILE_FK.sql")
            } else {
                errorMessage = errorMsg
            }
        }
    }
    
    func getFriendshipStatus(for profileId: String) -> DiscoverFriendshipStatus {
        // Check if there's an existing friendship
        if let friendship = friendships.first(where: {
            ($0.requesterId == myUserId && $0.addresseeId == profileId) ||
            ($0.addresseeId == myUserId && $0.requesterId == profileId)
        }) {
            if friendship.status == .accepted {
                return .accepted
            } else if friendship.status == .pending {
                // Check if it's an outgoing request (we sent it)
                if friendship.requesterId == myUserId {
                    return .pending
                } else {
                    // Incoming request - show as none since we can accept it
                    return .none
                }
            }
        }
        return .none
    }
    
    private func isTestAccountId(_ id: String) -> Bool {
        // Test account IDs from CREATE_AUTH_TEST_ACCOUNTS.sql
        let testAccountIds: Set<String> = [
            "11111111-1111-1111-1111-111111111111",
            "22222222-2222-2222-2222-222222222222",
            "33333333-3333-3333-3333-333333333333",
            "44444444-4444-4444-4444-444444444444",
            "55555555-5555-5555-5555-555555555555"
        ]
        return testAccountIds.contains(id)
    }

    func accept(friendshipId: String) async {
        do {
            try await service.acceptRequest(friendshipId: friendshipId)
            try await refreshFriendships()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func remove(friendshipId: String) async {
        do {
            try await service.removeFriendship(friendshipId: friendshipId)
            try await refreshFriendships()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func cancelFriendRequest(to userId: String) async {
        do {
            // Find the pending outgoing request
            if let friendship = friendships.first(where: {
                $0.requesterId == myUserId &&
                $0.addresseeId == userId &&
                $0.status == .pending
            }) {
                try await service.removeFriendship(friendshipId: friendship.id)
                try await refreshFriendships()
                try await refreshDiscover()
            }
        } catch {
            errorMessage = "Failed to cancel request: \(error.localizedDescription)"
            print("⚠️ Error cancelling friend request: \(error.localizedDescription)")
        }
    }

    // MARK: - Mapping helpers

    private func mapToFriendItems(friendships: [Friendship]) async throws -> [FriendListItem] {
        #if canImport(Supabase)
        let ids = Set(friendships.map { f in
            f.requesterId == myUserId ? f.addresseeId : f.requesterId
        })

        guard !ids.isEmpty else { return [] }

        let profiles: [Profile] = try await supabase
            .from("profiles")
            .select("id,username,display_name,first_name,last_name,avatar_url,public_profile")
            .in("id", values: Array(ids))
            .execute()
            .value
        let byId = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })

        return friendships.compactMap { f in
            let otherId = (f.requesterId == myUserId) ? f.addresseeId : f.requesterId
            guard let other = byId[otherId] else { return nil }

            let incoming = (f.addresseeId == myUserId && f.status == .pending)
            let outgoing = (f.requesterId == myUserId && f.status == .pending)

            return FriendListItem(
                id: f.id,
                profile: other,
                status: f.status,
                isIncomingRequest: incoming,
                isOutgoingRequest: outgoing
            )
        }
        .sorted { $0.profile.username.lowercased() < $1.profile.username.lowercased() }
        #else
        return []
        #endif
    }
}
