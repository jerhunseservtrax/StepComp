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
    @State private var collapsedExerciseIds: Set<UUID> = []
    
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
                                        focusedField: $focusedField,
                                        collapsedExerciseIds: $collapsedExerciseIds
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
        VStack(spacing: 8) {
            HStack {
                Text(viewModel.currentSession?.workoutName ?? "Workout")
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(StepCompColors.textPrimary)
                
                Spacer()
                
                // Timer and pause/resume button
                HStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.system(size: 12, weight: .bold))
                        Text(viewModel.formattedElapsedTime())
                            .font(.system(size: 13, weight: .black))
                            .monospacedDigit()
                    }
                    .foregroundColor(StepCompColors.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(StepCompColors.textSecondary.opacity(0.1))
                    .cornerRadius(16)
                    
                    // Pause/Resume button
                    Button(action: {
                        if viewModel.isPaused {
                            viewModel.resumeWorkout()
                        } else {
                            viewModel.pauseWorkout()
                        }
                    }) {
                        Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.black)
                            .cornerRadius(14)
                    }
                }
            }
            
            if let session = viewModel.currentSession {
                HStack(spacing: 4) {
                    Text("Monday Routine")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(StepCompColors.textSecondary)
                    Text("•")
                        .foregroundColor(StepCompColors.textSecondary)
                    Text("\(session.exercises.count) Exercises")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(StepCompColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
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
    @Binding var collapsedExerciseIds: Set<UUID>
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
        let isCollapsed = collapsedExerciseIds.contains(workoutExercise.id)
        
        VStack(spacing: 0) {
            if isCollapsed {
                collapsedView
            } else {
                expandedView
            }
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
        .cornerRadius(20)
        .shadow(color: StepCompColors.shadowSecondary, radius: 10, x: 0, y: 4)
    }
    
    private var expandedView: some View {
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
                    
                    // Progressive overload summary
                    if let summary = getProgressiveSummary(for: workoutExercise) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(summary.lastBest)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(StepCompColors.textSecondary)
                            Text(summary.suggested)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(StepCompColors.primary)
                        }
                        .padding(.top, 4)
                    } else if !allSetsCompleted {
                        Text("First time - set your baseline")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(StepCompColors.textSecondary)
                            .padding(.top, 4)
                    }
                }
                
                Spacer()
            }
            .padding(12)
            .opacity(allSetsCompleted ? 0.5 : 1.0)
            
            // Sets list (each row has .id for ScrollViewReader so focused set scrolls into view)
            VStack(spacing: 8) {
                ForEach(Array(workoutExercise.sets.enumerated()), id: \.element.id) { index, set in
                    let contextText = calculateContextText(for: set, at: index, in: workoutExercise)
                    SetRow(
                        set: set,
                        exerciseId: workoutExercise.id,
                        viewModel: viewModel,
                        unitManager: unitManager,
                        focusedField: $focusedField,
                        collapsedExerciseIds: $collapsedExerciseIds,
                        contextText: contextText
                    )
                    .id(set.id)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            
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
    }
    
    private var collapsedView: some View {
        HStack(spacing: 12) {
            // Checkmark or progress indicator
            if allSetsCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.green)
            } else {
                Image(systemName: "circle.dotted")
                    .font(.system(size: 16))
                    .foregroundColor(.orange)
            }
            
            // Exercise name
            Text(workoutExercise.exercise.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(StepCompColors.textPrimary)
            
            Text("|")
                .foregroundColor(StepCompColors.textSecondary.opacity(0.3))
            
            // Summary
            Text(collapsedSummary)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(StepCompColors.textSecondary)
            
            Spacer()
        }
        .padding(16)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                collapsedExerciseIds.remove(workoutExercise.id)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(workoutExercise.exercise.name), \(collapsedSummary)")
        .accessibilityHint("Tap to expand and view sets")
    }
    
    private var collapsedSummary: String {
        let completedSets = workoutExercise.sets.filter { $0.isCompleted }.count
        let totalSets = workoutExercise.sets.count
        
        let volume = workoutExercise.sets.reduce(0) { total, set in
            guard let weight = set.weight, let reps = set.reps else { return total }
            let displayWeight = Int(unitManager.convertWeightFromStorage(Double(weight)).rounded())
            return total + (displayWeight * reps)
        }
        
        let progression = calculateProgression()
        
        if allSetsCompleted {
            if progression > 0 {
                let displayProgression = unitManager.convertWeightFromStorage(Double(progression))
                return "\(totalSets) sets • \(volume.formatted()) \(unitManager.weightUnit.lowercased()) • +\(Int(displayProgression)) \(unitManager.weightUnit.lowercased())"
            } else {
                return "\(totalSets) sets • \(volume.formatted()) \(unitManager.weightUnit.lowercased())"
            }
        } else {
            return "\(completedSets)/\(totalSets) sets • \(volume.formatted()) \(unitManager.weightUnit.lowercased())"
        }
    }
    
    private func calculateProgression() -> Int {
        guard let firstSet = workoutExercise.sets.first,
              let weight = firstSet.weight,
              let prevWeight = firstSet.previousWeight else {
            return 0
        }
        return weight - prevWeight
    }
    
    private func calculateContextText(for set: WorkoutSet, at index: Int, in exercise: WorkoutExercise) -> String? {
        // Set 1: Always show "Last: X x Y" if previous data exists
        if index == 0 {
            if let prevWeight = set.previousWeight, let prevReps = set.previousReps {
                let displayWeight = Int(unitManager.convertWeightFromStorage(Double(prevWeight)).rounded())
                return "Last: \(displayWeight) x \(prevReps)"
            }
        }
        
        // Set 2: Show progression suggestion if available
        if index == 1 {
            if let sugWeight = set.suggestedWeight, let prevWeight = set.previousWeight {
                let delta = sugWeight - prevWeight
                if delta > 0 {
                    let displayDelta = unitManager.convertWeightFromStorage(Double(delta))
                    return String(format: "+%.1f \(unitManager.weightUnit.lowercased()) suggested", displayDelta)
                }
            }
        }
        
        // Set 3+: No context
        return nil
    }
    
    private func getProgressiveSummary(for exercise: WorkoutExercise) -> (lastBest: String, suggested: String)? {
        guard let firstSet = exercise.sets.first,
              let prevWeight = firstSet.previousWeight,
              let prevReps = firstSet.previousReps,
              let sugWeight = firstSet.suggestedWeight,
              let sugReps = firstSet.suggestedReps else {
            return nil
        }
        
        let displayPrevWeight = Int(unitManager.convertWeightFromStorage(Double(prevWeight)).rounded())
        let displaySugWeight = Int(unitManager.convertWeightFromStorage(Double(sugWeight)).rounded())
        
        let lastBest = "Last best: \(displayPrevWeight) x \(prevReps)"
        let suggested = "Suggested: \(displaySugWeight) x \(sugReps)"
        
        return (lastBest, suggested)
    }
}

struct SetRow: View {
    let set: WorkoutSet
    let exerciseId: UUID
    @ObservedObject var viewModel: WorkoutViewModel
    @ObservedObject var unitManager: UnitPreferenceManager
    @FocusState.Binding var focusedField: UUID?
    @Binding var collapsedExerciseIds: Set<UUID>
    let contextText: String?
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var weightText: String
    @State private var repsText: String
    @State private var showSuggestionApplied: Bool = false
    
    init(set: WorkoutSet, exerciseId: UUID, viewModel: WorkoutViewModel, unitManager: UnitPreferenceManager, focusedField: FocusState<UUID?>.Binding, collapsedExerciseIds: Binding<Set<UUID>>, contextText: String? = nil) {
        self.set = set
        self.exerciseId = exerciseId
        self.viewModel = viewModel
        self.unitManager = unitManager
        self._focusedField = focusedField
        self._collapsedExerciseIds = collapsedExerciseIds
        self.contextText = contextText
        // Convert stored weight (kg) to display unit (lbs or kg)
        _weightText = State(initialValue: set.weight.map { String(Int(unitManager.convertWeightFromStorage(Double($0)).rounded())) } ?? "")
        _repsText = State(initialValue: set.reps.map { String($0) } ?? "")
    }
    
    /// Light blue for completed-set checkmark so it stands out
    private static let setCompleteCheckmarkBlue = Color(red: 0.45, green: 0.78, blue: 0.95)

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 12) {
                // Set number
                Text("\(set.setNumber)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(set.isCompleted ? StepCompColors.textSecondary.opacity(0.3) : StepCompColors.textSecondary)
                    .frame(width: 30, alignment: .leading)
                
                // Weight input
                TextField("", text: $weightText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(StepCompColors.textPrimary)
                    .frame(width: 100, height: 44)
                    .background(set.isCompleted ? StepCompColors.textSecondary.opacity(0.1) : (colorScheme == .dark ? StepCompColors.surface : Color.white))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(inputBorderColor, lineWidth: focusedField == set.id ? 2 : 1)
                    )
                    .focused($focusedField, equals: set.id)
                    .disabled(set.isCompleted)
                    .onChange(of: weightText) { oldValue, newValue in
                        if let displayWeight = Int(newValue) {
                            let storageWeight = Int(unitManager.convertWeightToStorage(Double(displayWeight)).rounded())
                            viewModel.updateSet(exerciseId: exerciseId, setId: set.id, weight: storageWeight, reps: set.reps)
                            
                            // Auto-advance to reps if empty
                            if repsText.isEmpty {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    focusedField = set.id
                                }
                            }
                        }
                    }
                
                // x separator
                Text("x")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(StepCompColors.textSecondary)
                
                // Reps input
                TextField("", text: $repsText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(StepCompColors.textPrimary)
                    .frame(width: 100, height: 44)
                    .background(set.isCompleted ? StepCompColors.textSecondary.opacity(0.1) : (colorScheme == .dark ? StepCompColors.surface : Color.white))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(inputBorderColor, lineWidth: focusedField == set.id ? 2 : 1)
                    )
                    .focused($focusedField, equals: set.id)
                    .disabled(set.isCompleted)
                    .onChange(of: repsText) { oldValue, newValue in
                        if let reps = Int(newValue) {
                            viewModel.updateSet(exerciseId: exerciseId, setId: set.id, weight: set.weight, reps: reps)
                            
                            // Auto-advance to next set if available
                            if let nextSet = viewModel.getNextIncompleteSet(after: set.id, in: exerciseId) {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    focusedField = nextSet.id
                                }
                            } else {
                                // Last set, dismiss keyboard
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    focusedField = nil
                                }
                            }
                        }
                    }
                
                Spacer()
                
                // Complete button
                if set.isCompleted {
                    Button(action: {
                        viewModel.removeSet(exerciseId: exerciseId, setId: set.id)
                    }) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.red)
                            .cornerRadius(20)
                    }
                } else {
                    Button(action: {
                        viewModel.completeSet(exerciseId: exerciseId, setId: set.id)
                    }) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Self.setCompleteCheckmarkBlue)
                            .frame(width: 40, height: 40)
                            .background(StepCompColors.textSecondary.opacity(0.2))
                            .cornerRadius(20)
                    }
                }
            }
            
            // Context line (shown conditionally)
            if let contextText = contextText, !set.isCompleted {
                Text(contextText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(StepCompColors.textSecondary)
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
        .contentShape(Rectangle())
        .onTapGesture {
            if !set.isCompleted {
                handleSetTap()
            }
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            // Trigger haptic
            HapticManager.shared.light()
        }
        .contextMenu {
            if !set.isCompleted {
                Button(action: {
                    handleSetTap()
                }) {
                    Label("Complete Set", systemImage: "checkmark.circle")
                }
                
                Button(action: {
                    focusedField = set.id
                }) {
                    Label("Edit Set", systemImage: "pencil")
                }
            }
            
            Button(role: .destructive, action: {
                viewModel.removeSet(exerciseId: exerciseId, setId: set.id)
            }) {
                Label("Delete Set", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Tap to complete set, long press for more options")
        .accessibilityAddTraits(set.isCompleted ? [.isSelected] : [])
    }
    
    private var accessibilityLabel: String {
        let weightValue = weightText.isEmpty ? "empty" : "\(weightText) \(unitManager.weightUnit)"
        let repsValue = repsText.isEmpty ? "empty" : "\(repsText) reps"
        let status = set.isCompleted ? "completed" : "incomplete"
        
        return "Set \(set.setNumber), \(status), weight \(weightValue), \(repsValue)"
    }
    
    private func handleSetTap() {
        // Complete current set
        viewModel.completeSet(exerciseId: exerciseId, setId: set.id)
        
        // Check if all sets complete
        let allComplete = viewModel.allSetsCompleted(in: exerciseId)
        
        if allComplete {
            // Auto-collapse after short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.3)) {
                    collapsedExerciseIds.insert(exerciseId)
                }
                focusedField = nil
            }
        } else {
            // Find and focus next incomplete set
            if let nextSet = viewModel.getNextIncompleteSet(after: set.id, in: exerciseId) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    focusedField = nextSet.id
                }
            } else {
                focusedField = nil
            }
        }
        
        // Haptic feedback
        HapticManager.shared.success()
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
