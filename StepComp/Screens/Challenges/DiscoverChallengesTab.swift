//
//  DiscoverChallengesTab.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI

struct DiscoverChallengesTab: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    @ObservedObject var viewModel: ChallengesViewModel
    @EnvironmentObject var challengeService: ChallengeService
    
    @State private var searchText: String = ""
    @State private var selectedCategory: ChallengeCategory = .all
    @State private var navigationPath = NavigationPath()
    @State private var showingCreateChallenge = false
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    enum ChallengeCategory: String, CaseIterable {
        case all = "All"
        case corporate = "Corporate"
        case marathon = "Marathon"
        case friends = "Friends"
        case shortTerm = "Short Term"
    }
    
    var filteredChallenges: [Challenge] {
        var challenges = viewModel.publicChallenges
        
        // Filter by search text
        if !searchText.isEmpty {
            challenges = challenges.filter { challenge in
                challenge.name.localizedCaseInsensitiveContains(searchText) ||
                challenge.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by category (if implemented)
        // For now, all challenges are shown
        
        return challenges
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 0) {
                // Search Bar
                SearchBarView(searchText: $searchText)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                
                // Category Filters
                CategoryFiltersView(
                    selectedCategory: $selectedCategory
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                
                // Challenges Grid
                if filteredChallenges.isEmpty {
                    EmptyDiscoverView()
                        .padding(.vertical, 60)
                } else {
                    VStack(spacing: 16) {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ],
                            spacing: 16
                        ) {
                            ForEach(filteredChallenges) { challenge in
                                DiscoverChallengeCard(
                                    challenge: challenge,
                                    onTap: {
                                        // Navigate to challenge details or join
                                        navigationPath.append(AppRoute.groupDetails(challengeId: challenge.id))
                                    }
                                )
                            }
                        }
                        
                        // Create Custom Button (full width below grid)
                        CreateCustomChallengeButton {
                            showingCreateChallenge = true
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: AppRoute.self) { route in
                destinationView(for: route)
            }
        }
        .refreshable {
            await viewModel.loadChallenges()
        }
        .sheet(isPresented: $showingCreateChallenge) {
            CreateChallengeView(sessionViewModel: sessionViewModel)
        }
    }
    
    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .groupDetails(let challengeId):
            if viewModel.publicChallenges.contains(where: { $0.id == challengeId }) {
                GroupDetailsView(
                    sessionViewModel: sessionViewModel,
                    challengeId: challengeId
                )
            } else {
                EmptyView()
            }
        default:
            EmptyView()
        }
    }
}

// MARK: - Search Bar

struct SearchBarView: View {
    @Binding var searchText: String
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .padding(.leading, 16)
            
            TextField("Search challenges, friends, goals...", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled(true)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
        }
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(searchText.isEmpty ? Color.clear : primaryYellow, lineWidth: 2)
        )
    }
}

// MARK: - Category Filters

struct CategoryFiltersView: View {
    @Binding var selectedCategory: DiscoverChallengesTab.ChallengeCategory
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DiscoverChallengesTab.ChallengeCategory.allCases, id: \.self) { category in
                    CategoryFilterButton(
                        title: category.rawValue,
                        isSelected: selectedCategory == category,
                        action: {
                            withAnimation {
                                selectedCategory = category
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(isSelected ? .black : Color(red: 0.620, green: 0.616, blue: 0.278))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? primaryYellow : Color(.systemBackground))
                .cornerRadius(999)
                .overlay(
                    RoundedRectangle(cornerRadius: 999)
                        .stroke(isSelected ? Color.clear : Color(.systemGray5), lineWidth: 1)
                )
                .shadow(color: isSelected ? primaryYellow.opacity(0.3) : Color.clear, radius: 2, x: 0, y: 1)
        }
    }
}

// MARK: - Discover Challenge Card

struct DiscoverChallengeCard: View {
    let challenge: Challenge
    let onTap: () -> Void
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    private func challengeDuration(in challenge: Challenge) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: challenge.startDate, to: challenge.endDate)
        return max(1, components.day ?? 1)
    }
    
    var iconColor: Color {
        // Assign colors based on challenge name or type
        let colors: [Color] = [
            Color.orange,
            Color.blue,
            primaryYellow,
            Color.purple,
            Color.green
        ]
        return colors[abs(challenge.name.hashValue) % colors.count]
    }
    
    var iconName: String {
        // Assign icons based on challenge name
        let icons = ["figure.hiking", "drop.fill", "trophy.fill", "moon.fill", "tree.fill"]
        return icons[abs(challenge.name.hashValue) % icons.count]
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Top section with icon and title
                HStack(alignment: .top, spacing: 12) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(iconColor.opacity(0.2))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: iconName)
                            .font(.system(size: 24))
                            .foregroundColor(iconColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(challenge.name)
                            .font(.system(size: 16, weight: .bold))
                            .lineLimit(2)
                        
                        Text(challenge.description.isEmpty ? "Challenge" : challenge.description)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(red: 0.620, green: 0.616, blue: 0.278))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Arrow icon
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .padding(16)
                
                // Duration and status tags
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 10))
                        Text("\(challengeDuration(in: challenge)) Days")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(iconColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(iconColor.opacity(0.1))
                    .cornerRadius(8)
                    
                    Text(challenge.isOngoing ? "Ongoing" : "Starts \(formatDate(challenge.startDate))")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                
                // Participants
                HStack {
                    // Participant avatars (mock for now)
                    HStack(spacing: -8) {
                        ForEach(0..<min(3, challenge.participantIds.count), id: \.self) { index in
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Text("\(index + 1)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.blue)
                                )
                        }
                    }
                    
                    Spacer()
                    
                    Text("\(challenge.participantIds.count) joined")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.620, green: 0.616, blue: 0.278))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Create Custom Challenge Button

struct CreateCustomChallengeButton: View {
    let onCreate: () -> Void
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        Button(action: onCreate) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("Create Custom")
                        .font(.system(size: 16, weight: .bold))
                    
                    Text("Start your own battle and invite friends.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .padding(16)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                    .foregroundColor(Color(.systemGray4))
            )
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty Discover View

struct EmptyDiscoverView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Challenges Found")
                .font(.system(size: 20, weight: .bold))
            
            Text("Try adjusting your search or filters")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }
}

