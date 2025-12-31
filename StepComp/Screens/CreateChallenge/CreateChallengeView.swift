//
//  CreateChallengeView.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine

struct CreateChallengeView: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    @StateObject private var viewModel: CreateChallengeViewModel
    @EnvironmentObject var challengeService: ChallengeService
    @EnvironmentObject var friendsService: FriendsService
    @Environment(\.dismiss) var dismiss
    
    @State private var showingSuccess = false
    @State private var showingDatePicker = false
    @State private var showingCustomDuration = false
    @State private var searchText: String = ""
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    init(sessionViewModel: SessionViewModel) {
        self.sessionViewModel = sessionViewModel
        let userId = sessionViewModel.currentUser?.id ?? ""
        // Initialize with placeholder - will be updated in onAppear
        _viewModel = StateObject(
            wrappedValue: CreateChallengeViewModel(
                challengeService: ChallengeService(),
                creatorId: userId
            )
        )
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Top App Bar
                    TopAppBar(onBack: { dismiss() })
                    
                    // Preview Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Challenge Ticket")
                            .font(.system(size: 28, weight: .bold))
                            .padding(.horizontal)
                            .padding(.top, 24)
                        
                        ChallengePreviewCard(
                            name: viewModel.name.isEmpty ? "Morning Sprinters" : viewModel.name,
                            startDate: viewModel.startDate,
                            duration: viewModel.durationInDays,
                            creatorName: sessionViewModel.currentUser?.displayName ?? "You"
                        )
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 24)
                    
                    // Form Section
                    VStack(spacing: 24) {
                        // Name Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name it")
                                .font(.system(size: 16, weight: .bold))
                            
                            TextField("e.g. Weekend Warriors", text: $viewModel.name)
                                .textFieldStyle(CreateChallengeTextFieldStyle())
                        }
                        .padding(.horizontal)
                        
                        // Duration Selector
                        DurationSelectorView(
                            selectedDuration: $viewModel.selectedDuration,
                            onSelect: { duration in
                                if duration == .custom {
                                    showingCustomDuration = true
                                } else {
                                    viewModel.updateDuration(duration)
                                }
                            }
                        )
                        .padding(.horizontal)
                        
                        // Start Date Selector
                        StartDateSelectorView(
                            startDateMode: $viewModel.startDateMode,
                            onSelectMode: { mode in
                                viewModel.updateStartDateMode(mode)
                            },
                            onPickDate: {
                                showingDatePicker = true
                            }
                        )
                        .padding(.horizontal)
                        
                        // Invite Section
                        InviteSectionView(
                            selectedParticipants: $viewModel.selectedParticipants,
                            friends: [], // FriendsLoaderViewModel will load friends from Supabase
                            searchText: $searchText,
                            isFriendsOnly: $viewModel.isFriendsOnly
                        )
                        .padding(.horizontal)
                        
                        // Privacy Setting
                        PrivacyToggleView(isPrivate: $viewModel.isPrivate)
                            .padding(.horizontal)
                        
                        // Spacer for bottom button
                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(.vertical, 24)
                }
            }
            
            // Sticky Footer Button
            VStack {
                Spacer()
                StickyFooterButton(
                    title: "Launch Challenge",
                    isLoading: viewModel.isLoading,
                    isEnabled: viewModel.isValid,
                    action: {
                        Task {
                            await viewModel.createChallenge()
                            if viewModel.createdChallenge != nil {
                                // Refresh challenges immediately after creation
                                #if canImport(Supabase)
                                await challengeService.refreshChallenges()
                                #endif
                                showingSuccess = true
                            }
                        }
                    }
                )
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingDatePicker) {
            NavigationStack {
                DatePicker(
                    "Start Date",
                    selection: $viewModel.startDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .navigationTitle("Select Start Date")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Done") {
                            showingDatePicker = false
                            viewModel.updateDuration(viewModel.selectedDuration) // Recalculate end date
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .alert("Challenge Created!", isPresented: $showingSuccess) {
            Button("OK") {
                viewModel.reset()
                // Refresh challenges after creation
                Task {
                    #if canImport(Supabase)
                    await challengeService.refreshChallenges()
                    #endif
                }
                dismiss()
            }
        } message: {
            Text("Your challenge has been created successfully.")
        }
        .sheet(isPresented: $showingCustomDuration) {
            CustomDurationSheet(
                customDays: $viewModel.customDays,
                onSave: { days in
                    viewModel.updateCustomDays(days)
                    viewModel.updateDuration(.custom)
                    showingCustomDuration = false
                },
                onCancel: {
                    showingCustomDuration = false
                }
            )
        }
        .dismissKeyboardOnTap()
        .onAppear {
            viewModel.updateService(challengeService)
            
            // Debug logging for user state
            print("🔍 CreateChallengeView appeared")
            print("   currentUser: \(sessionViewModel.currentUser?.username ?? "nil")")
            print("   currentUser.id: \(sessionViewModel.currentUser?.id ?? "nil")")
            print("   isAuthenticated: \(sessionViewModel.isAuthenticated)")
            
            if sessionViewModel.currentUser == nil {
                print("⚠️ WARNING: currentUser is nil! Challenge creation will fail.")
            } else if sessionViewModel.currentUser?.id.isEmpty ?? true {
                print("⚠️ WARNING: currentUser.id is empty! Challenge creation will fail.")
            } else {
                print("✅ User authenticated and ready to create challenges")
            }
        }
        .onDisappear {
            // Always reset the form when view disappears
            // This ensures clean state for next challenge creation
            print("🔄 CreateChallengeView disappeared - resetting form")
            viewModel.reset()
        }
        .onChange(of: challengeService.challenges.count) {
            // Update viewModel when challenges change
            viewModel.updateService(challengeService)
        }
    }
}

// MARK: - Top App Bar

struct TopAppBar: View {
    let onBack: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
                    .frame(width: 48, height: 48)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text("New Challenge")
                .font(.system(size: 18, weight: .bold))
            
            Spacer()
            
            Button(action: {}) {
                Text("Help")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(red: 0.62, green: 0.62, blue: 0.28))
                    .frame(width: 48, height: 48)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            Color(.systemBackground)
                .opacity(0.95)
                .background(.ultraThinMaterial)
        )
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.black.opacity(0.05)),
            alignment: .bottom
        )
    }
}

// MARK: - Challenge Preview Card

struct ChallengePreviewCard: View {
    let name: String
    let startDate: Date
    let duration: Int
    let creatorName: String
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        VStack(spacing: 0) {
            // Image Section
            ZStack(alignment: .bottomLeading) {
                // Placeholder gradient background
                LinearGradient(
                    colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 200)
                
                // Gradient overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Badge
                HStack {
                    Text("Step Master")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(primaryYellow)
                        .cornerRadius(20)
                }
                .padding()
            }
            
            // Content Section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .font(.system(size: 20, weight: .bold))
                        
                        Text("Hosted by \(creatorName)")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Avatar stack placeholder
                    HStack(spacing: -8) {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .stroke(Color(.systemBackground), lineWidth: 2)
                            )
                        
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text("+0")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.secondary)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color(.systemBackground), lineWidth: 2)
                            )
                    }
                }
                
                Divider()
                    .background(Color(.systemGray5))
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("STARTS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .tracking(1)
                        
                        Text(formatStartDate(startDate))
                            .font(.system(size: 14, weight: .semibold))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("DURATION")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .tracking(1)
                        
                        Text("\(duration) Days")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
            }
            .padding(20)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
    }
    
    private func formatStartDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            return date.formatted(style: .medium)
        }
    }
}

// MARK: - Text Field Style

struct CreateChallengeTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .cornerRadius(999)
            .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Duration Selector

struct DurationSelectorView: View {
    @Binding var selectedDuration: CreateChallengeViewModel.ChallengeDuration
    let onSelect: (CreateChallengeViewModel.ChallengeDuration) -> Void
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("How long?")
                    .font(.system(size: 16, weight: .bold))
                
                Spacer()
                
                Button(action: {
                    onSelect(.custom)
                }) {
                    Text("Custom")
                        .font(.system(size: 14, weight: selectedDuration == .custom ? .bold : .semibold))
                        .foregroundColor(selectedDuration == .custom ? .black : primaryYellow)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedDuration == .custom ? primaryYellow : Color.clear
                        )
                        .cornerRadius(8)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CreateChallengeViewModel.ChallengeDuration.allCases.filter { $0 != .custom }, id: \.self) { duration in
                        DurationButton(
                            title: duration.displayName,
                            isSelected: selectedDuration == duration,
                            action: {
                                onSelect(duration)
                            }
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

struct DurationButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .black : .primary)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    isSelected ? primaryYellow : Color(.systemBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 999)
                        .stroke(isSelected ? Color.clear : Color(.systemGray4), lineWidth: 1)
                )
                .cornerRadius(999)
                .shadow(
                    color: isSelected ? primaryYellow.opacity(0.2) : Color.clear,
                    radius: isSelected ? 8 : 0,
                    x: 0,
                    y: isSelected ? 4 : 0
                )
        }
    }
}

// MARK: - Start Date Selector

struct StartDateSelectorView: View {
    @Binding var startDateMode: CreateChallengeViewModel.StartDateMode
    let onSelectMode: (CreateChallengeViewModel.StartDateMode) -> Void
    let onPickDate: () -> Void
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("When does it start?")
                .font(.system(size: 16, weight: .bold))
            
            HStack(spacing: 12) {
                StartDateButton(
                    icon: "calendar.badge.clock",
                    title: "Start Today",
                    subtitle: "Ready, set, go!",
                    isSelected: startDateMode == .today,
                    action: {
                        onSelectMode(.today)
                    }
                )
                
                StartDateButton(
                    icon: "calendar",
                    title: "Pick Date",
                    subtitle: "Schedule for later",
                    isSelected: startDateMode == .pickDate,
                    action: {
                        onSelectMode(.pickDate)
                        onPickDate()
                    }
                )
            }
        }
    }
}

struct StartDateButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .black : .secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isSelected ? .black : .primary)
                    
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(isSelected ? .black.opacity(0.8) : .secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                isSelected ? primaryYellow : Color(.systemBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Color(.systemGray4), lineWidth: 1)
            )
            .cornerRadius(16)
        }
    }
}

// MARK: - Invite Section

struct InviteSectionView: View {
    @Binding var selectedParticipants: [String]
    let friends: [User] // Friends from FriendsService (for backward compatibility)
    @Binding var searchText: String
    @Binding var isFriendsOnly: Bool
    
    @StateObject private var friendsLoader = FriendsLoaderViewModel()
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    // Use friends from Supabase if available, otherwise fallback to passed friends
    var availableFriends: [User] {
        if !friendsLoader.friends.isEmpty {
            return friendsLoader.friends
        }
        return friends
    }
    
    var filteredFriends: [User] {
        let friends: [User]
        if searchText.isEmpty {
            friends = availableFriends
        } else {
            friends = availableFriends.filter { friend in
                friend.displayName.localizedCaseInsensitiveContains(searchText) ||
                friend.username.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Friends are already shown first since we're loading from Supabase friends table
        // If isFriendsOnly is enabled, we could filter to only show friends here
        // For now, we show all friends (they're already prioritized)
        return friends
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Who's playing?")
                    .font(.system(size: 16, weight: .bold))
                
                Spacer()
                
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16))
                        Text("Share Link")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(primaryYellow)
                }
            }
            
            // Friends Only Toggle
            FriendsOnlyToggleView(isFriendsOnly: $isFriendsOnly)
                .padding(.vertical, 8)
            
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .padding(.leading, 16)
                
                TextField("Search friends or contacts...", text: $searchText)
                    .textFieldStyle(.plain)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    .autocorrectionDisabled(true)
            }
            .padding(.vertical, 14)
            .background(Color(.systemBackground))
            .cornerRadius(999)
            .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
            
            // Friend avatars
            if friendsLoader.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading friends...")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else if filteredFriends.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text(availableFriends.isEmpty ? "No friends yet" : "No friends found")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    if availableFriends.isEmpty {
                        Text("Add friends to invite them to challenges")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(filteredFriends) { friend in
                            FriendAvatarButton(
                                friend: friend,
                                isSelected: selectedParticipants.contains(friend.id),
                                onTap: {
                                    toggleFriendSelection(friendId: friend.id)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 16)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray5)),
            alignment: .top
        )
        .onAppear {
            friendsLoader.loadFriends()
        }
    }
    
    private func toggleFriendSelection(friendId: String) {
        if selectedParticipants.contains(friendId) {
            selectedParticipants.removeAll { $0 == friendId }
        } else {
            selectedParticipants.append(friendId)
        }
    }
}

struct FriendAvatarButton: View {
    let friend: User
    let isSelected: Bool
    let onTap: () -> Void
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    AvatarView(
                        displayName: friend.displayName,
                        avatarURL: friend.avatarURL,
                        size: 56
                    )
                    .overlay(
                        Circle()
                            .stroke(isSelected ? primaryYellow : Color.clear, lineWidth: 2)
                    )
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                            .padding(4)
                            .background(primaryYellow)
                            .clipShape(Circle())
                            .offset(x: 20, y: -20)
                    }
                }
                
                Text(friend.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .frame(width: 60)
            }
            .opacity(isSelected ? 1.0 : 0.7)
        }
    }
}

// MARK: - Custom Duration Sheet

struct CustomDurationSheet: View {
    @Binding var customDays: Int
    let onSave: (Int) -> Void
    let onCancel: () -> Void
    
    @State private var daysText: String
    @State private var errorMessage: String?
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    init(customDays: Binding<Int>, onSave: @escaping (Int) -> Void, onCancel: @escaping () -> Void) {
        self._customDays = customDays
        self.onSave = onSave
        self.onCancel = onCancel
        _daysText = State(initialValue: "\(customDays.wrappedValue)")
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Custom Duration")
                        .font(.system(size: 24, weight: .bold))
                    
                    Text("Enter the number of days for your challenge")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)
                
                // Input Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Number of Days")
                        .font(.system(size: 16, weight: .semibold))
                    
                    HStack {
                        TextField("Enter days", text: $daysText)
                            .keyboardType(.numberPad)
                            .textFieldStyle(CustomDurationTextFieldStyle())
                            .onChange(of: daysText) { oldValue, newValue in
                                // Filter out non-numeric characters
                                let filtered = newValue.filter { $0.isNumber }
                                if filtered != newValue {
                                    daysText = filtered
                                }
                                errorMessage = nil
                            }
                        
                        Text("days")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    if let errorMessage = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 14))
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                        }
                        .padding(.top, 4)
                    }
                    
                    // Quick select buttons
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick Select")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            QuickSelectButton(title: "7", days: 7, selectedText: $daysText)
                            QuickSelectButton(title: "14", days: 14, selectedText: $daysText)
                            QuickSelectButton(title: "30", days: 30, selectedText: $daysText)
                            QuickSelectButton(title: "60", days: 60, selectedText: $daysText)
                            QuickSelectButton(title: "90", days: 90, selectedText: $daysText)
                        }
                    }
                    .padding(.top, 16)
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveDays()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
        .dismissKeyboardOnTap()
    }
    
    private func saveDays() {
        guard let days = Int(daysText), days > 0 else {
            errorMessage = "Please enter a valid number of days"
            return
        }
        
        guard days <= 365 else {
            errorMessage = "Maximum duration is 365 days"
            return
        }
        
        onSave(days)
    }
    
}

struct QuickSelectButton: View {
    let title: String
    let days: Int
    @Binding var selectedText: String
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        Button(action: {
            selectedText = "\(days)"
        }) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(selectedText == "\(days)" ? .black : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    selectedText == "\(days)" ? primaryYellow : Color(.systemGray6)
                )
                .cornerRadius(8)
        }
    }
}

struct CustomDurationTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 32, weight: .bold))
            .multilineTextAlignment(.center)
            .keyboardType(.numberPad)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(.systemGray6))
            .cornerRadius(16)
    }
}

// MARK: - Sticky Footer Button

struct StickyFooterButton: View {
    let title: String
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.black.opacity(0.05))
            
            Button(action: action) {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Text(title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                        
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.black)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isEnabled ? primaryYellow : Color(.systemGray4))
                .cornerRadius(999)
                .shadow(
                    color: isEnabled ? primaryYellow.opacity(0.25) : Color.clear,
                    radius: 16,
                    x: 0,
                    y: 4
                )
            }
            .disabled(!isEnabled || isLoading)
            .padding()
            .background(
                Color(.systemBackground)
                    .opacity(0.9)
                    .background(.ultraThinMaterial)
            )
        }
    }
}

