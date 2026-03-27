//
//  WorkoutDetailView.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 2/23/26.
//

import SwiftUI

struct WorkoutDetailView: View {
    let workout: Workout
    let selectedDate: Date?
    @ObservedObject var viewModel: WorkoutViewModel
    @ObservedObject var unitManager = UnitPreferenceManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    var tabManager: TabSelectionManager?
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color(hex: "1a1a1a") : Color.white
    }
    
    private var isCompleted: Bool {
        if let date = selectedDate {
            return viewModel.wasWorkoutCompleted(workout: workout, on: date)
        }
        return false
    }

    private var totalSets: Int {
        workout.exercises.reduce(0) { $0 + $1.sets.count }
    }

    private var workoutMuscleGroups: [MuscleGroup] {
        let allTargetStrings = workout.exercises.map { $0.exercise.targetMuscles.lowercased() }
        return MuscleGroup.allCases.filter { group in
            allTargetStrings.contains(where: { target in
                group.matchKeywords.contains(where: { target.contains($0.lowercased()) })
            })
        }
    }

    private var projectedVolume: Double {
        workout.exercises.reduce(0) { runningTotal, workoutExercise in
            runningTotal + workoutExercise.sets.reduce(0) { setTotal, set in
                if let previousWeight = set.previousWeight, let previousReps = set.previousReps {
                    return setTotal + (previousWeight * Double(previousReps))
                }
                if let suggestedWeight = set.suggestedWeight, let suggestedReps = set.suggestedReps {
                    return setTotal + (suggestedWeight * Double(suggestedReps))
                }
                return setTotal
            }
        }
    }

    private var projectedDuration: TimeInterval {
        let matchingSessions = viewModel.completedSessions.filter {
            $0.workoutId == workout.id || namesMatch($0.workoutName, workout.name)
        }

        if !matchingSessions.isEmpty {
            let totalDuration = matchingSessions.reduce(0.0) { $0 + $1.duration }
            return totalDuration / Double(matchingSessions.count)
        }

        // Includes expected work and rest time when no historical data exists.
        return TimeInterval(totalSets * 120)
    }

    private var projectedDurationText: String {
        let total = Int(projectedDuration)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                FitCompColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Workout Header
                        workoutHeader
                        
                        // Workout Info
                        workoutInfo
                        
                        // Exercises Section
                        exercisesSection
                        
                        // Start Workout Button (fixed at bottom)
                        Spacer()
                            .frame(height: 80)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                // Floating Start Button
                VStack {
                    Spacer()
                    
                    if isCompleted {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Already Completed Today")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.green.opacity(0.35))
                        .foregroundColor(Color.green)
                        .cornerRadius(28)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    } else {
                        Button(action: {
                            if let date = selectedDate {
                                viewModel.startWorkout(workout, targetDate: date)
                            } else {
                                viewModel.startWorkout(workout, targetDate: Date())
                            }
                            dismiss()
                            // Switch to Workouts tab to show active workout
                            if let tabManager = tabManager {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    tabManager.selectedTab = 1
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Start Workout")
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(FitCompColors.primary)
                            .foregroundColor(FitCompColors.buttonTextOnPrimary)
                            .cornerRadius(28)
                            .shadow(color: FitCompColors.primary.opacity(0.3), radius: 16, x: 0, y: 8)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }
                }
            }
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var workoutHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(FitCompColors.primary.opacity(0.2))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 28))
                        .foregroundColor(FitCompColors.primary)
                }
                
                Spacer()
                
                if isCompleted {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                        Text("COMPLETED")
                            .font(.system(size: 12, weight: .black))
                            .tracking(1)
                    }
                    .foregroundColor(Color.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(12)
                }
            }
            
            Text(workout.name)
                .font(.system(size: 32, weight: .black))
                .foregroundColor(FitCompColors.textPrimary)
            
            if let lastCompleted = workout.lastCompletedAt {
                Text("Last completed: \(formatDate(lastCompleted))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(FitCompColors.textSecondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.clear, lineWidth: 1)
        )
    }
    
    private var workoutInfo: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workout Details")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(FitCompColors.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                DetailMetricCard(title: "Est. Duration", value: projectedDurationText, tint: Color.yellow)
                DetailMetricCard(title: "Exercises", value: "\(workout.exercises.count)", tint: Color.red)
                DetailMetricCard(
                    title: "Est. Volume",
                    value: "\(unitManager.formatWeight(projectedVolume, decimals: 0)) \(unitManager.weightUnit.lowercased())",
                    tint: Color.green
                )
                DetailMetricCard(title: "Total Sets", value: "\(totalSets)", tint: Color.blue)
            }

            HStack(spacing: 8) {
                Text("Muscles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(FitCompColors.textSecondary)

                HStack(spacing: 6) {
                    ForEach(Array(workoutMuscleGroups.prefix(4)), id: \.id) { group in
                        Image(systemName: group.icon)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(FitCompColors.textPrimary)
                            .frame(width: 26, height: 26)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(8)
                    }
                }

                Spacer()

                Text("Exercises \(workout.exercises.count)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(FitCompColors.textSecondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .cornerRadius(18)
    }
    
    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("EXERCISES")
                .font(.system(size: 13, weight: .black))
                .tracking(1.5)
                .foregroundColor(FitCompColors.textSecondary)
            
            VStack(spacing: 12) {
                ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, workoutExercise in
                    ExerciseDetailCard(
                        exerciseNumber: index + 1,
                        workoutExercise: workoutExercise,
                        unitManager: unitManager,
                        viewModel: viewModel
                    )
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func namesMatch(_ lhs: String, _ rhs: String) -> Bool {
        let left = lhs.lowercased()
        let right = rhs.lowercased()
        return left.contains(right) || right.contains(left)
    }
}

struct ExerciseDetailCard: View {
    let exerciseNumber: Int
    let workoutExercise: WorkoutExercise
    @ObservedObject var unitManager: UnitPreferenceManager
    @ObservedObject var viewModel: WorkoutViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var isExpanded = false
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color(hex: "1a1a1a") : Color.white
    }
    
    private var previousData: (weight: Double, reps: Int)? {
        // Get the most recent completed data for this exercise
        for session in viewModel.completedSessions.sorted(by: { $0.endTime > $1.endTime }) {
            for exercise in session.exercises {
                if exercise.exercise.name.lowercased() == workoutExercise.exercise.name.lowercased() {
                    // Find the first completed set
                    if let firstSet = exercise.sets.first(where: { $0.isCompleted }),
                       let weight = firstSet.weight,
                       let reps = firstSet.reps {
                        return (weight, reps)
                    }
                }
            }
        }
        return nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                ExerciseDemoButton(exercise: workoutExercise.exercise, size: 44)

                Button(action: { isExpanded.toggle() }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(workoutExercise.exercise.name)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(FitCompColors.textPrimary)

                            HStack(spacing: 4) {
                                Text(workoutExercise.exercise.targetMuscles)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(FitCompColors.textSecondary)
                                Text("•")
                                    .foregroundColor(FitCompColors.textSecondary)
                                Text("\(workoutExercise.sets.count) sets")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(FitCompColors.textSecondary)
                            }
                        }

                        Spacer()

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(FitCompColors.textSecondary)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(16)
            
            // Expanded set details
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(workoutExercise.sets) { set in
                        SetPreviewRow(
                            set: set,
                            unitManager: unitManager
                        )
                    }
                    
                    // Show previous performance if available
                    if let previous = previousData {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 12))
                            let displayWeight = unitManager.convertWeightFromStorage(previous.weight)
                            let weightStr = displayWeight.truncatingRemainder(dividingBy: 1) == 0
                                ? String(Int(displayWeight))
                                : String(format: "%.1f", displayWeight)
                            Text("Last time: \(weightStr) \(unitManager.weightUnit.lowercased()) × \(previous.reps) reps")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(colorScheme == .dark ? FitCompColors.primary : .black)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)

                        let oneRM = viewModel.calculateEstimated1RM(weight: previous.weight, reps: previous.reps)
                        HStack {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 12))
                            Text(String(format: "Estimated 1RM: %.1f %@", unitManager.convertWeightFromStorage(oneRM), unitManager.weightUnit.lowercased()))
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(FitCompColors.textSecondary)
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .background(cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.clear, lineWidth: 1)
        )
    }
}

struct SetPreviewRow: View {
    let set: WorkoutSet
    @ObservedObject var unitManager: UnitPreferenceManager
    
    var body: some View {
        HStack(spacing: 8) {
            Text("Set \(set.setNumber)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(FitCompColors.textSecondary)
                .frame(width: 60, alignment: .leading)
            
            if let prevWeight = set.previousWeight, let prevReps = set.previousReps {
                HStack(spacing: 4) {
                    let displayWeight = unitManager.convertWeightFromStorage(prevWeight)
                    let weightStr = displayWeight.truncatingRemainder(dividingBy: 1) == 0
                        ? String(Int(displayWeight))
                        : String(format: "%.1f", displayWeight)
                    Text(weightStr)
                        .font(.system(size: 14, weight: .bold))
                    Text(unitManager.weightUnit.lowercased())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(FitCompColors.textSecondary)
                    Text("×")
                        .font(.system(size: 12))
                        .foregroundColor(FitCompColors.textSecondary)
                    Text("\(prevReps)")
                        .font(.system(size: 14, weight: .bold))
                    Text("reps")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(FitCompColors.textSecondary)
                }
                .foregroundColor(FitCompColors.textPrimary)
            } else if let suggestedWeight = set.suggestedWeight, let suggestedReps = set.suggestedReps {
                HStack(spacing: 4) {
                    let displayWeight = unitManager.convertWeightFromStorage(suggestedWeight)
                    let weightStr = displayWeight.truncatingRemainder(dividingBy: 1) == 0
                        ? String(Int(displayWeight))
                        : String(format: "%.1f", displayWeight)
                    Text(weightStr)
                        .font(.system(size: 14, weight: .bold))
                    Text(unitManager.weightUnit.lowercased())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(FitCompColors.textSecondary)
                    Text("×")
                        .font(.system(size: 12))
                        .foregroundColor(FitCompColors.textSecondary)
                    Text("\(suggestedReps)")
                        .font(.system(size: 14, weight: .bold))
                    Text("reps")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(FitCompColors.textSecondary)
                }
                .foregroundColor(FitCompColors.textPrimary.opacity(0.7))
            } else {
                Text("—")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(FitCompColors.textSecondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(FitCompColors.textSecondary.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal, 16)
    }
}

#Preview {
    let sampleExercises = [
        WorkoutExercise(
            exercise: Exercise(name: "Barbell Bench Press", targetMuscles: "Chest, Triceps"),
            sets: [
                WorkoutSet(setNumber: 1, previousWeight: 135, previousReps: 8),
                WorkoutSet(setNumber: 2, previousWeight: 135, previousReps: 8),
                WorkoutSet(setNumber: 3, previousWeight: 135, previousReps: 6),
            ]
        ),
        WorkoutExercise(
            exercise: Exercise(name: "Incline Dumbbell Press", targetMuscles: "Upper Chest"),
            sets: [
                WorkoutSet(setNumber: 1, previousWeight: 50, previousReps: 10),
                WorkoutSet(setNumber: 2, previousWeight: 50, previousReps: 10),
            ]
        ),
    ]
    
    let sampleWorkout = Workout(
        name: "Push Day",
        exercises: sampleExercises,
        assignedDays: [.monday, .thursday]
    )
    
    return WorkoutDetailView(
        workout: sampleWorkout,
        selectedDate: Date(),
        viewModel: WorkoutViewModel.shared
    )
}
