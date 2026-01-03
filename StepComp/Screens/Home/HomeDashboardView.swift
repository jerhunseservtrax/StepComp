//
//  HomeDashboardView.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

struct HomeDashboardView: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    @ObservedObject var tabManager: TabSelectionManager
    @EnvironmentObject var challengeService: ChallengeService
    @EnvironmentObject var healthKitService: HealthKitService
    
    @StateObject private var viewModel: DashboardViewModel
    @State private var navigationPath = NavigationPath()
    @State private var showingAddFriends = false
    @State private var showingCreateChallenge = false
    @State private var dailyGoal: Int = 10000 // Default goal
    @State private var yesterdaySteps: Int = 0
    
    init(sessionViewModel: SessionViewModel, tabManager: TabSelectionManager) {
        self.sessionViewModel = sessionViewModel
        self.tabManager = tabManager
        // Initialize with placeholder - will be updated in onAppear
        _viewModel = StateObject(
            wrappedValue: DashboardViewModel(
                challengeService: ChallengeService(),
                healthKitService: HealthKitService(),
                userId: ""
            )
        )
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    DashboardHeader(user: sessionViewModel.currentUser)
                    
                    // Speedometer - Step Progress
                    StepSpeedometerView(
                        currentSteps: viewModel.todaySteps,
                        dailyGoal: dailyGoal,
                        percentageChange: calculatePercentageChange()
                    )
                    
                    // Active Challenges Section
                    if viewModel.activeChallenges.isEmpty {
                        EmptyChallengesView()
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Active Challenges")
                                .font(.system(size: 20, weight: .bold))
                                .padding(.horizontal)
                            
                            ForEach(viewModel.activeChallenges) { challenge in
                                ActiveChallengeCard(
                                    challenge: challenge,
                                    currentSteps: viewModel.todaySteps,
                                    onTap: {
                                        navigationPath.append(AppRoute.groupDetails(challengeId: challenge.id))
                                    },
                                    onViewLeaderboard: {
                                        navigationPath.append(AppRoute.leaderboard(challengeId: challenge.id))
                                    }
                                )
                            }
                        }
                    }
                    
                    // Daily Pulse Stats
                    DailyPulseStatsView(
                        calories: viewModel.caloriesBurned,
                        distanceMiles: viewModel.distanceMiles,
                        steps: viewModel.todaySteps
                    )
                    
                    // Add Friends CTA
                    AddFriendsCTA {
                        showingAddFriends = true
                    }
                    
                    // Create Challenge CTA
                    CreateChallengeCTA {
                        showingCreateChallenge = true
                    }
                    
                    // Join Challenge CTA (if no active challenges)
                    if viewModel.activeChallenges.isEmpty {
                        JoinChallengeCTA {
                            // Navigate to join challenge tab or view
                            // This could be handled by switching tabs or navigation
                        }
                    }
                }
                .iPadAdaptivePadding()
                .padding(.vertical)
            }
            .navigationBarHidden(true)
            .navigationDestination(for: AppRoute.self) { route in
                destinationView(for: route)
            }
            .refreshable {
                #if canImport(Supabase)
                await challengeService.refreshChallenges()
                #endif
                viewModel.refresh()
            }
        }
        .onAppear {
            loadDailyGoal()
            loadYesterdaySteps()
            updateViewModel()
            // Ensure HealthKit is initialized
            _ = healthKitService.isHealthKitAvailable
            healthKitService.checkAuthorizationStatus()
            
            // Resume auto-refresh when view appears
            viewModel.resumeAutoRefresh()
            
            // Refresh challenges from Supabase when view appears
            Task {
                #if canImport(Supabase)
                await challengeService.refreshChallenges()
                #endif
                updateViewModel()
                // Steps will sync automatically via DashboardViewModel.loadStepData()
            }
        }
        .onDisappear {
            // Pause auto-refresh when view disappears to save resources
            viewModel.pauseAutoRefresh()
        }
        .onChange(of: healthKitService.isAuthorized) { _, _ in
            // Reload data when authorization status changes
            updateViewModel()
        }
        #if canImport(UIKit)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Refresh when app comes to foreground
            updateViewModel()
        }
        #endif
        .task(id: challengeService.challenges.count) {
            // Only update when challenges actually change (count changes)
            updateViewModel()
        }
        .sheet(isPresented: $showingAddFriends) {
            AddFriendsView(sessionViewModel: sessionViewModel)
        }
        .sheet(isPresented: $showingCreateChallenge) {
            CreateChallengeView(sessionViewModel: sessionViewModel)
        }
        .onChange(of: showingCreateChallenge) { oldValue, newValue in
            // Refresh challenges when sheet is dismissed
            if oldValue == true && newValue == false {
                Task {
                    #if canImport(Supabase)
                    // Small delay to ensure database transaction is committed
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    await challengeService.refreshChallenges()
                    #endif
                    await viewModel.refreshChallenges()
                    updateViewModel()
                    print("🔄 Home screen: Refreshed challenges after creation")
                }
            }
        }
    }
    
    private func updateViewModel() {
        guard let userId = sessionViewModel.currentUser?.id else { return }
        viewModel.updateServices(challengeService: challengeService, healthKitService: healthKitService, userId: userId)
    }
    
    private func loadDailyGoal() {
        dailyGoal = UserDefaults.standard.integer(forKey: "dailyStepGoal")
        if dailyGoal == 0 {
            dailyGoal = 10000 // Default if not set
        }
    }
    
    private func loadYesterdaySteps() {
        Task {
            do {
                let calendar = Calendar.current
                let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
                let startOfYesterday = calendar.startOfDay(for: yesterday)
                let endOfYesterday = calendar.date(byAdding: .day, value: 1, to: startOfYesterday)!
                
                if let steps = try await healthKitService.getStepCount(
                    from: startOfYesterday,
                    to: endOfYesterday
                ) {
                    yesterdaySteps = Int(steps)
                }
            } catch {
                print("Failed to load yesterday's steps: \(error)")
            }
        }
    }
    
    private func calculatePercentageChange() -> Double {
        guard yesterdaySteps > 0 else { return 0 }
        let change = Double(viewModel.todaySteps - yesterdaySteps)
        return (change / Double(yesterdaySteps)) * 100.0
    }
    
    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .groupDetails(let challengeId):
            GroupDetailsView(
                sessionViewModel: sessionViewModel,
                challengeId: challengeId
            )
        case .leaderboard(let challengeId):
            LeaderboardView(sessionViewModel: sessionViewModel, challengeId: challengeId)
        case .createChallenge:
            CreateChallengeView(sessionViewModel: sessionViewModel)
        default:
            EmptyView()
        }
    }
}

struct EmptyChallengesView: View {
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.976, green: 0.961, blue: 0.024).opacity(0.1))
                    .frame(width: 120, height: 120)
                    .blur(radius: 40)
                
                Image(systemName: "figure.walk")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                Text("No Active Challenges")
                    .font(.system(size: 20, weight: .bold))
                
                Text("Create or join a challenge to get started!")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(.systemBackground))
        .cornerRadius(32)
        .shadow(color: Color.black.opacity(0.04), radius: 24, x: 0, y: 4)
    }
}

struct JoinChallengeCTA: View {
    let onJoin: () -> Void
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        Button(action: onJoin) {
            HStack {
                Image(systemName: "magnifyingglass")
                Text("Discover Challenges")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .cornerRadius(12)
        }
    }
}

