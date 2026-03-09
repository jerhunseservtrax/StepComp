//
//  WorkoutDetailView.swift
//  StepComp
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                StepCompColors.background.ignoresSafeArea()
                
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
                                    tabManager.selectedTab = 3
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
                            .background(StepCompColors.primary)
                            .foregroundColor(StepCompColors.buttonTextOnPrimary)
                            .cornerRadius(28)
                            .shadow(color: StepCompColors.primary.opacity(0.3), radius: 16, x: 0, y: 8)
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
                        .fill(StepCompColors.primary.opacity(0.2))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 28))
                        .foregroundColor(StepCompColors.primary)
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
                .foregroundColor(StepCompColors.textPrimary)
            
            if let lastCompleted = workout.lastCompletedAt {
                Text("Last completed: \(formatDate(lastCompleted))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(StepCompColors.textSecondary)
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
            Text("WORKOUT INFO")
                .font(.system(size: 13, weight: .black))
                .tracking(1.5)
                .foregroundColor(StepCompColors.textSecondary)
            
            VStack(spacing: 12) {
                InfoRow(
                    icon: "calendar",
                    label: "Scheduled Days",
                    value: workout.assignedDays.map { $0.rawValue }.joined(separator: ", ")
                )
                
                InfoRow(
                    icon: "dumbbell",
                    label: "Exercises",
                    value: "\(workout.exercises.count)"
                )
                
                let totalSets = workout.exercises.reduce(0) { $0 + $1.sets.count }
                InfoRow(
                    icon: "list.bullet",
                    label: "Total Sets",
                    value: "\(totalSets)"
                )
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
    
    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("EXERCISES")
                .font(.system(size: 13, weight: .black))
                .tracking(1.5)
                .foregroundColor(StepCompColors.textSecondary)
            
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
}

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(StepCompColors.primary)
                    .frame(width: 24)
                
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(StepCompColors.textSecondary)
            }
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(StepCompColors.textPrimary)
        }
        .padding(.vertical, 4)
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
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    // Exercise number badge
                    Text("\(exerciseNumber)")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.black)
                        .frame(width: 32, height: 32)
                        .background(StepCompColors.primary)
                        .cornerRadius(16)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workoutExercise.exercise.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(StepCompColors.textPrimary)
                        
                        HStack(spacing: 4) {
                            Text(workoutExercise.exercise.targetMuscles)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(StepCompColors.textSecondary)
                            Text("•")
                                .foregroundColor(StepCompColors.textSecondary)
                            Text("\(workoutExercise.sets.count) sets")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(StepCompColors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(StepCompColors.textSecondary)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
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
                        .foregroundColor(colorScheme == .dark ? StepCompColors.primary : .black)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
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
                .foregroundColor(StepCompColors.textSecondary)
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
                        .foregroundColor(StepCompColors.textSecondary)
                    Text("×")
                        .font(.system(size: 12))
                        .foregroundColor(StepCompColors.textSecondary)
                    Text("\(prevReps)")
                        .font(.system(size: 14, weight: .bold))
                    Text("reps")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(StepCompColors.textSecondary)
                }
                .foregroundColor(StepCompColors.textPrimary)
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
                        .foregroundColor(StepCompColors.textSecondary)
                    Text("×")
                        .font(.system(size: 12))
                        .foregroundColor(StepCompColors.textSecondary)
                    Text("\(suggestedReps)")
                        .font(.system(size: 14, weight: .bold))
                    Text("reps")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(StepCompColors.textSecondary)
                }
                .foregroundColor(StepCompColors.textPrimary.opacity(0.7))
            } else {
                Text("—")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(StepCompColors.textSecondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(StepCompColors.textSecondary.opacity(0.05))
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
