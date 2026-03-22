//
//  ChatListView.swift
//  FitComp
//
//  Displays all chats the user is in with quick access
//

import SwiftUI

struct ChatListView: View {
    @StateObject private var viewModel: ChatListViewModel
    @Environment(\.dismiss) var dismiss
    
    let currentUserId: String
    let onChatSelected: (String, String) -> Void // (challengeId, challengeName)
    
    
    init(currentUserId: String, onChatSelected: @escaping (String, String) -> Void) {
        self.currentUserId = currentUserId
        self.onChatSelected = onChatSelected
        _viewModel = StateObject(wrappedValue: ChatListViewModel(userId: currentUserId))
    }
    
    var body: some View {
        // Note: This view should be embedded in a NavigationStack by its parent
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: FitCompColors.primary))
            } else if viewModel.chatPreviews.isEmpty {
                EmptyChatsView()
            } else {
                List {
                    ForEach(viewModel.chatPreviews) { preview in
                        Button(action: {
                            onChatSelected(preview.id, preview.challengeName)
                        }) {
                            ChatPreviewRow(preview: preview)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Chats")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .dismissKeyboardOnTap()
        .task {
            print("📱 ChatListView appeared, loading chats...")
            await viewModel.loadChats()
        }
        .refreshable {
            print("🔄 ChatListView refreshing...")
            await viewModel.loadChats()
        }
        .onAppear {
            // Always reload chats when view appears to get updated unread counts
            // This ensures unread badges update after viewing a chat
            Task {
                await viewModel.loadChats()
            }
        }
        .onDisappear {
            NotificationCenter.default.post(name: .chatViewDismissed, object: nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: .chatViewDismissed)) { _ in
            // Refresh chat list when user returns from viewing a chat
            Task {
                print("🔄 Chat view dismissed, refreshing chat list...")
                await viewModel.loadChats()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
}

// MARK: - Chat Preview Row

struct ChatPreviewRow: View {
    let preview: ChatPreview
    
    
    var body: some View {
        HStack(spacing: 12) {
            // Challenge Avatar/Icon
            ZStack {
                Circle()
                    .fill(FitCompColors.primary.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 20))
                    .foregroundColor(FitCompColors.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Challenge name
                Text(preview.challengeName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Last message
                if let lastMessage = preview.lastMessage {
                    Text(lastMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                } else {
                    Text("No messages yet")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                // Time
                if let displayTime = preview.displayTime {
                    Text(displayTime)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                // Unread badge
                if preview.hasUnread {
                    Text("\(preview.unreadCount)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(minWidth: 20, minHeight: 20)
                        .background(Color.red)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Empty Chats View

struct EmptyChatsView: View {
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(FitCompColors.primary)
            
            Text("No Chats Yet")
                .font(.system(size: 20, weight: .bold))
            
            Text("Join a challenge to start chatting with other members!")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ChatListView(currentUserId: "test-user-id") { _, _ in }
    }
}

