//
//  ChatListViewModel.swift
//  FitComp
//
//  Manages the list of all chats the user is in
//

import Foundation
import Combine
#if canImport(Supabase)
import Supabase
#endif

@MainActor
final class ChatListViewModel: ObservableObject {
    @Published var chatPreviews: [ChatPreview] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var totalUnreadCount: Int = 0
    
    let userId: String
    
    init(userId: String) {
        self.userId = userId
    }
    
    // MARK: - Load Chats
    
    func loadChats() async {
        isLoading = true
        errorMessage = nil
        
        #if canImport(Supabase)
        do {
            // Get all challenges the user is in
            let challenges = try await getUserChallenges()
            print("📊 Found \(challenges.count) challenges for user")
            
            guard !challenges.isEmpty else {
                chatPreviews = []
                totalUnreadCount = 0
                isLoading = false
                print("ℹ️ No challenges found for user")
                return
            }
            
            // Get unread counts and last messages for each challenge
            var previews: [ChatPreview] = []
            var totalUnread = 0
            
            await withTaskGroup(of: (ChatPreview?, Int).self) { group in
                for challenge in challenges {
                    let challengeId = challenge.id
                    let challengeName = challenge.name
                    group.addTask { [weak self] in
                        guard self != nil else { return (nil, 0) }
                        do {
                            let unreadCount = try await Self.fetchUnreadCount(challengeId: challengeId)
                            let lastMessage = try? await Self.fetchLastMessage(challengeId: challengeId)
                            
                            let preview = ChatPreview(
                                id: challengeId,
                                challengeName: challengeName,
                                lastMessage: lastMessage?.content,
                                lastMessageTime: lastMessage?.createdAt,
                                unreadCount: unreadCount,
                                challengeAvatarURL: nil
                            )
                            
                            return (preview, unreadCount)
                        } catch {
                            print("⚠️ Error processing challenge \(challengeId): \(error.localizedDescription)")
                            return (nil, 0)
                        }
                    }
                }
                
                for await (preview, unreadCount) in group {
                    if let preview = preview {
                        previews.append(preview)
                        totalUnread += unreadCount
                    }
                }
            }
            
            // Sort by last message time (most recent first)
            chatPreviews = previews.sorted { preview1, preview2 in
                guard let time1 = preview1.lastMessageTime else { return false }
                guard let time2 = preview2.lastMessageTime else { return true }
                return time1 > time2
            }
            
            totalUnreadCount = totalUnread
            print("✅ Loaded \(chatPreviews.count) chats with \(totalUnreadCount) total unread")
            
        } catch {
            print("❌ Error loading chats: \(error.localizedDescription)")
            errorMessage = "Failed to load chats: \(error.localizedDescription)"
            chatPreviews = []
            totalUnreadCount = 0
        }
        #else
        chatPreviews = []
        totalUnreadCount = 0
        #endif
        
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    #if canImport(Supabase)
    private func getUserChallenges() async throws -> [SimpleChallengeInfo] {
        // Get challenge IDs where user is a member
        let memberRecords: [ChallengeMember] = try await supabase
            .from("challenge_members")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
        
        let challengeIds = memberRecords.map { $0.challengeId }
        
        guard !challengeIds.isEmpty else {
            return []
        }
        
        // Get challenge info - check if challenges actually exist AND haven't ended
        let challenges: [SimpleChallengeInfo] = try await supabase
            .from("challenges")
            .select("id, name")
            .in("id", values: challengeIds)
            .gte("end_date", value: ISO8601DateFormatter().string(from: Date()))
            .execute()
            .value
        
        // Find orphaned challenge_members (member record exists but challenge doesn't or has ended)
        let foundChallengeIds = Set(challenges.map { $0.id })
        let orphanedIds = Set(challengeIds).subtracting(foundChallengeIds)
        
        // Clean up orphaned records
        if !orphanedIds.isEmpty {
            for orphanedId in orphanedIds {
                do {
                    try await supabase
                        .from("challenge_members")
                        .delete()
                        .eq("user_id", value: userId)
                        .eq("challenge_id", value: orphanedId)
                        .execute()
                } catch {
                    print("⚠️ Failed to clean up orphaned record: \(error.localizedDescription)")
                }
            }
        }
        
        return challenges
    }
    
    nonisolated private static func fetchUnreadCount(challengeId: String) async throws -> Int {
        do {
            let result = try await supabase
                .rpc("get_challenge_unread_count", params: [
                    "p_challenge_id": challengeId
                ])
                .execute()
            
            let decoder = JSONDecoder()
            do {
                let count = try decoder.decode(Int.self, from: result.data)
                return count
            } catch {
                if let counts = try? decoder.decode([Int].self, from: result.data),
                   let first = counts.first {
                    return first
                }
                if let countString = String(data: result.data, encoding: .utf8),
                   let count = Int(countString.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    return count
                }
                return 0
            }
        } catch {
            print("⚠️ Error getting unread count for challenge \(challengeId): \(error.localizedDescription)")
            return 0
        }
    }
    
    nonisolated private static func fetchLastMessage(challengeId: String) async throws -> LastMessageInfo? {
        let messages: [LastMessageInfo] = try await supabase
            .from("challenge_messages")
            .select("id, content, created_at")
            .eq("challenge_id", value: challengeId)
            .eq("is_deleted", value: false)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value
        
        return messages.first
    }
    #endif
}

// MARK: - Helper Models

struct SimpleChallengeInfo: Codable {
    let id: String
    let name: String
}

struct LastMessageInfo: Codable {
    let id: String
    let content: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case content
        case createdAt = "created_at"
    }
}

