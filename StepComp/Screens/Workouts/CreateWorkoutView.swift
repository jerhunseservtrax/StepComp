//
//  CreateWorkoutView.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 2/16/26.
//

import SwiftUI

struct CreateWorkoutView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: WorkoutViewModel
    var editingWorkout: Workout? = nil
    
    @State private var workoutName = ""
    @State private var selectedExercises: [SelectedExercise] = []
    @State private var selectedDays: Set<DayOfWeek> = []
    @State private var isOneTimeWorkout = false
    @State private var currentStep: CreateWorkoutStep = .nameWorkout
    @State private var showingExercisePicker = false
    
    enum CreateWorkoutStep {
        case nameWorkout
        case selectExercises
        case configureSets
        case selectDays
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                FitCompColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress indicator
                    progressIndicator
                    
                    // Content based on step
                    ScrollView {
                        VStack(spacing: 24) {
                            switch currentStep {
                            case .nameWorkout:
                                nameWorkoutStep
                            case .selectExercises:
                                selectExercisesStep
                            case .configureSets:
                                configureSetsStep
                            case .selectDays:
                                selectDaysStep
                            }
                        }
                        .padding(20)
                        .padding(.bottom, 100)
                    }
                    
                    // Bottom action buttons
                    bottomActionBar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView { exercise in
                let newExercise = SelectedExercise(exercise: exercise, sets: 3, reps: 10)
                selectedExercises.append(newExercise)
            }
        }
        .onAppear {
            if let workout = editingWorkout {
                workoutName = workout.name
                selectedExercises = workout.exercises.map { we in
                    SelectedExercise(
                        id: we.id,
                        exercise: we.exercise,
                        sets: we.sets.count,
                        reps: we.sets.first?.previousReps ?? we.sets.first?.reps ?? 10
                    )
                }
                selectedDays = Set(workout.assignedDays)
                isOneTimeWorkout = workout.isOneTime
            }
        }
    }
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<4) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index <= stepIndex ? FitCompColors.primary : Color.gray.opacity(0.2))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    private var stepIndex: Int {
        switch currentStep {
        case .nameWorkout: return 0
        case .selectExercises: return 1
        case .configureSets: return 2
        case .selectDays: return 3
        }
    }
    
    // MARK: - Name Workout Step
    
    private var nameWorkoutStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Name Your Workout")
                .font(.system(size: 28, weight: .black))
                .foregroundColor(.black)
            
            Text("Give your workout a memorable name")
                .font(.system(size: 16))
                .foregroundColor(.gray)
            
            TextField("e.g., Upper Body A, Leg Day", text: $workoutName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .padding(.top, 8)
        }
    }
    
    // MARK: - Select Exercises Step
    
    private var selectExercisesStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Exercises")
                .font(.system(size: 28, weight: .black))
                .foregroundColor(.black)
            
            Text("Add exercises to your workout")
                .font(.system(size: 16))
                .foregroundColor(.gray)
            
            if selectedExercises.isEmpty {
                emptyExerciseState
            } else {
                exerciseList
            }
            
            Button(action: { showingExercisePicker = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Exercise")
                        .font(.system(size: 16, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(FitCompColors.primary, lineWidth: 2)
                )
            }
        }
    }
    
    private var emptyExerciseState: some View {
        VStack(spacing: 12) {
            Image(systemName: "dumbbell")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.3))
            
            Text("No exercises added yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .background(Color.white)
        .cornerRadius(16)
    }
    
    private var exerciseList: some View {
        VStack(spacing: 12) {
            ForEach(Array(selectedExercises.enumerated()), id: \.element.id) { index, exercise in
                HStack(spacing: 10) {
                    VStack(spacing: 0) {
                        Button {
                            guard index > 0 else { return }
                            selectedExercises.swapAt(index, index - 1)
                            HapticManager.shared.soft()
                        } label: {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(index > 0 ? FitCompColors.primary : Color.gray.opacity(0.25))
                                .frame(width: 32, height: 22)
                        }
                        .disabled(index == 0)
                        .accessibilityLabel("Move exercise up")

                        Button {
                            guard index < selectedExercises.count - 1 else { return }
                            selectedExercises.swapAt(index, index + 1)
                            HapticManager.shared.soft()
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(index < selectedExercises.count - 1 ? FitCompColors.primary : Color.gray.opacity(0.25))
                                .frame(width: 32, height: 22)
                        }
                        .disabled(index >= selectedExercises.count - 1)
                        .accessibilityLabel("Move exercise down")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.exercise.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                        Text(exercise.exercise.targetMuscles)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Button(action: {
                        selectedExercises.remove(at: index)
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .frame(width: 36, height: 36)
                    }
                    .accessibilityLabel("Remove exercise")
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Configure Sets Step
    
    private var configureSetsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Configure Sets & Reps")
                .font(.system(size: 28, weight: .black))
                .foregroundColor(.black)
            
            Text("Set default sets and reps for each exercise")
                .font(.system(size: 16))
                .foregroundColor(.gray)
            
            VStack(spacing: 12) {
                ForEach(Array(selectedExercises.enumerated()), id: \.element.id) { index, exercise in
                    ExerciseConfigCard(
                        exercise: exercise,
                        onSetsChange: { newSets in
                            selectedExercises[index].sets = newSets
                        },
                        onRepsChange: { newReps in
                            selectedExercises[index].reps = newReps
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Select Days Step
    
    private var selectDaysStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Schedule")
                .font(.system(size: 28, weight: .black))
                .foregroundColor(.black)

            Text("How often do you want to do this workout?")
                .font(.system(size: 16))
                .foregroundColor(.gray)

            // Today Only option
            Button(action: {
                isOneTimeWorkout = true
                selectedDays.removeAll()
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Today Only")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(FitCompColors.textPrimary)
                        Text("One-time workout for \(todayFormatted)")
                            .font(.system(size: 13))
                            .foregroundColor(FitCompColors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: isOneTimeWorkout ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(isOneTimeWorkout ? FitCompColors.primary : FitCompColors.textTertiary)
                }
                .padding(16)
                .background(isOneTimeWorkout ? FitCompColors.primary.opacity(0.1) : FitCompColors.surface)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isOneTimeWorkout ? FitCompColors.primary : FitCompColors.cardBorder, lineWidth: isOneTimeWorkout ? 2 : 1)
                )
            }

            // Divider with "or"
            HStack {
                Rectangle()
                    .fill(FitCompColors.textTertiary.opacity(0.3))
                    .frame(height: 1)
                Text("or repeat on")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(FitCompColors.textTertiary)
                Rectangle()
                    .fill(FitCompColors.textTertiary.opacity(0.3))
                    .frame(height: 1)
            }

            // Recurring day selection
            VStack(spacing: 12) {
                ForEach(DayOfWeek.allCases) { day in
                    DaySelectionButton(
                        day: day,
                        isSelected: selectedDays.contains(day),
                        action: {
                            isOneTimeWorkout = false
                            if selectedDays.contains(day) {
                                selectedDays.remove(day)
                            } else {
                                selectedDays.insert(day)
                            }
                        }
                    )
                }
            }
        }
    }

    private var todayFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }
    
    // MARK: - Bottom Action Bar
    
    private var bottomActionBar: some View {
        HStack(spacing: 12) {
            if currentStep != .nameWorkout {
                Button(action: previousStep) {
                    Text("Back")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.black)
                        .cornerRadius(28)
                }
            }
            
            Button(action: nextStep) {
                Text(currentStep == .selectDays ? (editingWorkout != nil ? "Save Changes" : "Create Workout") : "Next")
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(canProceed ? FitCompColors.primary : Color.gray.opacity(0.3))
                    .foregroundColor(.black)
                    .cornerRadius(28)
            }
            .disabled(!canProceed)
        }
        .padding(20)
        .background(Color.white)
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case .nameWorkout:
            return !workoutName.trimmingCharacters(in: .whitespaces).isEmpty
        case .selectExercises:
            return !selectedExercises.isEmpty
        case .configureSets:
            return true
        case .selectDays:
            return isOneTimeWorkout || !selectedDays.isEmpty
        }
    }
    
    private func nextStep() {
        HapticManager.shared.soft()
        
        switch currentStep {
        case .nameWorkout:
            currentStep = .selectExercises
        case .selectExercises:
            currentStep = .configureSets
        case .configureSets:
            currentStep = .selectDays
        case .selectDays:
            createWorkout()
        }
    }
    
    private func previousStep() {
        HapticManager.shared.soft()
        
        switch currentStep {
        case .nameWorkout:
            break
        case .selectExercises:
            currentStep = .nameWorkout
        case .configureSets:
            currentStep = .selectExercises
        case .selectDays:
            currentStep = .configureSets
        }
    }
    
    private func createWorkout() {
        let workoutExercises = selectedExercises.map { selectedExercise in
            let sets = (1...selectedExercise.sets).map { setNumber in
                WorkoutSet(setNumber: setNumber)
            }
            return WorkoutExercise(
                id: selectedExercise.id,
                exercise: selectedExercise.exercise,
                sets: sets
            )
        }
        
        let oneTime: Date? = isOneTimeWorkout ? Calendar.current.startOfDay(for: Date()) : nil

        if let existing = editingWorkout {
            let workout = Workout(
                id: existing.id,
                name: workoutName,
                exercises: workoutExercises,
                assignedDays: Array(selectedDays),
                createdAt: existing.createdAt,
                lastCompletedAt: existing.lastCompletedAt,
                oneTimeDate: oneTime
            )
            viewModel.updateWorkout(workout)
        } else {
            let workout = Workout(
                name: workoutName,
                exercises: workoutExercises,
                assignedDays: Array(selectedDays),
                oneTimeDate: oneTime
            )
            viewModel.addWorkout(workout)
        }
        HapticManager.shared.success()
        dismiss()
    }
}

struct SelectedExercise: Identifiable {
    let id: UUID
    let exercise: Exercise
    var sets: Int
    var reps: Int

    init(id: UUID = UUID(), exercise: Exercise, sets: Int, reps: Int) {
        self.id = id
        self.exercise = exercise
        self.sets = sets
        self.reps = reps
    }
}

struct ExerciseConfigCard: View {
    let exercise: SelectedExercise
    let onSetsChange: (Int) -> Void
    let onRepsChange: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(exercise.exercise.name)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SETS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                    
                    HStack {
                        Button(action: {
                            if exercise.sets > 1 {
                                onSetsChange(exercise.sets - 1)
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(exercise.sets > 1 ? FitCompColors.primary : Color.gray.opacity(0.3))
                        }
                        
                        Text("\(exercise.sets)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 40)
                        
                        Button(action: {
                            if exercise.sets < 10 {
                                onSetsChange(exercise.sets + 1)
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(exercise.sets < 10 ? FitCompColors.primary : Color.gray.opacity(0.3))
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("REPS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                    
                    HStack {
                        Button(action: {
                            if exercise.reps > 1 {
                                onRepsChange(exercise.reps - 1)
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(exercise.reps > 1 ? FitCompColors.primary : Color.gray.opacity(0.3))
                        }
                        
                        Text("\(exercise.reps)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 40)
                        
                        Button(action: {
                            if exercise.reps < 50 {
                                onRepsChange(exercise.reps + 1)
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(exercise.reps < 50 ? FitCompColors.primary : Color.gray.opacity(0.3))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
    }
}

struct DaySelectionButton: View {
    let day: DayOfWeek
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(day.fullName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(FitCompColors.textPrimary)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? FitCompColors.primary : FitCompColors.textTertiary)
            }
            .padding(16)
            .background(isSelected ? FitCompColors.primary.opacity(0.1) : FitCompColors.surface)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? FitCompColors.primary : FitCompColors.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

#Preview {
    CreateWorkoutView(viewModel: WorkoutViewModel.shared)
}
