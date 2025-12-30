//
//  SettingsView.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

struct SettingsView: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    @EnvironmentObject var healthKitService: HealthKitService
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showingSignOutAlert = false
    @State private var healthKitEnabled = true
    @State private var appleWatchSetup = false
    @State private var dailyRecap = true
    @State private var leaderboardAlerts = false
    @State private var motivationalNudges = true
    @State private var darkMode = false
    @State private var unitSystem: UnitSystem = .metric
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    enum UnitSystem {
        case metric
        case imperial
    }
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > 768 {
                // iPad/Desktop Layout with Sidebar
                HStack(spacing: 0) {
                    // Sidebar
                    SettingsSidebar(
                        user: sessionViewModel.currentUser,
                        totalSteps: sessionViewModel.currentUser?.totalSteps ?? 0,
                        currentStreak: 42
                    )
                    .frame(width: 320)
                    
                    // Main Content
                    SettingsMainContent(
                        healthKitEnabled: $healthKitEnabled,
                        appleWatchSetup: $appleWatchSetup,
                        dailyRecap: $dailyRecap,
                        leaderboardAlerts: $leaderboardAlerts,
                        motivationalNudges: $motivationalNudges,
                        darkMode: $darkMode,
                        unitSystem: $unitSystem,
                        sessionViewModel: sessionViewModel,
                        onSignOut: {
                            showingSignOutAlert = true
                        }
                    )
                }
            } else {
                // Mobile Layout
                VStack(spacing: 0) {
                    // Mobile Header
                    SettingsMobileHeader(onBack: { dismiss() })
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            // Profile Section (Mobile)
                            SettingsProfileSection(
                                user: sessionViewModel.currentUser,
                                totalSteps: sessionViewModel.currentUser?.totalSteps ?? 0,
                                currentStreak: 42
                            )
                            .padding()
                            
                            // Settings Cards
                            SettingsMainContent(
                                healthKitEnabled: $healthKitEnabled,
                                appleWatchSetup: $appleWatchSetup,
                                dailyRecap: $dailyRecap,
                                leaderboardAlerts: $leaderboardAlerts,
                                motivationalNudges: $motivationalNudges,
                                darkMode: $darkMode,
                                unitSystem: $unitSystem,
                                sessionViewModel: sessionViewModel,
                                onSignOut: {
                                    showingSignOutAlert = true
                                }
                            )
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    await sessionViewModel.signOut()
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .onAppear {
            healthKitEnabled = healthKitService.isAuthorized
            darkMode = colorScheme == .dark
        }
    }
}

// MARK: - Mobile Header

struct SettingsMobileHeader: View {
    let onBack: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text("Settings")
                .font(.system(size: 18, weight: .bold))
            
            Spacer()
            
            // Spacer for balance
            Color.clear
                .frame(width: 40, height: 40)
        }
        .padding()
        .background(
            Color(.systemBackground)
                .opacity(0.95)
                .background(.ultraThinMaterial)
        )
    }
}

// MARK: - Sidebar

struct SettingsSidebar: View {
    let user: User?
    let totalSteps: Int
    let currentStreak: Int
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    // Profile Section
                    SettingsProfileSection(
                        user: user,
                        totalSteps: totalSteps,
                        currentStreak: currentStreak
                    )
                    .padding(32)
                    
                    // Version Info
                    Text("v2.4.0 (Build 390)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.top, 32)
                }
            }
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Color(.systemGray5)),
            alignment: .trailing
        )
    }
}

// MARK: - Profile Section

struct SettingsProfileSection: View {
    let user: User?
    let totalSteps: Int
    let currentStreak: Int
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var displayName: String {
        user?.displayName ?? "User"
    }
    
    var formattedSteps: String {
        if totalSteps >= 1_000_000 {
            return String(format: "%.1fM", Double(totalSteps) / 1_000_000.0)
        } else if totalSteps >= 1_000 {
            return String(format: "%.1fK", Double(totalSteps) / 1_000.0)
        }
        return "\(totalSteps)"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                AvatarView(
                    displayName: displayName,
                    avatarURL: user?.avatarURL,
                    size: 128
                )
                .overlay(
                    Circle()
                        .stroke(primaryYellow, lineWidth: 4)
                )
                .shadow(color: primaryYellow.opacity(0.1), radius: 10, x: 0, y: 4)
                
                // Edit button
                ZStack {
                    Circle()
                        .fill(primaryYellow)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                }
                .overlay(
                    Circle()
                        .stroke(Color(.systemBackground), lineWidth: 4)
                )
            }
            
            // User Info
            VStack(spacing: 8) {
                Text(displayName)
                    .font(.system(size: 24, weight: .bold))
                
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14))
                    Text("Step Master")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(primaryYellow)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(primaryYellow.opacity(0.2))
                .cornerRadius(999)
            }
            
            // Mini Stats
            HStack(spacing: 12) {
                MiniStatCard(
                    label: "All-Time Steps",
                    value: formattedSteps
                )
                
                MiniStatCard(
                    label: "Current Streak",
                    value: "\(currentStreak) Days"
                )
            }
        }
    }
}

struct MiniStatCard: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(2)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

// MARK: - Main Content

struct SettingsMainContent: View {
    @Binding var healthKitEnabled: Bool
    @Binding var appleWatchSetup: Bool
    @Binding var dailyRecap: Bool
    @Binding var leaderboardAlerts: Bool
    @Binding var motivationalNudges: Bool
    @Binding var darkMode: Bool
    @Binding var unitSystem: SettingsView.UnitSystem
    
    let sessionViewModel: SessionViewModel?
    let onSignOut: () -> Void
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        VStack(spacing: 0) {
            // Desktop Header (only visible on iPad/Desktop)
            #if canImport(UIKit)
            if UIDevice.current.userInterfaceIdiom == .pad {
                HStack {
                    Text("Preferences")
                        .font(.system(size: 32, weight: .bold))
                    
                    Spacer()
                    
                    Button(action: onSignOut) {
                        HStack(spacing: 8) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color(.systemBackground))
                        .cornerRadius(999)
                        .overlay(
                            RoundedRectangle(cornerRadius: 999)
                                .stroke(Color(.systemGray5), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
                .background(
                    Color(.systemBackground)
                        .opacity(0.9)
                        .background(.ultraThinMaterial)
                )
            }
            #endif
            
            // Scrollable Content
            ScrollView {
                VStack(spacing: 24) {
                    // Settings Grid
                    #if canImport(UIKit)
                    let columns: [GridItem] = UIDevice.current.userInterfaceIdiom == .pad ? [
                        GridItem(.flexible(), spacing: 24),
                        GridItem(.flexible(), spacing: 24)
                    ] : [
                        GridItem(.flexible())
                    ]
                    #else
                    let columns: [GridItem] = [
                        GridItem(.flexible())
                    ]
                    #endif
                    
                    LazyVGrid(columns: columns, spacing: 24) {
                        // Connectivity Card
                        ConnectivityCard(
                            healthKitEnabled: $healthKitEnabled,
                            appleWatchSetup: $appleWatchSetup
                        )
                        
                        // Notifications Card
                        NotificationsCard(
                            dailyRecap: $dailyRecap,
                            leaderboardAlerts: $leaderboardAlerts,
                            motivationalNudges: $motivationalNudges
                        )
                        
                        // Preferences Card
                        PreferencesCard(
                            darkMode: $darkMode,
                            unitSystem: $unitSystem,
                            sessionViewModel: sessionViewModel
                        )
                        
                        // Support & Legal Card
                        SupportLegalCard()
                        
                        // Developer/Test Card (only show in debug builds)
                        #if DEBUG
                        DeveloperCard()
                        #endif
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 16)
                    
                    // Fun Footer
                    FunFooter()
                        .padding(.top, 32)
                        .padding(.bottom, 48)
                }
            }
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Connectivity Card

struct ConnectivityCard: View {
    @Binding var healthKitEnabled: Bool
    @Binding var appleWatchSetup: Bool
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        SettingsCard(
            icon: "applewatch",
            iconColor: .blue,
            title: "Connectivity"
        ) {
            VStack(spacing: 16) {
                // HealthKit
                SettingItemRow(
                    icon: "heart.fill",
                    title: "HealthKit Sync",
                    subtitle: "Permissions Granted",
                    trailing: {
                        Toggle("", isOn: $healthKitEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.976, green: 0.961, blue: 0.024)))
                    }
                )
                
                // Apple Watch
                SettingItemRow(
                    icon: "applewatch",
                    title: "Apple Watch",
                    subtitle: appleWatchSetup ? "Connected" : "Not setup",
                    trailing: {
                        if !appleWatchSetup {
                            Button("Setup") {
                                appleWatchSetup = true
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .cornerRadius(999)
                        } else {
                            Toggle("", isOn: $appleWatchSetup)
                                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.976, green: 0.961, blue: 0.024)))
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Notifications Card

struct NotificationsCard: View {
    @Binding var dailyRecap: Bool
    @Binding var leaderboardAlerts: Bool
    @Binding var motivationalNudges: Bool
    
    var body: some View {
        SettingsCard(
            icon: "bell.badge.fill",
            iconColor: .yellow,
            title: "Notifications"
        ) {
            VStack(spacing: 16) {
                SettingItemRow(
                    icon: "doc.text.fill",
                    title: "Daily Recap",
                    trailing: {
                        Toggle("", isOn: $dailyRecap)
                            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.976, green: 0.961, blue: 0.024)))
                    }
                )
                
                SettingItemRow(
                    icon: "trophy.fill",
                    title: "Leaderboard Alerts",
                    trailing: {
                        Toggle("", isOn: $leaderboardAlerts)
                            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.976, green: 0.961, blue: 0.024)))
                    }
                )
                
                SettingItemRow(
                    icon: "bolt.fill",
                    title: "Motivational Nudges",
                    trailing: {
                        Toggle("", isOn: $motivationalNudges)
                            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.976, green: 0.961, blue: 0.024)))
                    }
                )
            }
        }
    }
}

// MARK: - Preferences Card

struct PreferencesCard: View {
    @Binding var darkMode: Bool
    @Binding var unitSystem: SettingsView.UnitSystem
    @ObservedObject var sessionViewModel: SessionViewModel?
    @State private var showingHeightWeightEditor = false
    
    var body: some View {
        SettingsCard(
            icon: "slider.horizontal.3",
            iconColor: .purple,
            title: "App Preferences"
        ) {
            VStack(spacing: 16) {
                SettingItemRow(
                    icon: "moon.fill",
                    iconBackground: Color.black,
                    title: "Dark Mode",
                    trailing: {
                        Toggle("", isOn: $darkMode)
                            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.976, green: 0.961, blue: 0.024)))
                    }
                )
                
                SettingItemRow(
                    icon: "ruler.fill",
                    title: "Unit System",
                    trailing: {
                        HStack(spacing: 4) {
                            Button(action: { unitSystem = .metric }) {
                                Text("KM")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(unitSystem == .metric ? .black : .secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 4)
                                    .background(unitSystem == .metric ? Color(.systemBackground) : Color.clear)
                                    .cornerRadius(999)
                            }
                            
                            Button(action: { unitSystem = .imperial }) {
                                Text("MI")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(unitSystem == .imperial ? .black : .secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 4)
                                    .background(unitSystem == .imperial ? Color(.systemBackground) : Color.clear)
                                    .cornerRadius(999)
                            }
                        }
                        .padding(4)
                        .background(Color(.systemGray6))
                        .cornerRadius(999)
                    }
                )
                
                // Height and Weight
                if let sessionViewModel = sessionViewModel {
                    Button(action: {
                        showingHeightWeightEditor = true
                    }) {
                        SettingItemRow(
                            icon: "figure.stand",
                            title: "Height & Weight",
                            subtitle: {
                                let height = UserDefaults.standard.integer(forKey: "userHeight")
                                let weight = UserDefaults.standard.integer(forKey: "userWeight")
                                if height > 0 && weight > 0 {
                                    return "\(height) cm, \(weight) kg"
                                } else {
                                    return "Not set"
                                }
                            }(),
                            trailing: {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .sheet(isPresented: $showingHeightWeightEditor) {
                        if let user = sessionViewModel.currentUser {
                            EditHeightWeightSheet(
                                user: user,
                                onSave: { height, weight in
                                    Task {
                                        await sessionViewModel.authServiceAccess.updateUserHeightWeight(height: height, weight: weight)
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Support & Legal Card

struct SupportLegalCard: View {
    var body: some View {
        SettingsCard(
            icon: "questionmark.circle.fill",
            iconColor: .pink,
            title: "Support & Legal"
        ) {
            VStack(spacing: 8) {
                SupportLinkRow(
                    icon: "questionmark.circle.fill",
                    title: "FAQ / Help Center"
                )
                
                Divider()
                    .background(Color(.systemGray5))
                
                SupportLinkRow(
                    icon: "lock.fill",
                    title: "Privacy Policy"
                )
                
                Divider()
                    .background(Color(.systemGray5))
                
                SupportLinkRow(
                    icon: "info.circle.fill",
                    title: "About Us"
                )
            }
        }
    }
}

struct SupportLinkRow: View {
    let icon: String
    let title: String
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        Button(action: {}) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(.primary)
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Settings Card

struct SettingsCard<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.system(size: 20, weight: .bold))
            }
            
            // Content
            content()
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(32)
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Setting Item Row

struct SettingItemRow<Trailing: View>: View {
    let icon: String
    var iconBackground: Color = Color(.systemGray6)
    let title: String
    var subtitle: String? = nil
    @ViewBuilder let trailing: () -> Trailing
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconBackground)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconBackground == Color.black ? .white : .primary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            trailing()
        }
        .padding(8)
    }
}

// MARK: - Fun Footer

struct FunFooter: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "figure.hiking")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            Text("Keep Moving")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(2)
        }
        .opacity(0.5)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Developer Card

#if DEBUG
struct DeveloperCard: View {
    @State private var showingSupabaseTest = false
    
    var body: some View {
        SettingsCard(
            icon: "wrench.and.screwdriver.fill",
            iconColor: .orange,
            title: "Developer Tools"
        ) {
            VStack(spacing: 8) {
                Button(action: {
                    showingSupabaseTest = true
                }) {
                    HStack {
                        Image(systemName: "network")
                            .font(.system(size: 18))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Test Supabase Connection")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("Verify your Supabase setup")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .sheet(isPresented: $showingSupabaseTest) {
            SupabaseTestView()
        }
    }
}
#endif

// MARK: - Edit Height Weight Sheet

struct EditHeightWeightSheet: View {
    let user: User
    let onSave: (Int?, Int?) -> Void
    
    @State private var editingHeight: String = ""
    @State private var editingWeight: String = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Body Measurements")) {
                    HStack {
                        Text("Height (cm)")
                        Spacer()
                        TextField("175", text: $editingHeight)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Weight (kg)")
                        Spacer()
                        TextField("70", text: $editingWeight)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
                
                Section(footer: Text("These values are used for calculating calories burned and other health metrics.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Height & Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        let height = editingHeight.isEmpty ? nil : Int(editingHeight)
                        let weight = editingWeight.isEmpty ? nil : Int(editingWeight)
                        onSave(height, weight)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .onAppear {
            let height = UserDefaults.standard.integer(forKey: "userHeight")
            let weight = UserDefaults.standard.integer(forKey: "userWeight")
            editingHeight = height > 0 ? "\(height)" : ""
            editingWeight = weight > 0 ? "\(weight)" : ""
        }
    }
}
