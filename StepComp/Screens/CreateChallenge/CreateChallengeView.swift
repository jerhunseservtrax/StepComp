//
//  CreateChallengeView.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine
import PhotosUI

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
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    
    init(sessionViewModel: SessionViewModel) {
        self.sessionViewModel = sessionViewModel
        let userId = sessionViewModel.currentUser?.id ?? ""
        // Initialize with placeholder - will be updated in onAppear
        _viewModel = StateObject(
            wrappedValue: CreateChallengeViewModel(
                challengeService: ChallengeService.shared,
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
                    
                    // Challenge Image Upload Section
                    ChallengeImageUploadView(
                        selectedPhotoItem: $selectedPhotoItem,
                        selectedImageData: $viewModel.challengeImageData,
                        challengeName: viewModel.name.isEmpty ? "Morning Sprinters" : viewModel.name
                    )
                    .padding(.horizontal)
                    .padding(.top, 16)
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
                        
                        // Privacy Setting (moved to top after name)
                        PrivacyToggleView(isPrivate: $viewModel.isPrivate)
                            .padding(.horizontal)
                        
                        // Category Selection (only for public challenges)
                        if !viewModel.isPrivate {
                            CategorySelectorView(selectedCategory: $viewModel.selectedCategory)
                                .padding(.horizontal)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
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
                        
                        // Rules Section
                        RulesSelectorView(selectedRules: $viewModel.selectedRules)
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
                        .background(FitCompColors.primary)
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
                        .foregroundColor(selectedDuration == .custom ? .black : FitCompColors.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedDuration == .custom ? FitCompColors.primary : Color.clear
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
    
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .black : .primary)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    isSelected ? FitCompColors.primary : Color(.systemBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 999)
                        .stroke(isSelected ? Color.clear : Color(.systemGray4), lineWidth: 1)
                )
                .cornerRadius(999)
                .shadow(
                    color: isSelected ? FitCompColors.primary.opacity(0.2) : Color.clear,
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
                isSelected ? FitCompColors.primary : Color(.systemBackground)
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
    @State private var debouncedSearchText: String = ""
    @State private var searchTask: Task<Void, Never>?
    
    // Use friends from Supabase if available, otherwise fallback to passed friends
    var availableFriends: [User] {
        if !friendsLoader.friends.isEmpty {
            return friendsLoader.friends
        }
        return friends
    }
    
    var filteredFriends: [User] {
        let query = debouncedSearchText.trimmingCharacters(in: .whitespaces).lowercased()
        
        guard !query.isEmpty else {
            return availableFriends
        }
        
        // Search across multiple fields: firstName, lastName, username, and displayName
        return availableFriends.filter { friend in
            // Search in username
            friend.username.lowercased().contains(query) ||
            // Search in firstName
            friend.firstName.lowercased().contains(query) ||
            // Search in lastName
            friend.lastName.lowercased().contains(query) ||
            // Search in full displayName
            friend.displayName.lowercased().contains(query) ||
            // Search in email (if available)
            (friend.email?.lowercased().contains(query) ?? false)
        }
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
                    .foregroundColor(FitCompColors.primary)
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
                
                TextField("Search friends...", text: $searchText)
                    .textFieldStyle(.plain)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    .autocorrectionDisabled(true)
                    .onChange(of: searchText) { _, newValue in
                        // Cancel previous search task
                        searchTask?.cancel()
                        
                        // Debounce search input (300ms delay)
                        searchTask = Task {
                            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
                            
                            if !Task.isCancelled {
                                await MainActor.run {
                                    debouncedSearchText = newValue
                                }
                            }
                        }
                    }
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
            // Reload friends when view appears to ensure we have the latest data
            friendsLoader.loadFriends()
            // Initialize debounced search text
            debouncedSearchText = searchText
        }
        .onChange(of: friendsLoader.friends) { _, newFriends in
            // Debug: Log when friends list changes
            print("🔄 [InviteSection] Friends list updated: \(newFriends.count) friends")
        }
        .onDisappear {
            // Cancel any pending search task
            searchTask?.cancel()
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
                            .stroke(isSelected ? FitCompColors.primary : Color.clear, lineWidth: 2)
                    )
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                            .padding(4)
                            .background(FitCompColors.primary)
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
                            DurationQuickSelectButton(title: "7", days: 7, selectedText: $daysText)
                            DurationQuickSelectButton(title: "14", days: 14, selectedText: $daysText)
                            DurationQuickSelectButton(title: "30", days: 30, selectedText: $daysText)
                            DurationQuickSelectButton(title: "60", days: 60, selectedText: $daysText)
                            DurationQuickSelectButton(title: "90", days: 90, selectedText: $daysText)
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

struct DurationQuickSelectButton: View {
    let title: String
    let days: Int
    @Binding var selectedText: String
    
    
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
                    selectedText == "\(days)" ? FitCompColors.primary : Color(.systemGray6)
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
                .background(isEnabled ? FitCompColors.primary : Color(.systemGray4))
                .cornerRadius(999)
                .shadow(
                    color: isEnabled ? FitCompColors.primary.opacity(0.25) : Color.clear,
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

// MARK: - Category Selector

struct CategorySelectorView: View {
    @Binding var selectedCategory: Challenge.ChallengeCategory?
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "tag.fill")
                    .font(.system(size: 16))
                    .foregroundColor(FitCompColors.primary)
                
                Text("Choose a Category")
                    .font(.system(size: 16, weight: .bold))
                
                Spacer()
                
                Text("Required for public")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Challenge.ChallengeCategory.allCases, id: \.self) { category in
                        CreateChallengeCategoryButton(
                            category: category,
                            isSelected: selectedCategory == category,
                            action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedCategory = category
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(16)
    }
}

struct CreateChallengeCategoryButton: View {
    let category: Challenge.ChallengeCategory
    let isSelected: Bool
    let action: () -> Void
    
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(isSelected ? .black : .secondary)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(isSelected ? FitCompColors.primary : Color(.systemBackground))
                    )
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.clear : Color(.systemGray4), lineWidth: 1)
                    )
                
                VStack(spacing: 2) {
                    Text(category.displayName)
                        .font(.system(size: 13, weight: isSelected ? .bold : .semibold))
                        .foregroundColor(isSelected ? .primary : .secondary)
                    
                    Text(category.description)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                .frame(width: 100)
            }
            .padding(12)
            .background(
                isSelected ? Color(.systemBackground) : Color.clear
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? FitCompColors.primary : Color.clear, lineWidth: 2)
            )
            .shadow(
                color: isSelected ? FitCompColors.primary.opacity(0.2) : Color.clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: isSelected ? 4 : 0
            )
        }
    }
}

// MARK: - Rules Selector View

struct RulesSelectorView: View {
    @Binding var selectedRules: Set<ChallengeRule>
    @State private var isExpanded: Bool = false
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "scroll.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.orange)
                    
                    Text("Challenge Rules")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Selected count badge
                    if !selectedRules.isEmpty {
                        Text("\(selectedRules.count) selected")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(FitCompColors.primary)
                            .cornerRadius(999)
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            
            // Optional badge
            Text("Optional • Set fair play guidelines")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 20) {
                    // Data Source Rules
                    RuleCategorySection(
                        title: "Data Sources",
                        icon: "checkmark.shield.fill",
                        rules: ChallengeRule.dataSourceRules,
                        selectedRules: $selectedRules
                    )
                    
                    // Daily Cap Rules
                    RuleCategorySection(
                        title: "Daily Step Limits",
                        icon: "gauge.medium",
                        rules: ChallengeRule.dailyCapRules,
                        selectedRules: $selectedRules,
                        isMutuallyExclusive: true
                    )
                    
                    // Sync Rules
                    RuleCategorySection(
                        title: "Sync Requirements",
                        icon: "arrow.triangle.2.circlepath",
                        rules: ChallengeRule.syncRules,
                        selectedRules: $selectedRules,
                        isMutuallyExclusive: true
                    )
                    
                    // Participation Rules
                    RuleCategorySection(
                        title: "Participation",
                        icon: "person.2.fill",
                        rules: ChallengeRule.participationRules,
                        selectedRules: $selectedRules
                    )
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Quick preview of selected rules when collapsed
            if !isExpanded && !selectedRules.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(selectedRules), id: \.id) { rule in
                            HStack(spacing: 6) {
                                Image(systemName: rule.icon)
                                    .font(.system(size: 10))
                                
                                Text(rule.title)
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(rule.color)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(rule.color.opacity(0.12))
                            .cornerRadius(999)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(16)
    }
}

// MARK: - Rule Category Section

struct RuleCategorySection: View {
    let title: String
    let icon: String
    let rules: [ChallengeRule]
    @Binding var selectedRules: Set<ChallengeRule>
    var isMutuallyExclusive: Bool = false
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                
                if isMutuallyExclusive {
                    Text("(pick one)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
            
            // Rules grid
            LazyVGrid(columns: [GridItem(.flexible())], spacing: 8) {
                ForEach(rules) { rule in
                    RuleToggleButton(
                        rule: rule,
                        isSelected: selectedRules.contains(rule),
                        action: {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                toggleRule(rule)
                            }
                        }
                    )
                }
            }
        }
    }
    
    private func toggleRule(_ rule: ChallengeRule) {
        if selectedRules.contains(rule) {
            selectedRules.remove(rule)
        } else {
            if isMutuallyExclusive {
                // Remove other rules in this category first
                for existingRule in rules {
                    selectedRules.remove(existingRule)
                }
            }
            selectedRules.insert(rule)
        }
    }
}

// MARK: - Rule Toggle Button

struct RuleToggleButton: View {
    let rule: ChallengeRule
    let isSelected: Bool
    let action: () -> Void
    
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? rule.color : rule.color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: rule.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isSelected ? .white : rule.color)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(rule.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(rule.subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? rule.color : Color(.systemGray4), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    
                    if isSelected {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(rule.color)
                            .frame(width: 22, height: 22)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(12)
            .background(
                isSelected ? rule.color.opacity(0.08) : Color(.systemBackground)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? rule.color.opacity(0.3) : Color(.systemGray5), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Challenge Image Upload View

struct ChallengeImageUploadView: View {
    @Binding var selectedPhotoItem: PhotosPickerItem?
    @Binding var selectedImageData: Data?
    let challengeName: String
    
    @State private var isLoadingImage = false
    
    
    var body: some View {
        VStack(spacing: 0) {
            // Image Preview Area
            ZStack {
                // Background - either selected image or placeholder
                if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                    // Selected image
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .overlay(
                            // Gradient overlay for text readability
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.5),
                                    Color.black.opacity(0.2),
                                    Color.clear
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                } else {
                    // Placeholder gradient background
                    ZStack {
                        LinearGradient(
                            colors: [
                                FitCompColors.primary.opacity(0.3),
                                FitCompColors.primary.opacity(0.1),
                                Color(.systemGray6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        // Decorative pattern
                        GeometryReader { geo in
                            ZStack {
                                ForEach(0..<6, id: \.self) { index in
                                    Circle()
                                        .fill(FitCompColors.primary.opacity(0.1))
                                        .frame(width: CGFloat.random(in: 40...80))
                                        .offset(
                                            x: CGFloat.random(in: -geo.size.width/2...geo.size.width/2),
                                            y: CGFloat.random(in: -50...50)
                                        )
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(height: 200)
                }
                
                // Upload Button Overlay
                VStack(spacing: 12) {
                    if isLoadingImage {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.white)
                    } else {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.95))
                                        .frame(width: 60, height: 60)
                                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                                    
                                    Image(systemName: selectedImageData == nil ? "photo.badge.plus" : "photo.badge.arrow.down")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                
                                Text(selectedImageData == nil ? "Add Cover Image" : "Change Image")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(selectedImageData == nil ? .primary : .white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(selectedImageData == nil ? Color.white.opacity(0.95) : Color.black.opacity(0.5))
                                    )
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                        }
                    }
                }
                
                // Challenge name preview (when image is selected)
                if selectedImageData != nil {
                    VStack {
                        Spacer()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(challengeName)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                                
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 12))
                                    Text("Challenge Preview")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                        }
                        .padding(16)
                    }
                }
                
                // Remove button (when image is selected)
                if selectedImageData != nil {
                    VStack {
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    selectedImageData = nil
                                    selectedPhotoItem = nil
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.primary)
                                    .frame(width: 28, height: 28)
                                    .background(Color.white.opacity(0.95))
                                    .clipShape(Circle())
                                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                            }
                            .padding(12)
                        }
                        
                        Spacer()
                    }
                }
            }
            .frame(height: 200)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        selectedImageData == nil ? 
                            Color(.systemGray4).opacity(0.5) : 
                            Color.clear,
                        style: StrokeStyle(lineWidth: 2, dash: selectedImageData == nil ? [8, 6] : [])
                    )
            )
            
            // Helper text
            if selectedImageData == nil {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text("Optional • This image will be the background of your challenge")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 12)
            }
        }
        .onChange(of: selectedPhotoItem) { _, newValue in
            Task {
                await loadSelectedImage(from: newValue)
            }
        }
    }
    
    private func loadSelectedImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        isLoadingImage = true
        defer { isLoadingImage = false }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                // Compress image if needed
                if let uiImage = UIImage(data: data) {
                    // Resize and compress to reasonable size (max 1MB)
                    let maxSize: CGFloat = 1200
                    let scale = min(maxSize / uiImage.size.width, maxSize / uiImage.size.height, 1.0)
                    let newSize = CGSize(
                        width: uiImage.size.width * scale,
                        height: uiImage.size.height * scale
                    )
                    
                    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                    uiImage.draw(in: CGRect(origin: .zero, size: newSize))
                    let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    
                    if let compressedData = resizedImage?.jpegData(compressionQuality: 0.7) {
                        await MainActor.run {
                            withAnimation {
                                selectedImageData = compressedData
                            }
                        }
                    } else {
                        await MainActor.run {
                            withAnimation {
                                selectedImageData = data
                            }
                        }
                    }
                }
            }
        } catch {
            print("⚠️ Error loading image: \(error.localizedDescription)")
        }
    }
}

// MARK: - Image Style Presets

struct ImageStylePresetsView: View {
    @Binding var selectedImageData: Data?
    
    
    let presets: [(name: String, colors: [Color], icon: String)] = [
        ("Sunset", [Color.orange, Color.pink, Color.purple], "sun.horizon.fill"),
        ("Ocean", [Color.cyan, Color.blue, Color.indigo], "water.waves"),
        ("Forest", [Color.green, Color.mint, Color.teal], "leaf.fill"),
        ("Energy", [Color.yellow, Color.orange, Color.red], "bolt.fill"),
        ("Night", [Color.purple, Color.indigo, Color.black], "moon.stars.fill"),
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Or choose a style")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(presets, id: \.name) { preset in
                        Button(action: {
                            // Generate gradient image
                            generateGradientImage(colors: preset.colors)
                        }) {
                            ZStack {
                                LinearGradient(
                                    colors: preset.colors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .frame(width: 64, height: 64)
                                .cornerRadius(12)
                                
                                Image(systemName: preset.icon)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func generateGradientImage(colors: [Color]) {
        let size = CGSize(width: 800, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            let cgContext = context.cgContext
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            
            let uiColors = colors.map { UIColor($0) }
            let cgColors = uiColors.map { $0.cgColor } as CFArray
            
            if let gradient = CGGradient(
                colorsSpace: colorSpace,
                colors: cgColors,
                locations: nil
            ) {
                cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: size.width, y: size.height),
                    options: []
                )
            }
        }
        
        if let data = image.jpegData(compressionQuality: 0.8) {
            withAnimation {
                selectedImageData = data
            }
        }
    }
}

