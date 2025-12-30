//
//  ProfileView.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine

struct ProfileView: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    @StateObject private var viewModel: ProfileViewModel
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var challengeService: ChallengeService
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var healthKitService: HealthKitService
    
    @State private var showingEditProfile = false
    @State private var showingEditAccount = false
    @State private var showingLogoutAlert = false
    @State private var showingDeleteAlert = false
    @State private var isEditing = false
    @State private var showingAddFriends = false
    @State private var showEditAccountInfoCard = false
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    init(sessionViewModel: SessionViewModel) {
        self.sessionViewModel = sessionViewModel
        let user = sessionViewModel.currentUser ?? User(username: "user", firstName: "User", lastName: "")
        _viewModel = StateObject(
            wrappedValue: ProfileViewModel(
                user: user,
                challengeService: ChallengeService(),
                authService: AuthService()
            )
        )
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Profile Header Section
                    ProfileHeaderSection(
                        user: viewModel.user,
                        level: viewModel.level,
                        badge: viewModel.badge,
                        memberSince: viewModel.memberSince,
                        isEditing: $isEditing,
                        onEditAvatar: {
                            showingEditProfile = true
                        }
                    )
                    .padding(.top, 24)
                    .padding(.bottom, 24)
                    
                    // Stats Cards
                    StatsCardsSection(
                        totalSteps: viewModel.totalSteps,
                        calories: viewModel.caloriesBurned,
                        activeTime: viewModel.activeTimeHours
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                    
                    // Activity Section
                    ActivitySection(
                        todaySteps: viewModel.todaySteps,
                        selectedPeriod: $viewModel.selectedActivityPeriod,
                        weeklyData: viewModel.weeklyActivityData,
                        monthlyData: viewModel.monthlyActivityData
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                    
                    // Badges Section
                    BadgesSection()
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                    
                    // Friends Section
                    ProfileFriendsSection(onAddFriends: {
                        showingAddFriends = true
                    })
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                    
                    // Edit Account Info Section (only show after saving changes)
                    if showEditAccountInfoCard {
                        EditAccountInfoSection(
                            user: viewModel.user,
                            height: $viewModel.height,
                            weight: $viewModel.weight,
                            onSave: { height, weight in
                                viewModel.updateAccountInfo(height: height, weight: weight)
                                // Hide the card after saving
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    showEditAccountInfoCard = false
                                }
                            },
                            onDismiss: {
                                showEditAccountInfoCard = false
                            }
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Privacy & Settings Section
                    PrivacySettingsSection(
                        isPublicProfile: $viewModel.isPublicProfile,
                        shareActivity: $viewModel.shareActivity,
                        dailyReminders: $viewModel.dailyReminders
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                    
                    // Account Actions
                    AccountActionsSection(
                        onLogOut: {
                            showingLogoutAlert = true
                        },
                        onDeleteData: {
                            showingDeleteAlert = true
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100) // Space for bottom nav
                }
            }
            .background(Color(red: 0.973, green: 0.973, blue: 0.961))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Profile")
                        .font(.system(size: 18, weight: .bold))
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showingEditAccount = true
                    }) {
                        Text("Edit")
                            .foregroundColor(primaryYellow)
                            .font(.system(size: 16, weight: .bold))
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(
                user: viewModel.user,
                onSave: { firstName, lastName, avatarURL in
                    viewModel.updateProfile(firstName: firstName, lastName: lastName, avatarURL: avatarURL)
                }
            )
        }
        .sheet(isPresented: $showingEditAccount) {
            EditAccountInfoSheet(
                user: viewModel.user,
                height: $viewModel.height,
                weight: $viewModel.weight,
                onSave: { height, weight in
                    viewModel.updateAccountInfo(height: height, weight: weight)
                    showingEditAccount = false
                    // Show the card after saving
                    showEditAccountInfoCard = true
                }
            )
        }
        .alert("Log Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    await sessionViewModel.signOut()
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete All Data", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // TODO: Implement delete all data
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
        .sheet(isPresented: $showingAddFriends) {
            AddFriendsView(sessionViewModel: sessionViewModel)
        }
        .onAppear {
            viewModel.updateServices(challengeService: challengeService, authService: authService)
            viewModel.setThemeManager(themeManager)
            viewModel.healthKitEnabled = healthKitService.isAuthorized
        }
    }
}

// MARK: - Profile Header Section

struct ProfileHeaderSection: View {
    let user: User
    let level: Int
    let badge: String
    let memberSince: Int
    @Binding var isEditing: Bool
    let onEditAvatar: () -> Void
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar with edit button
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: URL(string: user.avatarURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Text(user.initials)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 112, height: 112)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color(red: 0.176, green: 0.133, blue: 0.059), lineWidth: 4)
                )
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
                
                Button(action: onEditAvatar) {
                    Image(systemName: "pencil")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(red: 0.176, green: 0.133, blue: 0.059))
                        .frame(width: 28, height: 28)
                        .background(primaryYellow)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color(red: 0.176, green: 0.133, blue: 0.059), lineWidth: 4)
                        )
                }
                .offset(x: -4, y: -4)
            }
            
            // Name
            Text(user.displayName)
                .font(.system(size: 24, weight: .black))
                .tracking(-0.5)
            
            // Level and Badge
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .foregroundColor(primaryYellow)
                    .font(.system(size: 20))
                Text("Level \(level) • \(badge)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            // Member Since
            Text("MEMBER SINCE \(memberSince)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
                .tracking(1.5)
        }
    }
}

// MARK: - Stats Cards Section

struct StatsCardsSection: View {
    let totalSteps: Int
    let calories: Int
    let activeTime: Int
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        HStack(spacing: 12) {
            StatCard(
                icon: "footprint",
                value: formatSteps(totalSteps),
                label: "Total Steps",
                color: primaryYellow
            )
            
            StatCard(
                icon: "flame.fill",
                value: formatNumber(calories),
                label: "Calories",
                color: primaryYellow
            )
            
            StatCard(
                icon: "timer",
                value: "\(activeTime)h",
                label: "Active Time",
                color: primaryYellow
            )
        }
    }
    
    private func formatSteps(_ steps: Int) -> String {
        if steps >= 1000 {
            return String(format: "%.1fk", Double(steps) / 1000.0)
        }
        return "\(steps)"
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(white: 1.0, opacity: 0.0))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(white: 0.0, opacity: 0.05))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(white: 1.0, opacity: 0.05), lineWidth: 1)
        )
    }
}

// MARK: - Activity Section

struct ActivitySection: View {
    let todaySteps: Int
    @Binding var selectedPeriod: ProfileViewModel.ActivityPeriod
    let weeklyData: [Int]
    let monthlyData: [Int]
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var currentData: [Int] {
        selectedPeriod == .week ? weeklyData : monthlyData
    }
    
    var maxValue: Int {
        currentData.max() ?? 10000
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Activity")
                        .font(.system(size: 18, weight: .bold))
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(formatSteps(todaySteps))")
                            .font(.system(size: 28, weight: .black))
                            .tracking(-0.5)
                        Text("steps today")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Period Toggle
                HStack(spacing: 4) {
                    Button(action: {
                        selectedPeriod = .week
                    }) {
                        Text("Week")
                            .font(.system(size: 12, weight: selectedPeriod == .week ? .bold : .medium))
                            .foregroundColor(selectedPeriod == .week ? .black : .gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(selectedPeriod == .week ? Color.white : Color.clear)
                            )
                    }
                    
                    Button(action: {
                        selectedPeriod = .month
                    }) {
                        Text("Month")
                            .font(.system(size: 12, weight: selectedPeriod == .month ? .bold : .medium))
                            .foregroundColor(selectedPeriod == .month ? .black : .gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(selectedPeriod == .month ? Color.white : Color.clear)
                            )
                    }
                }
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(white: 0.0, opacity: 0.1))
                )
                .frame(width: 100, height: 36)
            }
            
            // Bar Chart
            if selectedPeriod == .week {
                WeekBarChart(data: weeklyData, maxValue: maxValue)
            } else {
                MonthBarChart(data: monthlyData, maxValue: maxValue)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 1.0, opacity: 0.0))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(white: 0.0, opacity: 0.05))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(white: 1.0, opacity: 0.05), lineWidth: 1)
        )
    }
    
    private func formatSteps(_ steps: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }
}

struct WeekBarChart: View {
    let data: [Int]
    let maxValue: Int
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    private let days = ["M", "T", "W", "T", "F", "S", "S"]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(0..<min(data.count, 7), id: \.self) { index in
                VStack(spacing: 8) {
                    GeometryReader { geometry in
                        let height = maxValue > 0 ? CGFloat(data[index]) / CGFloat(maxValue) : 0.0
                        let isHighlighted = index == 4 // Friday
                        
                        ZStack(alignment: .bottom) {
                            // Background bar
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(white: 1.0, opacity: 0.1))
                                .frame(height: geometry.size.height)
                            
                            // Data bar
                            RoundedRectangle(cornerRadius: 2)
                                .fill(isHighlighted ? primaryYellow : primaryYellow.opacity(0.3))
                                .frame(height: geometry.size.height * height)
                                .shadow(
                                    color: isHighlighted ? primaryYellow.opacity(0.3) : .clear,
                                    radius: isHighlighted ? 8 : 0
                                )
                        }
                    }
                    .frame(height: 128)
                    
                    Text(days[index])
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(index == 4 ? primaryYellow : .gray)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct MonthBarChart: View {
    let data: [Int]
    let maxValue: Int
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<min(data.count, 30), id: \.self) { index in
                    GeometryReader { geometry in
                        let height = maxValue > 0 ? CGFloat(data[index]) / CGFloat(maxValue) : 0.0
                        
                        RoundedRectangle(cornerRadius: 1)
                            .fill(primaryYellow.opacity(0.3))
                            .frame(height: geometry.size.height * height)
                    }
                    .frame(width: 8, height: 128)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Badges Section

struct BadgesSection: View {
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Badges")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                Button(action: {}) {
                    Text("See All")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(primaryYellow)
                }
            }
            
            HStack(spacing: 16) {
                BadgeItem(
                    icon: "trophy.fill",
                    title: "First 10k",
                    color: primaryYellow,
                    isUnlocked: true
                )
                
                BadgeItem(
                    icon: "flame.fill",
                    title: "7 Day Streak",
                    color: .blue,
                    isUnlocked: true
                )
                
                BadgeItem(
                    icon: "figure.hiking",
                    title: "Climber",
                    color: .purple,
                    isUnlocked: true
                )
                
                BadgeItem(
                    icon: "lock.fill",
                    title: "Marathon",
                    color: .gray,
                    isUnlocked: false
                )
            }
        }
    }
}

struct BadgeItem: View {
    let icon: String
    let title: String
    let color: Color
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        isUnlocked ?
                        LinearGradient(
                            colors: [color, color.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color(white: 0.0, opacity: 0.1), Color(white: 0.0, opacity: 0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .overlay(
                        Circle()
                            .stroke(
                                isUnlocked ? Color.clear : Color.gray.opacity(0.5),
                                style: StrokeStyle(lineWidth: 2, dash: [4, 4])
                            )
                    )
                    .shadow(
                        color: isUnlocked ? color.opacity(0.2) : .clear,
                        radius: 8
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isUnlocked ? (color == primaryYellow ? .black : .white) : .gray)
            }
            
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 24)
        }
        .frame(maxWidth: .infinity)
        .opacity(isUnlocked ? 1.0 : 0.4)
    }
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
}

// MARK: - Edit Account Info Section

struct EditAccountInfoSection: View {
    let user: User
    @Binding var height: Int
    @Binding var weight: Int
    let onSave: (Int, Int) -> Void
    let onDismiss: () -> Void
    
    @State private var editingHeight: Int = 175
    @State private var editingWeight: Int = 68
    @State private var showingPassword = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Edit Account Info")
                    .font(.system(size: 18, weight: .bold))
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(spacing: 16) {
                // Full Name
                FormField(
                    label: "Full Name",
                    icon: "person.fill",
                    value: user.displayName,
                    isEditable: false
                )
                
                // Email
                FormField(
                    label: "Email Address",
                    icon: "envelope.fill",
                    value: user.email ?? "",
                    isEditable: false
                )
                
                // Height and Weight (Editable)
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Height (cm)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        TextField("175", value: $editingHeight, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .onAppear {
                                editingHeight = height
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight (kg)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        TextField("70", value: $editingWeight, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .onAppear {
                                editingWeight = weight
                            }
                    }
                }
                
                // Password
                HStack {
                    FormField(
                        label: "Password",
                        icon: "lock.fill",
                        value: "••••••••",
                        isEditable: false
                    )
                    
                    Button(action: {
                        showingPassword.toggle()
                    }) {
                        Image(systemName: showingPassword ? "eye.fill" : "eye.slash.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                    }
                }
                
                // Save Changes Button
                Button(action: {
                    height = editingHeight
                    weight = editingWeight
                    onSave(editingHeight, editingWeight)
                }) {
                    Text("SAVE CHANGES")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(primaryYellow)
                        .cornerRadius(12)
                        .shadow(color: primaryYellow.opacity(0.5), radius: 10, x: 0, y: 4)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 1.0, opacity: 0.0))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(white: 0.0, opacity: 0.05))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(white: 1.0, opacity: 0.05), lineWidth: 1)
            )
        }
    }
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
}

struct FormField: View {
    let label: String
    let icon: String?
    let value: String
    let isEditable: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray)
                .tracking(0.5)
            
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(.gray)
                        .font(.system(size: 18))
                        .frame(width: 24)
                }
                
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(white: 0.0, opacity: 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(white: 1.0, opacity: 0.1), lineWidth: 1)
            )
        }
    }
}

// MARK: - Edit Account Info Sheet

struct EditAccountInfoSheet: View {
    let user: User
    @Binding var height: Int
    @Binding var weight: Int
    let onSave: (Int, Int) -> Void
    
    @State private var editingHeight: String = ""
    @State private var editingWeight: String = ""
    @State private var showingPassword = false
    @Environment(\.dismiss) var dismiss
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Full Name", text: .constant(user.displayName))
                        .disabled(true)
                    
                    TextField("Email Address", text: .constant(user.email ?? ""))
                        .disabled(true)
                }
                
                Section {
                    HStack {
                        Text("Height (cm)")
                        Spacer()
                        TextField("", text: $editingHeight)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Weight (kg)")
                        Spacer()
                        TextField("", text: $editingWeight)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
                
                Section {
                    HStack {
                        Text("Password")
                        Spacer()
                        SecureField("", text: .constant(""))
                            .disabled(true)
                    }
                }
            }
            .navigationTitle("Edit Account Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        if let h = Int(editingHeight), let w = Int(editingWeight) {
                            onSave(h, w)
                        }
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .onAppear {
            editingHeight = "\(height)"
            editingWeight = "\(weight)"
        }
    }
}

// MARK: - Privacy Settings Section

struct PrivacySettingsSection: View {
    @Binding var isPublicProfile: Bool
    @Binding var shareActivity: Bool
    @Binding var dailyReminders: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Privacy & Settings")
                .font(.system(size: 18, weight: .bold))
            
            VStack(spacing: 0) {
                SettingToggleRow(
                    icon: "eye.fill",
                    title: "Public Profile",
                    color: .blue,
                    isOn: $isPublicProfile
                )
                
                Divider()
                    .background(Color(white: 1.0, opacity: 0.05))
                
                SettingToggleRow(
                    icon: "square.and.arrow.up.fill",
                    title: "Share Activity",
                    color: .green,
                    isOn: $shareActivity
                )
                
                Divider()
                    .background(Color(white: 1.0, opacity: 0.05))
                
                SettingToggleRow(
                    icon: "bell.fill",
                    title: "Daily Reminders",
                    color: .orange,
                    isOn: $dailyReminders
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 1.0, opacity: 0.0))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(white: 0.0, opacity: 0.05))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(white: 1.0, opacity: 0.05), lineWidth: 1)
            )
        }
    }
}

struct SettingToggleRow: View {
    let icon: String
    let title: String
    let color: Color
    @Binding var isOn: Bool
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16))
            }
            
            Text(title)
                .font(.system(size: 14, weight: .bold))
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(primaryYellow)
        }
        .padding(16)
    }
}

// MARK: - Account Actions Section

struct AccountActionsSection: View {
    let onLogOut: () -> Void
    let onDeleteData: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: onLogOut) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 20))
                    Text("Log Out")
                        .font(.system(size: 16, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(white: 1.0, opacity: 0.2), lineWidth: 1)
                )
            }
            
            Button(action: onDeleteData) {
                Text("Delete All Data")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    let user: User
    let onSave: (String, String, String?) -> Void
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var avatarURL: String?
    @Environment(\.dismiss) var dismiss
    
    init(user: User, onSave: @escaping (String, String, String?) -> Void) {
        self.user = user
        self.onSave = onSave
        _firstName = State(initialValue: user.firstName)
        _lastName = State(initialValue: user.lastName)
        _avatarURL = State(initialValue: user.avatarURL)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Avatar URL (optional)", text: Binding(
                        get: { avatarURL ?? "" },
                        set: { avatarURL = $0.isEmpty ? nil : $0 }
                    ))
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
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        onSave(firstName, lastName, avatarURL)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}

// MARK: - User Extension

extension User {
    var initials: String {
        let first = firstName.prefix(1).uppercased()
        let last = lastName.prefix(1).uppercased()
        return "\(first)\(last)"
    }
}
