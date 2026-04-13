//
//  ChallengeChatViewModel.swift
//  FitComp
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
    @Published var isLoadingMore: Bool = false
    @Published var hasMoreMessages: Bool = true
    
    let challengeId: String
    let currentUserId: String
    
    #if canImport(Supabase)
    private var channel: RealtimeChannelV2?
    #endif
    private let pageSize = 40
    private var oldestLoadedDate: Date?
    private var refreshTask: Task<Void, Never>?
    
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
        oldestLoadedDate = nil
        hasMoreMessages = true
        
        #if canImport(Supabase)
        do {
            let latest = try await fetchLatestMessages(limit: pageSize)
            messages = latest
            oldestLoadedDate = latest.first?.createdAt
            hasMoreMessages = latest.count >= pageSize
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

    func loadMoreMessages() async {
        guard !isLoadingMore, hasMoreMessages else { return }
        guard let oldestLoadedDate else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        #if canImport(Supabase)
        do {
            let older = try await fetchMessages(before: oldestLoadedDate, limit: pageSize)
            if older.isEmpty {
                hasMoreMessages = false
                return
            }

            messages = (older + messages).uniquedById()
            self.oldestLoadedDate = messages.first?.createdAt
            hasMoreMessages = older.count >= pageSize
        } catch {
            errorMessage = "Failed to load older messages"
        }
        #endif
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
            
            let latest = try await fetchLatestMessages(limit: pageSize)
            messages = latest
            oldestLoadedDate = latest.first?.createdAt
            hasMoreMessages = latest.count >= pageSize
            
            // Post notification to update chat badge in dashboard header
            NotificationCenter.default.post(name: .chatMessageReceived, object: nil)
            
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
        refreshTask?.cancel()
        let cid = challengeId

        let ch = supabase.channel("challenge-chat-\(cid)")
        channel = ch

        let insertStream = ch.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "challenge_messages",
            filter: "challenge_id=eq.\(cid)"
        )
        let updateStream = ch.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "challenge_messages",
            filter: "challenge_id=eq.\(cid)"
        )
        let deleteStream = ch.postgresChange(
            DeleteAction.self,
            schema: "public",
            table: "challenge_messages",
            filter: "challenge_id=eq.\(cid)"
        )

        refreshTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await ch.subscribeWithError()
            } catch {
                #if DEBUG
                print("⚠️ Realtime subscribe failed, falling back to polling: \(error.localizedDescription)")
                #endif
                await self.fallbackPolling()
                return
            }

            await withTaskGroup(of: Void.self) { group in
                group.addTask { [weak self] in
                    for await _ in insertStream {
                        guard let self, !Task.isCancelled else { return }
                        await self.refreshMessages()
                    }
                }
                group.addTask { [weak self] in
                    for await _ in updateStream {
                        guard let self, !Task.isCancelled else { return }
                        await self.refreshMessages()
                    }
                }
                group.addTask { [weak self] in
                    for await _ in deleteStream {
                        guard let self, !Task.isCancelled else { return }
                        await self.refreshMessages()
                    }
                }
            }
        }

        NotificationCenter.default.post(name: .chatMessageReceived, object: nil)
        #endif
    }

    func unsubscribeFromRealtime() {
        #if canImport(Supabase)
        refreshTask?.cancel()
        refreshTask = nil
        Task { [channel] in
            await channel?.unsubscribe()
        }
        #endif
    }

    #if canImport(Supabase)
    private func refreshMessages() async {
        do {
            let latest = try await fetchLatestMessages(limit: pageSize)
            if latest.last?.id != messages.last?.id || latest.count != messages.count {
                messages = latest
                oldestLoadedDate = latest.first?.createdAt
                hasMoreMessages = latest.count >= pageSize
                NotificationCenter.default.post(name: .chatMessageReceived, object: nil)
            }
        } catch {
            #if DEBUG
            print("⚠️ Refresh after realtime event failed: \(error.localizedDescription)")
            #endif
        }
    }

    private func fallbackPolling() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await refreshMessages()
        }
    }
    #endif

    #if canImport(Supabase)
    private func fetchLatestMessages(limit: Int) async throws -> [ChallengeMessage] {
        let response: [ServerChallengeMessage] = try await supabase
            .from("challenge_messages")
            .select("""
                *,
                profiles(username, display_name, avatar_url)
            """)
            .eq("challenge_id", value: challengeId)
            .eq("is_deleted", value: false)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return response
            .map { $0.toChallengeMessage() }
            .sorted { $0.createdAt < $1.createdAt }
    }

    private func fetchMessages(before: Date, limit: Int) async throws -> [ChallengeMessage] {
        let iso = ISO8601DateFormatter().string(from: before)
        let response: [ServerChallengeMessage] = try await supabase
            .from("challenge_messages")
            .select("""
                *,
                profiles(username, display_name, avatar_url)
            """)
            .eq("challenge_id", value: challengeId)
            .eq("is_deleted", value: false)
            .lt("created_at", value: iso)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return response
            .map { $0.toChallengeMessage() }
            .sorted { $0.createdAt < $1.createdAt }
    }
    #endif
}

private extension Array where Element == ChallengeMessage {
    func uniquedById() -> [ChallengeMessage] {
        var seen = Set<String>()
        return filter {
            seen.insert($0.id).inserted
        }
    }
}

