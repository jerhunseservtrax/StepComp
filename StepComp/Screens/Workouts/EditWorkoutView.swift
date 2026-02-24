//
//  EditWorkoutView.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 2/16/26.
//

import SwiftUI

struct EditWorkoutView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: WorkoutViewModel
    @State var workout: Workout
    
    @State private var workoutName: String
    @State private var selectedExercises: [SelectedExercise]
    @State private var selectedDays: Set<DayOfWeek>
    @State private var showingExercisePicker = false
    @State private var showingDeleteConfirmation = false
    
    init(viewModel: WorkoutViewModel, workout: Workout) {
        self.viewModel = viewModel
        self._workout = State(initialValue: workout)
        self._workoutName = State(initialValue: workout.name)
        self._selectedDays = State(initialValue: Set(workout.assignedDays))
        
        // Convert workout exercises to selected exercises
        let exercises = workout.exercises.map { workoutExercise in
            SelectedExercise(
                exercise: workoutExercise.exercise,
                sets: workoutExercise.sets.count,
                reps: workoutExercise.sets.first?.reps ?? 10
            )
        }
        self._selectedExercises = State(initialValue: exercises)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                StepCompColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Workout name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("WORKOUT NAME")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.gray)
                            
                            TextField("Workout name", text: $workoutName)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(16)
                        }
                        
                        // Exercises
                        VStack(alignment: .leading, spacing: 12) {
                            Text("EXERCISES")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.gray)
                            
                            if selectedExercises.isEmpty {
                                Text("No exercises added")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 100)
                                    .background(Color.white)
                                    .cornerRadius(16)
                            } else {
                                ForEach(Array(selectedExercises.enumerated()), id: \.element.id) { index, exercise in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(exercise.exercise.name)
                                                .font(.system(size: 16, weight: .bold))
                                            Text("\(exercise.sets) sets × \(exercise.reps) reps")
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
                                    }
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                }
                            }
                            
                            Button(action: { showingExercisePicker = true }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Exercise")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.white)
                                .foregroundColor(.black)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(StepCompColors.primary, lineWidth: 2)
                                )
                            }
                        }
                        
                        // Days
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ASSIGNED DAYS")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.gray)
                            
                            ForEach(DayOfWeek.allCases) { day in
                                DaySelectionButton(
                                    day: day,
                                    isSelected: selectedDays.contains(day),
                                    action: {
                                        if selectedDays.contains(day) {
                                            selectedDays.remove(day)
                                        } else {
                                            selectedDays.insert(day)
                                        }
                                    }
                                )
                            }
                        }
                        
                        // Delete workout button
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Delete Workout")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(16)
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 100)
                }
                
                // Save button
                VStack {
                    Spacer()
                    Button(action: saveWorkout) {
                        Text("Save Changes")
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(canSave ? StepCompColors.primary : Color.gray.opacity(0.3))
                            .foregroundColor(.black)
                            .cornerRadius(28)
                    }
                    .disabled(!canSave)
                    .padding(20)
                    .background(Color.white)
                }
            }
            .navigationTitle("Edit Workout")
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
        .confirmationDialog("Delete Workout", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete Workout", role: .destructive) {
                viewModel.deleteWorkout(workout)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this workout? This action cannot be undone.")
        }
    }
    
    private var canSave: Bool {
        !workoutName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !selectedExercises.isEmpty &&
        !selectedDays.isEmpty
    }
    
    private func saveWorkout() {
        let workoutExercises = selectedExercises.map { selectedExercise in
            let sets = (1...selectedExercise.sets).map { setNumber in
                WorkoutSet(setNumber: setNumber)
            }
            return WorkoutExercise(
                exercise: selectedExercise.exercise,
                sets: sets
            )
        }
        
        let updatedWorkout = Workout(
            id: workout.id,
            name: workoutName,
            exercises: workoutExercises,
            assignedDays: Array(selectedDays),
            createdAt: workout.createdAt,
            lastCompletedAt: workout.lastCompletedAt
        )
        
        viewModel.updateWorkout(updatedWorkout)
        HapticManager.shared.success()
        dismiss()
    }
}

#Preview {
    EditWorkoutView(
        viewModel: WorkoutViewModel.shared,
        workout: Workout(
            name: "Upper Body",
            exercises: [],
            assignedDays: [.monday, .wednesday]
        )
    )
}
