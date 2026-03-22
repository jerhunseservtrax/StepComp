//
//  HomeDashboardView.swift
//  FitComp
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
    @Environment(\.colorScheme) private var colorScheme
    
    @StateObject private var viewModel: DashboardViewModel
    @ObservedObject private var celebrationManager = GoalCelebrationManager.shared
    @ObservedObject private var workoutViewModel = WorkoutViewModel.shared
    @State private var navigationPath = NavigationPath()
    @State private var showingAddFriends = false
    @State private var showingCreateChallenge = false
    @State private var selectedPage: Int = 0
    @State private var dailyGoal: Int = 10000 // Default goal
    @State private var selectedDate: Date = Date()
    @State private var weeklyStepData: [Int] = Array(repeating: 0, count: 30) // 30 days of historical data
    @State private var selectedDateSteps: Int = 0
    @State private var selectedDateCalories: Int = 0
    @State private var selectedDateDistance: Double = 0.0
    @State private var hasPerformedInitialLoad = false
    
    init(sessionViewModel: SessionViewModel, tabManager: TabSelectionManager) {
        self.sessionViewModel = sessionViewModel
        self.tabManager = tabManager
        _viewModel = StateObject(wrappedValue: DashboardViewModel(userId: ""))
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                FitCompColors.background
                    .ignoresSafeArea()

                VStack(spacing: 12) {
                    DashboardHeader(user: sessionViewModel.currentUser, sessionViewModel: sessionViewModel)
                        .padding(.top, 8)

                    Picker("Home Page", selection: $selectedPage) {
                        Text("Steps").tag(0)
                        Text("Workouts").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .tint(FitCompColors.primary)

                    TabView(selection: $selectedPage) {
                        stepsDashboardPage
                            .tag(0)

                        WorkoutsView()
                            .tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: AppRoute.self) { route in
                destinationView(for: route)
            }
            .refreshable {
                if selectedPage == 0 {
                    #if canImport(Supabase)
                    await challengeService.refreshChallenges()
                    #endif
                    viewModel.refresh()
                    await loadWeeklyData()
                }
            }
        }
        .onAppear {
            // Resume auto-refresh when view appears
            viewModel.resumeAutoRefresh()
        }
        .task {
            await performInitialLoadIfNeeded()
        }
        .onChange(of: selectedDate) { oldDate, newDate in
            // Load steps when date changes
            Task {
                await loadStepsForSelectedDate()
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
        // Goal Celebration Full-Screen Cover
        .fullScreenCover(isPresented: $celebrationManager.shouldShowCelebration) {
            GoalCelebrationView(
                steps: celebrationManager.celebrationSteps,
                goal: celebrationManager.celebrationGoal,
                onDismiss: {
                    celebrationManager.dismissCelebration()
                }
            )
        }
        .alert(
            "Sync Error",
            isPresented: Binding(
                get: { challengeService.lastErrorMessage != nil },
                set: { if !$0 { challengeService.lastErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(challengeService.lastErrorMessage ?? "Something went wrong.")
        }
    }

    private var stepsDashboardPage: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                LazyVStack(spacing: 20) {
                    DateSelectorView(selectedDate: $selectedDate)

                    DailyGoalCard(
                        currentSteps: selectedDateSteps,
                        dailyGoal: dailyGoal,
                        calories: selectedDateCalories,
                        distanceKm: selectedDateDistance,
                        activeHours: Double(selectedDateSteps) / 6500.0,
                        weeklyStepData: weeklyStepData,
                        selectedDate: selectedDate,
                        onRefresh: {
                            await loadStepsForSelectedDate()
                            await loadWeeklyData()
                            viewModel.refresh()
                        },
                        celebrationManager: celebrationManager
                    )

                    ActivityChartView(weeklyData: weeklyStepData)

                    if !viewModel.activeChallenges.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Active Challenges")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 24)

                            StackedChallengesView(
                                challenges: viewModel.activeChallenges,
                                currentSteps: viewModel.todaySteps,
                                onChallengeTap: { challenge in
                                    navigationPath.append(AppRoute.groupDetails(challengeId: challenge.id))
                                }
                            )
                        }
                        .padding(.top, 8)
                    }

                    Spacer()
                        .frame(height: 92)
                }
                .padding(.vertical)
            }

            VStack {
                Spacer()

                Button(action: {
                    showingCreateChallenge = true
                    HapticManager.shared.medium()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Create Challenge")
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundColor(FitCompColors.buttonTextOnPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(FitCompColors.primaryGradient(for: colorScheme))
                            .shadow(color: FitCompColors.primary.opacity(0.4), radius: 16, x: 0, y: 8)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
    }

    private var weeklyScopeCards: some View {
        return VStack(spacing: 10) {
            ForEach(Array(viewModel.weeklyScopeMetricPairs.enumerated()), id: \.offset) { _, pair in
                scopeCardRow(titleA: pair.titleA, valueA: pair.valueA, titleB: pair.titleB, valueB: pair.valueB)
            }
        }
        .padding(.horizontal, 20)
    }

    private var longTermScopeCards: some View {
        return VStack(spacing: 10) {
            ForEach(Array(viewModel.longTermScopeMetricPairs.enumerated()), id: \.offset) { _, pair in
                scopeCardRow(titleA: pair.titleA, valueA: pair.valueA, titleB: pair.titleB, valueB: pair.valueB)
            }
        }
        .padding(.horizontal, 20)
    }

    private func scopeCardRow(titleA: String, valueA: String, titleB: String, valueB: String) -> some View {
        HStack(spacing: 10) {
            scopeCard(title: titleA, value: valueA)
            scopeCard(title: titleB, value: valueB)
        }
    }

    private func scopeCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(FitCompColors.textSecondary)
            Text(value)
                .font(.system(size: 20, weight: .heavy))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
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
        viewModel.computeScopeMetrics(weeklyStepData: weeklyStepData, dailyGoal: dailyGoal)
    }

    private func performInitialLoadIfNeeded() async {
        guard !hasPerformedInitialLoad else { return }
        hasPerformedInitialLoad = true
        
        loadDailyGoal()
        
        // Ensure HealthKit is initialized before dashboard load.
        _ = healthKitService.isHealthKitAvailable
        healthKitService.checkAuthorizationStatus()
        
        updateViewModel()
        await loadWeeklyData()
        await loadStepsForSelectedDate()
    }
    
    private func loadWeeklyData() async {
        // Load historical step data from HealthKit (30 days)
        // IMPORTANT: Data format is "last N days" where last index = today, index 0 = N-1 days ago
        // This must match the display logic in DailyGoalCard.dayLabel(for:)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let numberOfDays = 30 // Load 30 days of historical data
        
        var dailySteps: [Int] = []
        
        // Load last N days: index 0 = (N-1) days ago, last index = today
        for dayOffset in 0..<numberOfDays {
            // Calculate date: today - (numberOfDays - 1 - dayOffset) days
            // dayOffset 0 -> (numberOfDays - 1) days ago
            // dayOffset (numberOfDays - 1) -> 0 days ago (today)
            guard let dayStart = calendar.date(byAdding: .day, value: dayOffset - (numberOfDays - 1), to: today),
                  let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                dailySteps.append(0)
                continue
            }
            
            do {
                let stats = try await healthKitService.getSteps(from: dayStart, to: dayEnd)
                let daySteps = stats.reduce(0) { $0 + $1.steps }
                dailySteps.append(daySteps)
            } catch {
                dailySteps.append(0)
            }
        }
        
        await MainActor.run {
            weeklyStepData = dailySteps
            viewModel.computeScopeMetrics(weeklyStepData: dailySteps, dailyGoal: dailyGoal)
        }
    }
    
    private func loadStepsForSelectedDate() async {
        let calendar = Calendar.current
        
        // Get start and end of selected date
        guard let dayStart = calendar.startOfDay(for: selectedDate) as Date?,
              let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            await MainActor.run {
                selectedDateSteps = 0
                selectedDateCalories = 0
                selectedDateDistance = 0.0
            }
            return
        }
        
        // Don't fetch data for future dates
        if dayStart > Date() {
            await MainActor.run {
                selectedDateSteps = 0
                selectedDateCalories = 0
                selectedDateDistance = 0.0
            }
            return
        }
        
        do {
            let stats = try await healthKitService.getSteps(from: dayStart, to: dayEnd)
            let totalSteps = stats.reduce(0) { $0 + $1.steps }
            
            // Calculate derived metrics
            let calories = Int(Double(totalSteps) * 0.04) // Approximate: 1 step ≈ 0.04 kcal
            let distance = Double(totalSteps) * 0.0008 // Approximate: 1 step ≈ 0.0008 km
            
            await MainActor.run {
                selectedDateSteps = totalSteps
                selectedDateCalories = calories
                selectedDateDistance = distance
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                print("📅 Loaded steps for \(dateFormatter.string(from: selectedDate)): \(totalSteps) steps")
            }
        } catch {
            print("⚠️ Error loading steps for selected date: \(error.localizedDescription)")
            await MainActor.run {
                selectedDateSteps = 0
                selectedDateCalories = 0
                selectedDateDistance = 0.0
            }
        }
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
                    .fill(FitCompColors.primary.opacity(0.1))
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

