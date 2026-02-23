//
//  ActiveWorkoutView.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 2/16/26.
//

import SwiftUI

struct ActiveWorkoutView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @ObservedObject var unitManager = UnitPreferenceManager.shared
    @State private var showingFinishConfirmation = false
    @FocusState private var focusedField: UUID?
    
    /// True when a set weight/reps field is focused (keyboard likely open) – we collapse the Finish area to give more room.
    private var isEditing: Bool { focusedField != nil }
    
    var body: some View {
        ZStack {
            StepCompColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                header
                
                // Exercise list – more bottom padding when not typing so Finish button doesn’t cover content
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            if let session = viewModel.currentSession {
                                ForEach(session.exercises) { workoutExercise in
                                    ExerciseCard(
                                        workoutExercise: workoutExercise,
                                        viewModel: viewModel,
                                        unitManager: unitManager,
                                        focusedField: $focusedField
                                    )
                                }
                            }
                        }
                        .padding(20)
                        .padding(.bottom, isEditing ? 24 : 150)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            focusedField = nil
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: focusedField) { _, newValue in
                        if let id = newValue {
                            withAnimation(.easeOut(duration: 0.25)) {
                                scrollProxy.scrollTo(id, anchor: .center)
                            }
                        }
                    }
                }
                
                // Bottom action area – hidden while typing so the keypad doesn’t compete with the big button; more room to see inputs
                if !isEditing {
                    Spacer()
                    bottomActionArea
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button(action: {
                        focusedField = nil
                    }) {
                        Text("Done")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(StepCompColors.primary)
                    }
                }
            }
        }
        .confirmationDialog("End Workout", isPresented: $showingFinishConfirmation, titleVisibility: .visible) {
            Button("Finish Workout") {
                viewModel.finishWorkout()
            }
            Button("Cancel Workout", role: .destructive) {
                viewModel.cancelWorkout()
            }
            Button("Keep Training", role: .cancel) {}
        } message: {
            Text("Would you like to finish and save this workout, or cancel without saving?")
        }
    }
    
    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Text(viewModel.currentSession?.workoutName ?? "Workout")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(StepCompColors.textPrimary)
                
                Spacer()
                
                // Timer and pause/resume button
                HStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "timer")
                            .font(.system(size: 14, weight: .bold))
                        Text(viewModel.formattedElapsedTime())
                            .font(.system(size: 14, weight: .black))
                            .monospacedDigit()
                    }
                    .foregroundColor(StepCompColors.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(StepCompColors.textSecondary.opacity(0.1))
                    .cornerRadius(20)
                    
                    // Pause/Resume button
                    Button(action: {
                        if viewModel.isPaused {
                            viewModel.resumeWorkout()
                        } else {
                            viewModel.pauseWorkout()
                        }
                    }) {
                        Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.black)
                            .cornerRadius(16)
                    }
                }
            }
            
            if let session = viewModel.currentSession {
                HStack(spacing: 4) {
                    Text("Monday Routine")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(StepCompColors.textSecondary)
                    Text("•")
                        .foregroundColor(StepCompColors.textSecondary)
                    Text("\(session.exercises.count) Exercises")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(StepCompColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .background(StepCompColors.surface.opacity(0.9))
        .overlay(
            Rectangle()
                .fill(StepCompColors.divider.opacity(0.1))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    private var bottomActionArea: some View {
        VStack(spacing: 0) {
            // Gradient overlay (slimmer so more room for content)
            LinearGradient(
                colors: [
                    StepCompColors.background.opacity(0),
                    StepCompColors.background,
                    StepCompColors.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)
            
            // Action buttons – compact height so list has more room
            Button(action: {
                showingFinishConfirmation = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "flag.checkered.2.crossed")
                        .font(.system(size: 16, weight: .bold))
                    Text("END WORKOUT")
                        .font(.system(size: 16, weight: .black))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(StepCompColors.primary)
                .foregroundColor(StepCompColors.buttonTextOnPrimary)
                .cornerRadius(26)
                .shadow(color: StepCompColors.primary.opacity(0.25), radius: 12, x: 0, y: 6)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .background(StepCompColors.background)
        }
    }
}

struct ExerciseCard: View {
    let workoutExercise: WorkoutExercise
    @ObservedObject var viewModel: WorkoutViewModel
    @ObservedObject var unitManager: UnitPreferenceManager
    @FocusState.Binding var focusedField: UUID?
    @State private var expandedSetId: UUID?
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var allSetsCompleted: Bool {
        workoutExercise.sets.allSatisfy { $0.isCompleted }
    }
    
    private var hasProgressiveOverloadSuggestions: Bool {
        workoutExercise.sets.contains { $0.suggestedWeight != nil && $0.suggestedReps != nil }
    }
    
    private var targetsMetOrExceeded: Int {
        workoutExercise.sets.filter { set in
            guard let weight = set.weight, let reps = set.reps,
                  let sugWeight = set.suggestedWeight, let sugReps = set.suggestedReps else {
                return false
            }
            return weight >= sugWeight || reps >= sugReps
        }.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Exercise header
            HStack(spacing: 12) {
                // Exercise image placeholder
                RoundedRectangle(cornerRadius: 16)
                    .fill(StepCompColors.textSecondary.opacity(0.1))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "dumbbell")
                            .foregroundColor(StepCompColors.textSecondary)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(workoutExercise.exercise.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(StepCompColors.textPrimary)
                    HStack(spacing: 8) {
                        Text("Target: \(workoutExercise.exercise.targetMuscles)")
                            .font(.system(size: 12))
                            .foregroundColor(StepCompColors.textSecondary)
                        
                        if hasProgressiveOverloadSuggestions && !allSetsCompleted {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 10))
                                Text("Progressive")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundColor(StepCompColors.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(StepCompColors.primary.opacity(0.15))
                            .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .opacity(allSetsCompleted ? 0.5 : 1.0)
            
            // Sets header
            HStack(spacing: 12) {
                Text("SET")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(StepCompColors.textSecondary.opacity(0.5))
                    .frame(width: 30, alignment: .leading)
                
                Text("PREV")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(StepCompColors.textSecondary.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("TARGET")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(StepCompColors.primary.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(unitManager.weightUnit)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(StepCompColors.textSecondary.opacity(0.5))
                    .frame(width: 80, alignment: .center)
                
                Text("REPS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(StepCompColors.textSecondary.opacity(0.5))
                    .frame(width: 80, alignment: .center)
                
                Spacer()
                    .frame(width: 40)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
            // Sets list (each row has .id for ScrollViewReader so focused set scrolls into view)
            VStack(spacing: 8) {
                ForEach(workoutExercise.sets) { set in
                    SetRow(
                        set: set,
                        exerciseId: workoutExercise.id,
                        viewModel: viewModel,
                        unitManager: unitManager,
                        focusedField: $focusedField
                    )
                    .id(set.id)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            
            // Add set button
            Button(action: {
                viewModel.addSet(exerciseId: workoutExercise.id)
            }) {
                Text("+ ADD SET")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(StepCompColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(StepCompColors.textSecondary.opacity(0.05))
            }
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
        .cornerRadius(20)
        .shadow(color: StepCompColors.shadowSecondary, radius: 10, x: 0, y: 4)
    }
}

struct SetRow: View {
    let set: WorkoutSet
    let exerciseId: UUID
    @ObservedObject var viewModel: WorkoutViewModel
    @ObservedObject var unitManager: UnitPreferenceManager
    @FocusState.Binding var focusedField: UUID?
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var weightText: String
    @State private var repsText: String
    @State private var showSuggestionApplied: Bool = false
    
    init(set: WorkoutSet, exerciseId: UUID, viewModel: WorkoutViewModel, unitManager: UnitPreferenceManager, focusedField: FocusState<UUID?>.Binding) {
        self.set = set
        self.exerciseId = exerciseId
        self.viewModel = viewModel
        self.unitManager = unitManager
        self._focusedField = focusedField
        // Convert stored weight (kg) to display unit (lbs or kg)
        _weightText = State(initialValue: set.weight.map { String(Int(unitManager.convertWeightFromStorage(Double($0)).rounded())) } ?? "")
        _repsText = State(initialValue: set.reps.map { String($0) } ?? "")
    }
    
    /// Light blue for completed-set checkmark so it stands out
    private static let setCompleteCheckmarkBlue = Color(red: 0.45, green: 0.78, blue: 0.95)

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Set number
                Text("\(set.setNumber)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(set.isCompleted ? StepCompColors.textSecondary.opacity(0.3) : StepCompColors.textSecondary)
                    .frame(width: 30, alignment: .leading)
                
                // Previous set
                Text(previousSetText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(StepCompColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Suggested target (progressive overload) - tappable to apply
                if !set.isCompleted && set.suggestedWeight != nil && set.suggestedReps != nil {
                    Button(action: applySuggestion) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 9, weight: .bold))
                            Text(suggestedText)
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(StepCompColors.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(StepCompColors.primary.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(suggestedText)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(StepCompColors.textSecondary.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Weight input
                TextField("", text: $weightText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(StepCompColors.textPrimary)
                    .frame(width: 80, height: 40)
                    .background(set.isCompleted ? StepCompColors.textSecondary.opacity(0.1) : (colorScheme == .dark ? StepCompColors.surface : Color.white))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(inputBorderColor, lineWidth: 2)
                    )
                    .focused($focusedField, equals: set.id)
                    .disabled(set.isCompleted)
                    .onChange(of: weightText) { oldValue, newValue in
                        if let displayWeight = Int(newValue) {
                            // Convert from display unit (lbs or kg) to storage unit (kg)
                            let storageWeight = Int(unitManager.convertWeightToStorage(Double(displayWeight)).rounded())
                            viewModel.updateSet(exerciseId: exerciseId, setId: set.id, weight: storageWeight, reps: set.reps)
                        }
                    }
                    .onTapGesture {
                        focusedField = set.id
                    }
                
                // Reps input
                TextField("", text: $repsText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(StepCompColors.textPrimary)
                    .frame(width: 80, height: 40)
                    .background(set.isCompleted ? StepCompColors.textSecondary.opacity(0.1) : (colorScheme == .dark ? StepCompColors.surface : Color.white))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(inputBorderColor, lineWidth: 2)
                    )
                    .focused($focusedField, equals: set.id)
                    .disabled(set.isCompleted)
                    .onChange(of: repsText) { oldValue, newValue in
                        if let reps = Int(newValue) {
                            viewModel.updateSet(exerciseId: exerciseId, setId: set.id, weight: set.weight, reps: reps)
                        }
                    }
                    .onTapGesture {
                        focusedField = set.id
                    }
                
                // Complete/Delete buttons
                if set.isCompleted {
                    // Delete button for completed sets
                    Button(action: {
                        viewModel.removeSet(exerciseId: exerciseId, setId: set.id)
                    }) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.red)
                            .cornerRadius(18)
                    }
                } else {
                    // Complete button for incomplete sets — light blue checkmark to stand out
                    Button(action: {
                        viewModel.completeSet(exerciseId: exerciseId, setId: set.id)
                    }) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Self.setCompleteCheckmarkBlue)
                            .frame(width: 36, height: 36)
                            .background(StepCompColors.textSecondary.opacity(0.2))
                            .cornerRadius(18)
                    }
                }
            }
            
            // Target met indicator
            if targetMetOrExceeded && !set.isCompleted {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                    Text("Target achieved! 🎯")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.green)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 42)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundFill)
        )
        .opacity(set.isCompleted ? 0.5 : 1.0)
        .contextMenu {
            // Context menu for deleting uncompleted sets
            if !set.isCompleted {
                Button(role: .destructive) {
                    viewModel.removeSet(exerciseId: exerciseId, setId: set.id)
                } label: {
                    Label("Delete Set", systemImage: "trash")
                }
            }
        }
    }
    
    private var backgroundFill: Color {
        if set.isCompleted {
            return Self.setCompleteCheckmarkBlue.opacity(0.18)
        } else if targetMetOrExceeded {
            return Color.green.opacity(0.08)
        }
        return Color.clear
    }
    
    private var inputBorderColor: Color {
        if focusedField == set.id {
            return StepCompColors.primary
        } else if targetMetOrExceeded && !set.isCompleted {
            return Color.green.opacity(0.5)
        }
        return StepCompColors.textSecondary.opacity(0.2)
    }
    
    private var targetMetOrExceeded: Bool {
        guard let weight = set.weight, let reps = set.reps,
              let sugWeight = set.suggestedWeight, let sugReps = set.suggestedReps else {
            return false
        }
        // Target is met if either weight OR reps meet/exceed suggestion
        return weight >= sugWeight || reps >= sugReps
    }
    
    private func applySuggestion() {
        guard let sugWeight = set.suggestedWeight, let sugReps = set.suggestedReps else { return }
        // Convert suggested weight (stored in kg) to display unit
        let displayWeight = Int(unitManager.convertWeightFromStorage(Double(sugWeight)).rounded())
        weightText = String(displayWeight)
        repsText = String(sugReps)
        // sugWeight is already in kg, so use it directly
        viewModel.updateSet(exerciseId: exerciseId, setId: set.id, weight: sugWeight, reps: sugReps)
        HapticManager.shared.light()
    }
    
    private var previousSetText: String {
        if let prevWeight = set.previousWeight, let prevReps = set.previousReps {
            // Convert stored weight (kg) to display unit
            let displayWeight = Int(unitManager.convertWeightFromStorage(Double(prevWeight)).rounded())
            return "\(displayWeight)x\(prevReps)"
        }
        return "-"
    }
    
    private var suggestedText: String {
        if let sugWeight = set.suggestedWeight, let sugReps = set.suggestedReps {
            // Convert stored weight (kg) to display unit
            let displayWeight = Int(unitManager.convertWeightFromStorage(Double(sugWeight)).rounded())
            return "\(displayWeight)x\(sugReps)"
        }
        return "-"
    }
}

#Preview {
    ActiveWorkoutView(viewModel: WorkoutViewModel.shared)
}
