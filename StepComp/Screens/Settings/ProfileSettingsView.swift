//
//  ProfileSettingsView.swift
//  StepComp
//
//  Edit profile information (name, username, avatar, bio)
//

import SwiftUI

struct ProfileSettingsView: View {
    let user: User
    
    @Environment(\.dismiss) var dismiss
    @State private var displayName: String
    @State private var username: String
    @State private var bio: String = ""
    @State private var selectedAvatar: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    // Available avatar emojis
    private let avatarOptions = [
        "👽", "🐱", "🤖", "🦊", "🐼", "🦁", "🐯", "🐸",
        "🦄", "🐙", "🦉", "🐝", "🦋", "🐢", "🦖", "🐲",
        "🎭", "🎨", "🎪", "🎯", "🎸", "🎮", "🚀", "⚡️"
    ]
    
    init(user: User) {
        self.user = user
        _displayName = State(initialValue: user.displayName)
        _username = State(initialValue: user.username ?? "")
        _selectedAvatar = State(initialValue: user.avatarURL ?? "👽")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Avatar Selection
                Section(header: Text("Avatar")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(avatarOptions, id: \.self) { emoji in
                                Button(action: {
                                    selectedAvatar = emoji
                                }) {
                                    Text(emoji)
                                        .font(.system(size: 48))
                                        .frame(width: 72, height: 72)
                                        .background(
                                            Circle()
                                                .fill(selectedAvatar == emoji ? primaryYellow.opacity(0.3) : Color(.systemGray6))
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(selectedAvatar == emoji ? primaryYellow : Color.clear, lineWidth: 3)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Display Name
                Section(header: Text("Display Name")) {
                    TextField("Display Name", text: $displayName)
                        .textInputAutocapitalization(.words)
                }
                
                // Username
                Section(header: Text("Username"), footer: Text("Your unique username. Others can find you by this.")) {
                    HStack {
                        Text("@")
                            .foregroundColor(.secondary)
                        TextField("username", text: $username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }
                
                // Bio
                Section(header: Text("Bio (Optional)"), footer: Text("Tell others a bit about yourself!")) {
                    TextEditor(text: $bio)
                        .frame(minHeight: 80)
                }
                
                // Account Info
                Section(header: Text("Account Info")) {
                    HStack {
                        Text("Email")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(user.email ?? "Not set")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("User ID")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(user.id.prefix(8) + "...")
                            .foregroundColor(.secondary)
                            .font(.system(.caption, design: .monospaced))
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveProfile()
                        }
                    }
                    .fontWeight(.bold)
                    .disabled(isSaving || displayName.isEmpty)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .overlay {
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: primaryYellow))
                                .scaleEffect(1.5)
                            
                            Text("Saving...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                        )
                    }
                }
            }
        }
    }
    
    private func saveProfile() async {
        isSaving = true
        
        // TODO: Implement actual profile update via AuthService
        // await authService.updateProfile(
        //     displayName: displayName,
        //     username: username,
        //     avatarURL: selectedAvatar,
        //     bio: bio
        // )
        
        // Simulate save
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        isSaving = false
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    ProfileSettingsView(
        user: User(
            id: "123",
            email: "user@example.com",
            displayName: "John Doe",
            username: "johndoe",
            avatarURL: "👽",
            totalSteps: 50000,
            dailyStepGoal: 10000,
            currentStreak: 5,
            publicProfile: true
        )
    )
}

