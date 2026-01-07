//
//  DashboardHeader.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
#if canImport(Supabase)
import Supabase
#endif

struct DashboardHeader: View {
    let user: User?
    @State private var showingInbox = false
    @State private var showingChats = false
    @State private var unreadNotificationCount: Int = 0
    @State private var unreadChatCount: Int = 0
    @State private var navigationPath = NavigationPath()
    
    var firstName: String {
        user?.firstName ?? "User"
    }
    
    var displayName: String {
        user?.displayName ?? "User"
    }
    
    var body: some View {
        HStack {
            // Greeting (new style)
            VStack(alignment: .leading, spacing: 2) {
                Text("WELCOME BACK")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .kerning(1.5)
                
                Text("\(firstName)!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                // Chat button with badge
                Button(action: {
                    showingChats = true
                }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .frame(width: 40, height: 40)
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                        
                        // Badge indicator
                        if unreadChatCount > 0 {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                                .offset(x: 4, y: -4)
                        }
                    }
                }
                .sheet(isPresented: $showingChats) {
                    NavigationStack(path: $navigationPath) {
                        ChatListView(currentUserId: user?.id ?? "") { challengeId, challengeName in
                            // Navigate to chat when selected
                            navigationPath.append(ChatDestination.chat(
                                challengeId: challengeId,
                                challengeName: challengeName
                            ))
                        }
                        .navigationDestination(for: ChatDestination.self) { destination in
                            switch destination {
                            case .chat(let challengeId, let challengeName):
                                ChallengeChatView(
                                    challengeId: challengeId,
                                    currentUserId: user?.id ?? "",
                                    challengeName: challengeName
                                )
                            }
                        }
                    }
                }
                
                // Profile button
                Button(action: {
                    showingInbox = true
                }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "person")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 40, height: 40)
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                        
                        // Badge indicator for notifications
                        if unreadNotificationCount > 0 {
                            Text("\(unreadNotificationCount)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .frame(minWidth: 14, minHeight: 14)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 4, y: -4)
                        }
                    }
                }
                .sheet(isPresented: $showingInbox) {
                    InboxView(userId: user?.id ?? "")
                }
            }
        }
        .padding(.horizontal, 20)
        .task {
            // Load unread counts
            await loadUnreadCounts()
        }
        .onReceive(NotificationCenter.default.publisher(for: .chatMessageReceived)) { _ in
            // Refresh chat count when new message received
            Task {
                await loadChatUnreadCount()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .chatViewDismissed)) { _ in
            // Refresh chat count when user returns from a chat
            Task {
                await loadChatUnreadCount()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .newNotificationReceived)) { _ in
            // Refresh notification count when new notification is created
            Task {
                await loadNotificationUnreadCount()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .notificationBadgeNeedsRefresh)) { _ in
            // Refresh notification count when notifications are marked as read
            Task {
                await loadNotificationUnreadCount()
            }
        }
    }
    
    private func loadUnreadCounts() async {
        await loadNotificationUnreadCount()
        await loadChatUnreadCount()
    }
    
    private func loadNotificationUnreadCount() async {
        guard let userId = user?.id else { return }
        
        #if canImport(Supabase)
        do {
            // Count unread notifications for this user
            let result = try await supabase
                .from("notifications")
                .select("id", head: false, count: .exact)
                .eq("user_id", value: userId)
                .eq("is_read", value: false)
                .execute()
            
            unreadNotificationCount = result.count ?? 0
            print("✅ Unread notifications: \(unreadNotificationCount)")
        } catch {
            print("⚠️ Error loading notification count: \(error.localizedDescription)")
            unreadNotificationCount = 0
        }
        #else
        unreadNotificationCount = 0
        #endif
    }
    
    private func loadChatUnreadCount() async {
        guard let userId = user?.id else { return }
        
        #if canImport(Supabase)
        let viewModel = ChatListViewModel(userId: userId)
        await viewModel.loadChats()
        unreadChatCount = viewModel.totalUnreadCount
        #else
        unreadChatCount = 0
        #endif
    }
}

// MARK: - Chat Navigation

enum ChatDestination: Hashable {
    case chat(challengeId: String, challengeName: String)
}

