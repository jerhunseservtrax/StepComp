//
//  WorkoutsView.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 2/16/26.
//

import SwiftUI

struct WorkoutsView: View {
    @ObservedObject var viewModel = WorkoutViewModel.shared
    @ObservedObject var unitManager = UnitPreferenceManager.shared
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var showingCreateWorkout = false
    @State private var workoutToEdit: Workout?
    @State private var workoutToDelete: Workout?
    @State private var showingDeleteConfirmation = false
    @State private var todaySteps: Int = 0
    @State private var userWeight: Int = 0
    @State private var sessionToEdit: CompletedWorkoutSession?
    
    @StateObject private var healthKitService = HealthKitService()
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject var weightViewModel = WeightViewModel.shared
    @ObservedObject var photoViewModel = TransformationPhotoViewModel.shared
    @State private var showingWeightEntry = false
    @State private var showingPhotoGallery = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                StepCompColors.background.ignoresSafeArea()
                
                if viewModel.currentSession != nil {
                    ActiveWorkoutView(viewModel: viewModel)
                } else {
                    workoutListView
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .fontWeight(.semibold)
                }
            }
            .confirmationDialog("Delete Workout", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let workout = workoutToDelete {
                        viewModel.deleteWorkout(workout)
                    }
                    workoutToDelete = nil
                    showingDeleteConfirmation = false
                }
                Button("Cancel", role: .cancel) {
                    workoutToDelete = nil
                    showingDeleteConfirmation = false
                }
            } message: {
                Text("Are you sure you want to delete \"\(workoutToDelete?.name ?? "")\"? This cannot be undone.")
            }
        }
    }
    
    private var workoutListView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with timer
                headerView
                
                // Date selector (horizontal calendar) - at the very top
                dateSelector
                
                // Workouts for selected day
                workoutsForSelectedDay
                
                // Add workout button
                addWorkoutButton
                
                // Estimated 1RM Section
                BigThreeLiftCard(viewModel: viewModel, unitManager: unitManager)
                
                // Personal Bests Cards (Weight and Photos)
                HStack(spacing: 12) {
                    WeightTrackingCard(
                        viewModel: weightViewModel,
                        unitManager: unitManager,
                        showingWeightEntry: $showingWeightEntry
                    )
                    
                    TransformationPhotoCard(
                        viewModel: photoViewModel,
                        showingPhotoGallery: $showingPhotoGallery
                    )
                }
                .frame(height: 160)
                
                // Consistency Tracker
                ConsistencyTrackerCard(viewModel: viewModel)
                
                // Completed exercises for selected day
                completedExercisesForSelectedDay
                
                // Recent Logs Section (at the very bottom)
                recentLogsSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .onAppear {
            loadHealthData()
        }
        .sheet(isPresented: $showingCreateWorkout) {
            CreateWorkoutView(viewModel: viewModel)
        }
        .sheet(item: $workoutToEdit) { workout in
            EditWorkoutView(viewModel: viewModel, workout: workout)
        }
        .sheet(item: $sessionToEdit) { session in
            EditCompletedSessionView(viewModel: viewModel, session: session)
        }
        .sheet(isPresented: $showingWeightEntry) {
            WeightEntryView(viewModel: weightViewModel, unitManager: unitManager)
        }
        .sheet(isPresented: $showingPhotoGallery) {
            TransformationPhotoGalleryView(viewModel: photoViewModel)
        }
    }
    
    private func formatNumberCompact(_ number: Int) -> String {
        if number >= 1000 {
            return String(format: "%.1fk", Double(number) / 1000.0)
        }
        return "\(number)"
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Workouts")
                    .font(.system(size: 28, weight: .black))
                
                if !viewModel.workouts.isEmpty {
                    Text("\(viewModel.workouts.count) total workout\(viewModel.workouts.count == 1 ? "" : "s")")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(StepCompColors.textSecondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Image(systemName: "timer")
                    .font(.system(size: 14, weight: .bold))
                Text("0:00")
                    .font(.system(size: 14, weight: .black))
                    .monospacedDigit()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(20)
        }
        .padding(.top, 20)
    }
    
    private var dateSelector: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(getDatesForWeek(), id: \.self) { date in
                        WorkoutDateButton(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            action: { selectedDate = date }
                        )
                        .id(date)
                    }
                }
            }
            .onAppear {
                // Scroll to today's date when view appears
                proxy.scrollTo(selectedDate, anchor: .center)
            }
        }
    }
    
    @ViewBuilder
    private var workoutsForSelectedDay: some View {
        let day = DayOfWeek.from(date: selectedDate)
        let workouts = viewModel.getWorkoutsForDay(day)
        if workouts.isEmpty {
            emptyState
        } else {
            VStack(spacing: 16) {
                ForEach(workouts) { workout in
                    WorkoutCard(
                        workout: workout,
                        selectedDate: selectedDate,
                        viewModel: viewModel,
                        onStart: { viewModel.startWorkout(workout, targetDate: selectedDate) },
                        onEdit: { workoutToEdit = workout },
                        onDelete: { viewModel.deleteWorkout(workout) }
                    )
                }
            }
        }
    }
    
    private var emptyState: some View {
        let selectedDay = DayOfWeek.from(date: selectedDate)
        
        return VStack(spacing: 16) {
            Image(systemName: "dumbbell")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.3))
            
            Text("No workouts on \(selectedDay.fullName)")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.gray)
            
            if viewModel.workouts.isEmpty {
                Text("Create a workout to get started")
                    .font(.system(size: 14))
                    .foregroundColor(.gray.opacity(0.7))
            } else {
                Text("Try selecting a different day or create a new workout")
                    .font(.system(size: 14))
                    .foregroundColor(.gray.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    private var addWorkoutButton: some View {
        Button(action: { showingCreateWorkout = true }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                Text("Create New Workout")
                    .font(.system(size: 16, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(StepCompColors.primary)
            .foregroundColor(.black)
            .cornerRadius(28)
        }
    }
    
    private func getDatesForWeek() -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysFromSunday = weekday - 1
        
        guard let sunday = calendar.date(byAdding: .day, value: -daysFromSunday, to: today) else {
            return []
        }
        
        // Show current week + 8 weeks ahead (9 weeks total = 63 days)
        return (0..<63).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: sunday)
        }
    }
    
    private func loadHealthData() {
        Task {
            // Request HealthKit authorization if needed
            if !healthKitService.isAuthorized {
                try? await healthKitService.requestAuthorization()
            }
            
            // Load today's steps from HealthKit
            do {
                let steps = try await healthKitService.getTodaySteps()
                print("📊 Steps from HealthKit: \(steps)")
                await MainActor.run {
                    todaySteps = steps
                }
            } catch {
                print("❌ Error loading steps: \(error)")
                await MainActor.run {
                    todaySteps = 0
                }
            }
            
            // Load weight from HealthKit
            do {
                if let weightKg = try await healthKitService.getWeight() {
                    print("⚖️ Weight from HealthKit: \(weightKg) kg")
                    await MainActor.run {
                        userWeight = Int(weightKg)
                        print("⚖️ Displaying weight: \(userWeight) kg")
                    }
                } else {
                    // Fallback to UserDefaults if HealthKit returns nil
                    print("⚠️ HealthKit returned nil for weight, using UserDefaults")
                    await MainActor.run {
                        userWeight = UserDefaults.standard.integer(forKey: "user_weight")
                        if userWeight == 0 {
                            userWeight = 68 // Default
                        }
                        print("⚖️ Using fallback weight: \(userWeight) kg")
                    }
                }
            } catch {
                print("❌ Error loading weight: \(error)")
                // Fallback to UserDefaults
                await MainActor.run {
                    userWeight = UserDefaults.standard.integer(forKey: "user_weight")
                    if userWeight == 0 {
                        userWeight = 68 // Default
                    }
                }
            }
        }
    }
    
    // MARK: - Recent Logs Section
    
    @ViewBuilder
    private var recentLogsSection: some View {
        if !viewModel.completedSessions.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("RECENT LOGS")
                    .font(.system(size: 13, weight: .black))
                    .tracking(1.5)
                    .foregroundColor(StepCompColors.textSecondary)
                
                VStack(spacing: 12) {
                    ForEach(getRecentSessions().prefix(3)) { session in
                        RecentWorkoutLogCard(
                            session: session,
                            viewModel: viewModel,
                            unitManager: unitManager,
                            sessionToEdit: $sessionToEdit
                        )
                    }
                }
            }
        }
    }
    
    private var completedExercisesForSelectedDay: some View {
        let completedSessions = getCompletedSessionsForSelectedDate()
        
        if !completedSessions.isEmpty {
            return AnyView(
                VStack(alignment: .leading, spacing: 12) {
                    Text("COMPLETED EXERCISES")
                        .font(.system(size: 13, weight: .black))
                        .tracking(1.5)
                        .foregroundColor(StepCompColors.textSecondary)
                    
                    VStack(spacing: 12) {
                        ForEach(completedSessions) { session in
                            CompletedSessionCard(
                                session: session,
                                viewModel: viewModel,
                                unitManager: unitManager,
                                sessionToEdit: $sessionToEdit
                            )
                        }
                    }
                }
            )
        } else {
            return AnyView(EmptyView())
        }
    }
    
    private func getCompletedSessionsForSelectedDate() -> [CompletedWorkoutSession] {
        let calendar = Calendar.current
        return viewModel.completedSessions.filter { session in
            calendar.isDate(session.endTime, inSameDayAs: selectedDate)
        }
        .sorted { $0.endTime > $1.endTime }
    }
    
    private func getRecentSessions() -> [CompletedWorkoutSession] {
        return viewModel.completedSessions
            .sorted { $0.endTime > $1.endTime }
    }
    
    private func isPRSet(_ set: WorkoutSet, exerciseName: String) -> Bool {
        // Check if this set is a PR by comparing with all previous sessions
        guard let weight = set.weight, let reps = set.reps else { return false }
        
        let estimated1RM = viewModel.calculateEstimated1RM(weight: weight, reps: reps)
        
        // Check all previous sessions for this exercise
        for session in viewModel.completedSessions {
            for exercise in session.exercises {
                if exercise.exercise.name.lowercased().contains(exerciseName.lowercased()) {
                    for oldSet in exercise.sets {
                        if let oldWeight = oldSet.weight, let oldReps = oldSet.reps {
                            let old1RM = viewModel.calculateEstimated1RM(weight: oldWeight, reps: oldReps)
                            if estimated1RM <= old1RM && (weight < oldWeight || reps <= oldReps) {
                                return false
                            }
                        }
                    }
                }
            }
        }
        
        return true
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

struct WorkoutDateButton: View {
    let date: Date
    let isSelected: Bool
    let action: () -> Void
    @ObservedObject var viewModel = WorkoutViewModel.shared
    
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    private var dayOfMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private var hasWorkouts: Bool {
        let day = DayOfWeek.from(date: date)
        return !viewModel.getWorkoutsForDay(day).isEmpty
    }
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 4) {
                    Text(dayOfWeek)
                        .font(.system(size: 10, weight: .bold))
                    Text(dayOfMonth)
                        .font(.system(size: 16, weight: .black))
                }
                .frame(width: 56, height: 56)
                .background(isSelected ? StepCompColors.primary : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .black : .gray)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? StepCompColors.primary.opacity(0.3) : Color.clear, lineWidth: 4)
                )
                
                if hasWorkouts && !isSelected {
                    Circle()
                        .fill(StepCompColors.primary)
                        .frame(width: 8, height: 8)
                        .offset(x: -6, y: 6)
                }
            }
        }
    }
}

struct WorkoutCard: View {
    let workout: Workout
    let selectedDate: Date
    @ObservedObject var viewModel: WorkoutViewModel
    let onStart: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingWorkoutDetail = false
    
    private var isCompleted: Bool {
        viewModel.wasWorkoutCompleted(workout: workout, on: selectedDate)
    }
    
    private var cardBackground: Color {
        if isCompleted {
            return Color.green.opacity(colorScheme == .dark ? 0.18 : 0.12)
        }
        return colorScheme == .dark ? Color.black : Color.white
    }
    
    var body: some View {
        Button(action: { showingWorkoutDetail = true }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(StepCompColors.textPrimary)
                        
                        HStack(spacing: 4) {
                            Text(workout.assignedDays.map { $0.rawValue }.joined(separator: ", "))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(StepCompColors.textSecondary)
                            Text("•")
                                .foregroundColor(StepCompColors.textSecondary)
                            Text("\(workout.exercises.count) Exercises")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(StepCompColors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        onEdit()
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16))
                            .foregroundColor(StepCompColors.textSecondary)
                            .frame(width: 40, height: 40)
                            .background(StepCompColors.textSecondary.opacity(0.1))
                            .cornerRadius(20)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Exercise preview
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(workout.exercises.prefix(3)) { workoutExercise in
                            ExercisePreviewChip(exerciseName: workoutExercise.exercise.name)
                        }
                        
                        if workout.exercises.count > 3 {
                            Text("+\(workout.exercises.count - 3) more")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(StepCompColors.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(StepCompColors.textSecondary.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }
                
                // Start workout / Completed button
                if isCompleted {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Completed")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.green.opacity(0.35))
                    .foregroundColor(Color.green)
                    .cornerRadius(24)
                } else {
                    Button(action: {
                        onStart()
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Workout")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(StepCompColors.primary)
                        .foregroundColor(StepCompColors.buttonTextOnPrimary)
                        .cornerRadius(24)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(16)
        }
        .buttonStyle(PlainButtonStyle())
        .background(cardBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isCompleted ? Color.green.opacity(0.4) : Color.clear, lineWidth: 1)
        )
        .shadow(color: StepCompColors.shadowSecondary, radius: 10, x: 0, y: 4)
        .sheet(isPresented: $showingWorkoutDetail) {
            WorkoutDetailView(
                workout: workout,
                selectedDate: selectedDate,
                viewModel: viewModel
            )
        }
    }
}

struct ExercisePreviewChip: View {
    let exerciseName: String
    
    var body: some View {
        Text(exerciseName)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(StepCompColors.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(StepCompColors.textSecondary.opacity(0.1))
            .cornerRadius(12)
    }
}

#Preview {
    WorkoutsView()
}

// MARK: - Stat Cards

// Personal Best Card (matching the example design)
struct PersonalBestCard: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let backgroundColor: Color
    let textColor: Color
    let iconBackgroundColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Icon at top
            HStack {
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor)
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(textColor)
                }
                Spacer()
            }
            .padding(.bottom, 8)
            
            Spacer()
            
            // Value and label at bottom
            VStack(alignment: .leading, spacing: 4) {
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(textColor.opacity(0.4))
                    .tracking(0.5)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 32, weight: .black))
                        .italic()
                        .foregroundColor(textColor)
                    if !unit.isEmpty {
                        Text(unit.lowercased())
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(textColor.opacity(0.6))
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .cornerRadius(24)
        .shadow(color: backgroundColor == StepCompColors.primary ? backgroundColor.opacity(0.15) : Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}

// Consistency Tracker with Grid (matching the example)
struct ConsistencyTrackerCard: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    private var currentStreak: Int {
        viewModel.getCurrentStreak()
    }
    
    private var totalSessions: Int {
        viewModel.getTotalSessions()
    }
    
    private var consistencyData: [Date: Bool] {
        viewModel.getConsistencyData(days: 90)
    }
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color(hex: "1a1a1a") : Color(hex: "f8f8f5")
    }
    
    private var gridBackground: Color {
        colorScheme == .dark ? Color(hex: "2a2a2a") : Color(hex: "e8e8e5")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("CONSISTENCY")
                    .font(.system(size: 13, weight: .black))
                    .tracking(1.5)
                    .foregroundColor(StepCompColors.textSecondary)
                
                Spacer()
                
                Text("LAST 90 DAYS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(StepCompColors.textSecondary)
            }
            
            // Heatmap Grid (7 rows x 13 columns = 91 days)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(0..<13, id: \.self) { column in
                        VStack(spacing: 4) {
                            ForEach(0..<7, id: \.self) { row in
                                let dayIndex = column * 7 + row
                                let date = getDateForIndex(dayIndex)
                                let hasWorkout = consistencyData[date] ?? false
                                
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(hasWorkout ? StepCompColors.primary : gridBackground)
                                    .frame(width: 12, height: 12)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Stats Row
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CURRENT STREAK")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(StepCompColors.textSecondary)
                    Text("\(currentStreak) Days")
                        .font(.system(size: 20, weight: .black))
                        .italic()
                        .foregroundColor(StepCompColors.textPrimary)
                }
                
                Spacer()
                
                Rectangle()
                    .fill(StepCompColors.textSecondary.opacity(0.2))
                    .frame(width: 1, height: 40)
                    .padding(.horizontal, 16)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("TOTAL SESSIONS")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(StepCompColors.textSecondary)
                    Text("\(totalSessions)")
                        .font(.system(size: 20, weight: .black))
                        .italic()
                        .foregroundColor(StepCompColors.textPrimary)
                }
            }
            .padding(.top, 8)
        }
        .padding(20)
        .background(cardBackground)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05), lineWidth: 1)
        )
    }
    
    private func getDateForIndex(_ index: Int) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: -(90 - index), to: today) ?? today
    }
}

// Big Three Lifts Card (updated design)
struct BigThreeLiftCard: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @ObservedObject var unitManager: UnitPreferenceManager
    @Environment(\.colorScheme) private var colorScheme
    
    private var bigThreeData: (squat: Double?, bench: Double?, deadlift: Double?) {
        viewModel.getBigThreeEstimated1RMs()
    }
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color(hex: "1a1a1a") : Color(hex: "f8f8f5")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("ESTIMATED 1RM")
                    .font(.system(size: 13, weight: .black))
                    .tracking(1.5)
                    .foregroundColor(StepCompColors.textSecondary)
                
                Spacer()
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(StepCompColors.primary)
            }
            
            // Lifts
            VStack(spacing: 12) {
                if let squat = bigThreeData.squat {
                    BigThreeLiftRow(
                        name: "Squat",
                        weight: unitManager.formatWeight(Double(squat), decimals: 0),
                        unit: unitManager.weightUnit
                    )
                }
                
                if let bench = bigThreeData.bench {
                    BigThreeLiftRow(
                        name: "Bench",
                        weight: unitManager.formatWeight(Double(bench), decimals: 0),
                        unit: unitManager.weightUnit
                    )
                }
                
                if let deadlift = bigThreeData.deadlift {
                    BigThreeLiftRow(
                        name: "Deadlift",
                        weight: unitManager.formatWeight(Double(deadlift), decimals: 0),
                        unit: unitManager.weightUnit
                    )
                }
                
                if bigThreeData.squat == nil && bigThreeData.bench == nil && bigThreeData.deadlift == nil {
                    Text("No lifts recorded yet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(StepCompColors.textSecondary)
                        .padding(.vertical, 12)
                }
            }
        }
        .padding(20)
        .background(cardBackground)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05), lineWidth: 1)
        )
    }
}

struct BigThreeLiftRow: View {
    let name: String
    let weight: String
    let unit: String
    
    var body: some View {
        HStack {
            Text(name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(StepCompColors.textSecondary)
            
            Spacer()
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(weight)
                    .font(.system(size: 20, weight: .black))
                    .italic()
                    .foregroundColor(StepCompColors.textPrimary)
                Text(unit.lowercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(StepCompColors.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// Color extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Completed Session Card (shows detailed exercise breakdown)
struct CompletedSessionCard: View {
    let session: CompletedWorkoutSession
    @ObservedObject var viewModel: WorkoutViewModel
    @ObservedObject var unitManager: UnitPreferenceManager
    @Binding var sessionToEdit: CompletedWorkoutSession?
    @Environment(\.colorScheme) private var colorScheme
    @State private var isExpanded = false
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color(hex: "1a1a1a") : Color.white
    }
    
    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05)
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: session.endTime)
    }
    
    private var durationString: String {
        let duration = session.duration
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.workoutName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(StepCompColors.textPrimary)
                        
                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                Text(timeString)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "timer")
                                    .font(.system(size: 10))
                                Text(durationString)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "dumbbell")
                                    .font(.system(size: 10))
                                Text("\(session.exercises.count) exercises")
                                    .font(.system(size: 12, weight: .medium))
                            }
                        }
                        .foregroundColor(StepCompColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        // Edit button
                        Button(action: {
                            sessionToEdit = session
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(StepCompColors.textSecondary)
                                .frame(width: 36, height: 36)
                                .background(StepCompColors.textSecondary.opacity(0.1))
                                .cornerRadius(18)
                        }
                        
                        // Expand/collapse icon
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(StepCompColors.textSecondary)
                    }
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Exercise details (when expanded)
            if isExpanded {
                VStack(spacing: 16) {
                    ForEach(session.exercises) { exercise in
                        ExerciseDetailRow(exercise: exercise, unitManager: unitManager)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: 1)
        )
    }
}

// Exercise detail row for completed session card
struct ExerciseDetailRow: View {
    let exercise: WorkoutExercise
    @ObservedObject var unitManager: UnitPreferenceManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.exercise.name)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(StepCompColors.textPrimary)
            
            VStack(spacing: 6) {
                ForEach(exercise.sets.filter { $0.isCompleted }) { set in
                    HStack(spacing: 8) {
                        Text("Set \(set.setNumber)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(StepCompColors.textSecondary)
                            .frame(width: 50, alignment: .leading)
                        
                        if let weight = set.weight, let reps = set.reps {
                            HStack(spacing: 4) {
                                let displayWeight = unitManager.convertWeightFromStorage(weight)
                                let weightStr = displayWeight.truncatingRemainder(dividingBy: 1) == 0
                                    ? String(Int(displayWeight))
                                    : String(format: "%.1f", displayWeight)
                                Text(weightStr)
                                    .font(.system(size: 14, weight: .bold))
                                Text(unitManager.weightUnit.lowercased())
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(StepCompColors.textSecondary)
                                Text("×")
                                    .font(.system(size: 12))
                                    .foregroundColor(StepCompColors.textSecondary)
                                Text("\(reps)")
                                    .font(.system(size: 14, weight: .bold))
                                Text("reps")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(StepCompColors.textSecondary)
                            }
                            .foregroundColor(StepCompColors.textPrimary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 12)
                    .background(StepCompColors.textSecondary.opacity(0.05))
                    .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// Recent Workout Log Card
struct RecentWorkoutLogCard: View {
    let session: CompletedWorkoutSession
    @ObservedObject var viewModel: WorkoutViewModel
    @ObservedObject var unitManager: UnitPreferenceManager
    @Binding var sessionToEdit: CompletedWorkoutSession?
    @Environment(\.colorScheme) private var colorScheme
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color(hex: "1a1a1a") : Color.white
    }
    
    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05)
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: session.endTime)
    }
    
    // Get the best set from the session (highest estimated 1RM)
    private var bestSet: (exercise: String, weight: Double, reps: Int, isPR: Bool)? {
        var best: (exercise: String, weight: Double, reps: Int, estimated1RM: Double, isPR: Bool)?

        for exercise in session.exercises {
            for set in exercise.sets {
                if let weight = set.weight, let reps = set.reps, reps >= 1 && reps <= 10 {
                    let estimated = viewModel.calculateEstimated1RM(weight: weight, reps: reps)
                    if best == nil || estimated > best!.estimated1RM {
                        let isPR = checkIfPR(exercise: exercise.exercise.name, weight: weight, reps: reps, sessionDate: session.endTime)
                        best = (exercise.exercise.name, weight, reps, estimated, isPR)
                    }
                }
            }
        }

        return best.map { ($0.exercise, $0.weight, $0.reps, $0.isPR) }
    }

    private func checkIfPR(exercise: String, weight: Double, reps: Int, sessionDate: Date) -> Bool {
        let currentEstimated = viewModel.calculateEstimated1RM(weight: weight, reps: reps)
        
        // Check all sessions BEFORE this one
        for oldSession in viewModel.completedSessions {
            // Skip sessions after this one
            if oldSession.endTime >= sessionDate { continue }
            
            for oldExercise in oldSession.exercises {
                // Match exercise name (case insensitive, contains)
                if oldExercise.exercise.name.lowercased().contains(exercise.lowercased()) ||
                   exercise.lowercased().contains(oldExercise.exercise.name.lowercased()) {
                    for oldSet in oldExercise.sets {
                        if let oldWeight = oldSet.weight, let oldReps = oldSet.reps, oldReps >= 1 && oldReps <= 10 {
                            let oldEstimated = viewModel.calculateEstimated1RM(weight: oldWeight, reps: oldReps)
                            // If we find a better or equal estimated 1RM in the past, it's not a PR
                            if oldEstimated >= currentEstimated {
                                return false
                            }
                        }
                    }
                }
            }
        }
        
        return true
    }
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(dateString)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(StepCompColors.textSecondary)
                
                if let best = bestSet {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(unitManager.formatWeight(best.weight, decimals: 1))
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(StepCompColors.textPrimary)
                        Text(unitManager.weightUnit.lowercased())
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(StepCompColors.textSecondary)
                        Text("×")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(StepCompColors.textSecondary)
                        Text("\(best.reps)")
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(StepCompColors.textPrimary)
                        Text("reps")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(StepCompColors.textSecondary)
                    }
                    
                    Text(best.exercise)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(StepCompColors.textSecondary)
                } else {
                    Text(session.workoutName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(StepCompColors.textPrimary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                // Gear icon for editing
                Button(action: {
                    sessionToEdit = session
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(StepCompColors.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(StepCompColors.textSecondary.opacity(0.1))
                        .cornerRadius(18)
                }
                
                if let best = bestSet, best.isPR {
                    Text("NEW PR")
                        .font(.system(size: 10, weight: .black))
                        .tracking(0.5)
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(StepCompColors.primary)
                        .cornerRadius(12)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(StepCompColors.textSecondary.opacity(0.3))
                }
            }
        }
        .padding(16)
        .background(cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: 1)
        )
    }
}
