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
    
    private let challengeId: String
    private let currentUserId: String
    
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
            let response: [ServerChallengeMessage] = try await supabase
                .from("challenge_messages")
                .select("""
                    id,
                    challenge_id,
                    user_id,
                    content,
                    message_type,
                    created_at,
                    edited_at,
                    is_deleted,
                    profiles!challenge_messages_user_id_fkey(username, display_name, avatar_url)
                """)
                .eq("challenge_id", value: challengeId)
                .eq("is_deleted", value: false)
                .order("created_at", ascending: true)
                .execute()
                .value
            
            messages = response.map { $0.toChallengeMessage() }
            print("✅ Loaded \(messages.count) messages for challenge \(challengeId)")
            
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
            
            // Message will appear via realtime subscription
            
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
            for message in messages where message.userId != currentUserId {
                try await supabase
                    .from("challenge_message_reads")
                    .upsert([
                        "user_id": currentUserId,
                        "message_id": message.id
                    ])
                    .execute()
            }
            
            unreadCount = 0
            print("✅ All messages marked as read")
            
        } catch {
            print("⚠️ Error marking messages as read: \(error.localizedDescription)")
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
            await channel?.subscribe()
            print("✅ Subscribed to realtime chat for challenge \(challengeId)")
        }
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

