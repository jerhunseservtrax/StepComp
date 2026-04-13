//
//  EditWorkoutView.swift
//  FitComp
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
    @State private var exerciseToConfigure: Exercise? = nil
    
    init(viewModel: WorkoutViewModel, workout: Workout) {
        self.viewModel = viewModel
        self._workout = State(initialValue: workout)
        self._workoutName = State(initialValue: workout.name)
        self._selectedDays = State(initialValue: Set(workout.assignedDays))
        
        // Convert workout exercises to selected exercises
        let exercises = workout.exercises.map { workoutExercise in
            SelectedExercise(
                id: workoutExercise.id,
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
                FitCompColors.background.ignoresSafeArea()

                List {
                    Section {
                        TextField("Workout name", text: $workoutName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(FitCompColors.textPrimary)
                            .padding(16)
                            .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                            .listRowBackground(FitCompColors.surface)
                            .cornerRadius(16)
                    } header: {
                        Text("WORKOUT NAME")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(FitCompColors.textSecondary)
                            .textCase(nil)
                    }

                    Section {
                        if selectedExercises.isEmpty {
                            Text("No exercises added")
                                .font(.system(size: 16))
                                .foregroundColor(FitCompColors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 80)
                                .listRowBackground(FitCompColors.surface)
                        }

                        ForEach(Array(selectedExercises.enumerated()), id: \.element.id) { index, exercise in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.exercise.name)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(FitCompColors.textPrimary)
                                    Text("\(exercise.sets) sets × \(exercise.reps) reps")
                                        .font(.system(size: 12))
                                        .foregroundColor(FitCompColors.textSecondary)
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
                            .padding(.vertical, 4)
                            .listRowBackground(FitCompColors.surface)
                        }
                        .onMove { from, to in
                            selectedExercises.move(fromOffsets: from, toOffset: to)
                            HapticManager.shared.soft()
                        }

                        Button(action: { showingExercisePicker = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Exercise")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .foregroundColor(FitCompColors.textPrimary)
                        }
                        .listRowBackground(FitCompColors.surface)
                    } header: {
                        Text("EXERCISES")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(FitCompColors.textSecondary)
                            .textCase(nil)
                    }

                    Section {
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
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    } header: {
                        Text("ASSIGNED DAYS")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(FitCompColors.textSecondary)
                            .textCase(nil)
                    }

                    Section {
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
                            .foregroundColor(.red)
                        }
                        .listRowBackground(Color.red.opacity(0.1))
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 4)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    Button(action: saveWorkout) {
                        Text("Save Changes")
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(canSave ? FitCompColors.primary : Color.gray.opacity(0.3))
                            .foregroundColor(canSave ? FitCompColors.buttonTextOnPrimary : FitCompColors.textSecondary)
                            .cornerRadius(28)
                    }
                    .disabled(!canSave)
                    .padding(20)
                    .background(FitCompColors.surface)
                }
            }
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(FitCompColors.textPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !selectedExercises.isEmpty {
                        EditButton()
                            .foregroundColor(FitCompColors.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView { exercise in
                exerciseToConfigure = exercise
            }
        }
        .sheet(item: $exerciseToConfigure) { exercise in
            AddExerciseConfigSheet(
                exercise: exercise,
                defaultSets: 3,
                defaultReps: 10,
                onAdd: { sets, reps in
                    selectedExercises.append(SelectedExercise(exercise: exercise, sets: sets, reps: reps))
                    exerciseToConfigure = nil
                },
                onCancel: {
                    exerciseToConfigure = nil
                }
            )
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
                id: selectedExercise.id,
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

// MARK: - Add Exercise Config Sheet

struct AddExerciseConfigSheet: View {
    let exercise: Exercise
    let defaultSets: Int
    let defaultReps: Int
    let onAdd: (Int, Int) -> Void
    let onCancel: () -> Void
    
    @State private var sets: Int
    @State private var reps: Int
    
    init(exercise: Exercise, defaultSets: Int = 3, defaultReps: Int = 10, onAdd: @escaping (Int, Int) -> Void, onCancel: @escaping () -> Void) {
        self.exercise = exercise
        self.defaultSets = defaultSets
        self.defaultReps = defaultReps
        self.onAdd = onAdd
        self.onCancel = onCancel
        self._sets = State(initialValue: defaultSets)
        self._reps = State(initialValue: defaultReps)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                FitCompColors.background.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Set the number of sets and reps for this exercise")
                        .font(.system(size: 16))
                        .foregroundColor(FitCompColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    ExerciseConfigCard(
                        exercise: SelectedExercise(exercise: exercise, sets: sets, reps: reps),
                        onSetsChange: { sets = $0 },
                        onRepsChange: { reps = $0 }
                    )
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    Button(action: {
                        onAdd(sets, reps)
                        HapticManager.shared.success()
                    }) {
                        Text("Add Exercise")
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(FitCompColors.primary)
                            .foregroundColor(FitCompColors.buttonTextOnPrimary)
                            .cornerRadius(28)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .padding(.top, 24)
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(FitCompColors.textPrimary)
                }
            }
        }
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
