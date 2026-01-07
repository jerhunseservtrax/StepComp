//
//  ChallengeChatView.swift
//  StepComp
//
//  Group chat interface for challenge members
//

import SwiftUI

struct ChallengeChatView: View {
    @StateObject private var viewModel: ChallengeChatViewModel
    @Environment(\.dismiss) var dismiss
    @FocusState private var isInputFocused: Bool
    
    
    init(challengeId: String, currentUserId: String, challengeName: String) {
        _viewModel = StateObject(wrappedValue: ChallengeChatViewModel(
            challengeId: challengeId,
            currentUserId: currentUserId
        ))
        self.challengeName = challengeName
    }
    
    let challengeName: String
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ChatHeader(challengeName: challengeName) {
                dismiss()
            }
            
            // Messages
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: StepCompColors.primary))
                Spacer()
            } else if viewModel.messages.isEmpty {
                EmptyChatView()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.messages) { message in
                                ChatMessageRow(
                                    message: message,
                                    isCurrentUser: message.userId == viewModel.currentUserId,
                                    onDelete: {
                                        Task {
                                            await viewModel.deleteMessage(message)
                                        }
                                    }
                                )
                                .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        // Auto-scroll to bottom on new message
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onAppear {
                        // Scroll to bottom when chat first opens
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if let lastMessage = viewModel.messages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }
            
            // Input bar
            ChatInputBar(
                text: $viewModel.inputText,
                isSending: viewModel.isSending,
                isInputFocused: $isInputFocused,
                onSend: {
                    Task {
                        await viewModel.sendMessage()
                    }
                }
            )
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
        .dismissKeyboardOnTap()
        .task {
            await viewModel.loadMessages()
            await viewModel.markAllAsRead()
        }
        .onDisappear {
            // Notify that we've left the chat so ChatListView can refresh
            NotificationCenter.default.post(name: .chatViewDismissed, object: nil)
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

// MARK: - Chat Header

struct ChatHeader: View {
    let challengeName: String
    let onBack: () -> Void
    
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(challengeName)
                    .font(.system(size: 18, weight: .bold))
                
                Text("Group Chat")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Chat Message Row

struct ChatMessageRow: View {
    let message: ChallengeMessage
    let isCurrentUser: Bool
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    
    var body: some View {
        if message.isSystemMessage {
            // System message (centered)
            HStack {
                Spacer()
                Text(message.content)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                Spacer()
            }
        } else {
            // Regular message
            HStack(alignment: .top, spacing: 12) {
                if isCurrentUser {
                    // Push user's messages to the right
                    Spacer()
                }
                
                if !isCurrentUser {
                    // Avatar for other users
                    AvatarView(
                        displayName: message.senderName ?? "?",
                        avatarURL: message.senderAvatarURL,
                        size: 32
                    )
                }
                
                VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                    // Sender name (if not current user)
                    if !isCurrentUser {
                        Text(message.senderName ?? "Unknown")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    
                    // Message bubble
                    Text(message.content)
                        .font(.system(size: 15))
                        .foregroundColor(isCurrentUser ? .black : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            isCurrentUser ? StepCompColors.primary : Color(.systemGray6)
                        )
                        .cornerRadius(18)
                        .contextMenu {
                            if isCurrentUser {
                                Button(role: .destructive) {
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete Message", systemImage: "trash")
                                }
                            }
                        }
                    
                    // Timestamp
                    Text(message.displayTime)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: isCurrentUser ? .trailing : .leading)
            .alert("Delete Message?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    onDelete()
                }
            } message: {
                Text("This message will be deleted for everyone.")
            }
        }
    }
}

// MARK: - Chat Input Bar

struct ChatInputBar: View {
    @Binding var text: String
    let isSending: Bool
    @FocusState.Binding var isInputFocused: Bool
    let onSend: () -> Void
    
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // Text field
                TextField("Message challenge", text: $text)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .focused($isInputFocused)
                    .disabled(isSending)
                
                // Send button
                Button(action: onSend) {
                    if isSending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(width: 36, height: 36)
                    } else {
                        ZStack {
                            Circle()
                                .fill(text.trimmingCharacters(in: .whitespaces).isEmpty ? Color(.systemGray5) : StepCompColors.primary)
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                        }
                    }
                }
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Empty Chat View

struct EmptyChatView: View {
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(StepCompColors.primary)
            
            Text("Start the Conversation")
                .font(.system(size: 20, weight: .bold))
            
            Text("Send the first message to get the challenge chat started!")
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
        ChallengeChatView(
            challengeId: "test-challenge-id",
            currentUserId: "test-user-id",
            challengeName: "Morning Sprinters"
        )
    }
}

