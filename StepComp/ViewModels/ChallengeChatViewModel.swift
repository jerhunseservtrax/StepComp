//
//  ChallengeChatViewModel.swift
//  StepComp
//
//  Manages challenge group chat with realtime updates
//

import Foundation
import Combine
#if canImport(Supabase)
import Supabase
import Realtime
#endif

@MainActor
final class ChallengeChatViewModel: ObservableObject {
    @Published var messages: [ChallengeMessage] = []
    @Published var inputText: String = ""
    @Published var isSending: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var unreadCount: Int = 0
    
    let challengeId: String
    let currentUserId: String
    
    #if canImport(Supabase)
    private var channel: RealtimeChannelV2?
    #endif
    
    init(challengeId: String, currentUserId: String) {
        self.challengeId = challengeId
        self.currentUserId = currentUserId
    }
    
    deinit {
        // Cleanup is handled automatically by channel lifecycle
        print("✅ ChallengeChatViewModel deinitialized")
    }
    
    // MARK: - Load Messages
    
    func loadMessages() async {
        isLoading = true
        errorMessage = nil
        
        #if canImport(Supabase)
        do {
            // First, try with profile join
            do {
                let response: [ServerChallengeMessage] = try await supabase
                    .from("challenge_messages")
                    .select("""
                        *,
                        profiles(username, display_name, avatar_url)
                    """)
                    .eq("challenge_id", value: challengeId)
                    .eq("is_deleted", value: false)
                    .order("created_at", ascending: true)
                    .execute()
                    .value
                
                messages = response.map { $0.toChallengeMessage() }
                print("✅ Loaded \(messages.count) messages for challenge \(challengeId)")
                
            } catch {
                // Fallback: Load messages without profile join, then fetch profiles separately
                print("⚠️ Profile join failed, using fallback method")
                
                struct SimpleMessage: Codable {
                    let id: String
                    let challengeId: String
                    let userId: String
                    let content: String
                    let messageType: String
                    let createdAt: String
                    let editedAt: String?
                    let isDeleted: Bool
                    
                    enum CodingKeys: String, CodingKey {
                        case id
                        case challengeId = "challenge_id"
                        case userId = "user_id"
                        case content
                        case messageType = "message_type"
                        case createdAt = "created_at"
                        case editedAt = "edited_at"
                        case isDeleted = "is_deleted"
                    }
                }
                
                let simpleMessages: [SimpleMessage] = try await supabase
                    .from("challenge_messages")
                    .select()
                    .eq("challenge_id", value: challengeId)
                    .eq("is_deleted", value: false)
                    .order("created_at", ascending: true)
                    .execute()
                    .value
                
                // Get unique user IDs
                let userIds = Array(Set(simpleMessages.map { $0.userId }))
                
                // Fetch profiles for these users
                var profilesMap: [String: ServerChallengeMessage.ProfileInfo] = [:]
                if !userIds.isEmpty {
                    struct ProfileRow: Codable {
                        let id: String
                        let username: String?
                        let displayName: String?
                        let avatarUrl: String?
                        
                        enum CodingKeys: String, CodingKey {
                            case id
                            case username
                            case displayName = "display_name"
                            case avatarUrl = "avatar_url"
                        }
                    }
                    
                    let profiles: [ProfileRow] = try await supabase
                        .from("profiles")
                        .select()
                        .in("id", values: userIds)
                        .execute()
                        .value
                    
                    for profile in profiles {
                        profilesMap[profile.id] = ServerChallengeMessage.ProfileInfo(
                            username: profile.username,
                            displayName: profile.displayName,
                            avatarUrl: profile.avatarUrl
                        )
                    }
                }
                
                // Combine messages with profiles
                messages = simpleMessages.map { msg in
                    let profile = profilesMap[msg.userId]
                    let messageType = ChallengeMessage.MessageType(rawValue: msg.messageType) ?? .text
                    
                    // Parse date from string
                    let dateFormatter = ISO8601DateFormatter()
                    let createdDate = dateFormatter.date(from: msg.createdAt) ?? Date()
                    let editedDate: Date? = msg.editedAt.flatMap { dateFormatter.date(from: $0) }
                    
                    return ChallengeMessage(
                        id: msg.id,
                        challengeId: msg.challengeId,
                        userId: msg.userId,
                        content: msg.content,
                        messageType: messageType,
                        createdAt: createdDate,
                        editedAt: editedDate,
                        isDeleted: msg.isDeleted,
                        senderName: profile?.displayName ?? profile?.username ?? "Unknown",
                        senderAvatarURL: profile?.avatarUrl
                    )
                }
                
                print("✅ Loaded \(messages.count) messages using fallback method")
            }
            
            // Subscribe to realtime after loading
            subscribeToRealtime()
            
            // Load unread count
            await loadUnreadCount()
            
        } catch {
            print("⚠️ Error loading messages: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        #endif
        
        isLoading = false
    }
    
    // MARK: - Send Message
    
    func sendMessage() async {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let messageContent = inputText
        inputText = "" // Clear immediately for better UX
        isSending = true
        errorMessage = nil
        
        #if canImport(Supabase)
        do {
            _ = try await supabase
                .rpc("send_challenge_message", params: [
                    "p_challenge_id": challengeId,
                    "p_content": messageContent
                ])
                .execute()
            
            print("✅ Message sent successfully")
            
            // Reload messages to get the new message with profile data
            await loadMessages()
            
        } catch {
            print("⚠️ Error sending message: \(error.localizedDescription)")
            errorMessage = "Failed to send message"
            inputText = messageContent // Restore text on error
        }
        #endif
        
        isSending = false
    }
    
    // MARK: - Soft Delete Message
    
    func deleteMessage(_ message: ChallengeMessage) async {
        guard message.userId == currentUserId else {
            errorMessage = "You can only delete your own messages"
            return
        }
        
        #if canImport(Supabase)
        do {
            try await supabase
                .from("challenge_messages")
                .update(["is_deleted": true])
                .eq("id", value: message.id)
                .execute()
            
            // Remove from local list
            messages.removeAll { $0.id == message.id }
            print("✅ Message deleted successfully")
            
        } catch {
            print("⚠️ Error deleting message: \(error.localizedDescription)")
            errorMessage = "Failed to delete message"
        }
        #endif
    }
    
    // MARK: - Edit Message
    
    func editMessage(_ message: ChallengeMessage, newContent: String) async {
        guard message.userId == currentUserId else {
            errorMessage = "You can only edit your own messages"
            return
        }
        
        guard !newContent.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        #if canImport(Supabase)
        do {
            try await supabase
                .from("challenge_messages")
                .update([
                    "content": newContent,
                    "edited_at": ISO8601DateFormatter().string(from: Date())
                ])
                .eq("id", value: message.id)
                .execute()
            
            // Update local list
            if let index = messages.firstIndex(where: { $0.id == message.id }) {
                messages[index].content = newContent
                messages[index].editedAt = Date()
            }
            
            print("✅ Message edited successfully")
            
        } catch {
            print("⚠️ Error editing message: \(error.localizedDescription)")
            errorMessage = "Failed to edit message"
        }
        #endif
    }
    
    // MARK: - Unread Count
    
    func loadUnreadCount() async {
        #if canImport(Supabase)
        do {
            let response: Int = try await supabase
                .rpc("get_challenge_unread_count", params: [
                    "p_challenge_id": challengeId
                ])
                .execute()
                .value
            
            unreadCount = response
            print("📬 Unread messages: \(unreadCount)")
            
        } catch {
            print("⚠️ Error loading unread count: \(error.localizedDescription)")
        }
        #endif
    }
    
    func markAllAsRead() async {
        // Mark all messages as read
        #if canImport(Supabase)
        do {
            // Try using RPC function for marking messages as read
            try await supabase
                .rpc("mark_challenge_messages_read", params: [
                    "p_challenge_id": challengeId
                ])
                .execute()
            
            unreadCount = 0
            print("✅ All messages marked as read")
            
        } catch let rpcError {
            print("⚠️ RPC method failed, trying direct upsert: \(rpcError.localizedDescription)")
            
            // Fallback to direct upsert
            var successCount = 0
            for message in messages where message.userId != currentUserId {
                do {
                    try await supabase
                        .from("challenge_message_reads")
                        .upsert([
                            "user_id": currentUserId,
                            "message_id": message.id
                        ])
                        .execute()
                    successCount += 1
                } catch {
                    print("⚠️ Failed to mark message as read: \(error.localizedDescription)")
                }
            }
            
            unreadCount = 0
            print("✅ Marked \(successCount) messages as read")
        }
        #endif
    }
    
    // MARK: - Realtime Subscription
    
    func subscribeToRealtime() {
        #if canImport(Supabase)
        let channelName = "challenge-chat-\(challengeId)"
        
        channel = supabase.channel(channelName)
        
        // Note: Realtime subscriptions in Supabase Swift use a different API
        // For now, we'll implement manual polling as fallback
        // TODO: Update to proper realtime when API is confirmed
        
        Task {
            do {
                try await channel?.subscribeWithError()
                print("✅ Subscribed to realtime chat for challenge \(challengeId)")
            } catch {
                print("⚠️ Error subscribing to realtime chat: \(error.localizedDescription)")
            }
        }
        
        // Post notification for badge updates
        NotificationCenter.default.post(name: .chatMessageReceived, object: nil)
        #endif
    }
    
    func unsubscribeFromRealtime() {
        #if canImport(Supabase)
        Task {
            await channel?.unsubscribe()
            print("✅ Unsubscribed from realtime chat")
        }
        #endif
    }
}

