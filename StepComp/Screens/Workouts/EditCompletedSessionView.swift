//
//  EditCompletedSessionView.swift
//  StepComp
//
//  Created by AI Assistant on 2/17/26.
//

import SwiftUI

struct EditCompletedSessionView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @ObservedObject var unitManager = UnitPreferenceManager.shared
    let session: CompletedWorkoutSession
    
    @State private var editedExercises: [WorkoutExercise]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    init(viewModel: WorkoutViewModel, session: CompletedWorkoutSession) {
        self.viewModel = viewModel
        self.session = session
        _editedExercises = State(initialValue: session.exercises)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                StepCompColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header info
                        VStack(alignment: .leading, spacing: 8) {
                            Text(session.workoutName)
                                .font(.system(size: 24, weight: .black))
                                .foregroundColor(StepCompColors.textPrimary)
                            
                            Text(formatDate(session.endTime))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(StepCompColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Exercises
                        ForEach(editedExercises.indices, id: \.self) { exerciseIndex in
                            EditExerciseCard(
                                exercise: $editedExercises[exerciseIndex],
                                unitManager: unitManager
                            )
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(StepCompColors.textPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(StepCompColors.primary)
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
    
    private func saveChanges() {
        // Find the session in the completed sessions array and update it
        if let index = viewModel.completedSessions.firstIndex(where: { $0.id == session.id }) {
            // Create a new session with updated exercises
            let updatedSession = CompletedWorkoutSession(
                id: session.id,
                workoutId: session.workoutId,
                workoutName: session.workoutName,
                startTime: session.startTime,
                endTime: session.endTime,
                exercises: editedExercises
            )
            viewModel.completedSessions[index] = updatedSession
            
            // Save to persistence
            viewModel.saveCompletedSessions()
        }
    }
}

struct EditExerciseCard: View {
    @Binding var exercise: WorkoutExercise
    @ObservedObject var unitManager: UnitPreferenceManager
    @Environment(\.colorScheme) private var colorScheme
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color(hex: "1a1a1a") : Color.white
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Exercise name
            Text(exercise.exercise.name)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(StepCompColors.textPrimary)
            
            // Sets
            VStack(spacing: 12) {
                ForEach(exercise.sets.indices, id: \.self) { setIndex in
                    EditSetRow(set: $exercise.sets[setIndex], unitManager: unitManager)
                }
            }
        }
        .padding(20)
        .background(cardBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}

struct EditSetRow: View {
    @Binding var set: WorkoutSet
    @ObservedObject var unitManager: UnitPreferenceManager
    @FocusState private var focusedField: Field?
    @State private var displayWeight: String = ""
    @State private var displayReps: String = ""
    
    enum Field {
        case weight
        case reps
    }
    
    init(set: Binding<WorkoutSet>, unitManager: UnitPreferenceManager) {
        self._set = set
        self.unitManager = unitManager
        
        // Initialize display values from storage (kg) to display unit
        if let weight = set.wrappedValue.weight {
            let converted = unitManager.convertWeightFromStorage(Double(weight))
            // Show decimals if present, otherwise show as integer
            if converted.truncatingRemainder(dividingBy: 1) == 0 {
                _displayWeight = State(initialValue: String(Int(converted)))
            } else {
                _displayWeight = State(initialValue: String(format: "%.1f", converted))
            }
        }
        if let reps = set.wrappedValue.reps {
            _displayReps = State(initialValue: String(reps))
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Set number
            Text("Set \(set.setNumber)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(StepCompColors.textSecondary)
                .frame(width: 50, alignment: .leading)
            
            // Weight input
            VStack(alignment: .leading, spacing: 4) {
                Text("Weight (\(unitManager.weightUnit))")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(StepCompColors.textSecondary)
                    .textCase(.uppercase)
                
                TextField("0", text: $displayWeight)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(StepCompColors.textPrimary)
                    .padding(12)
                    .background(StepCompColors.textSecondary.opacity(0.1))
                    .cornerRadius(12)
                    .focused($focusedField, equals: .weight)
                    .onTapGesture {
                        displayWeight = ""
                        focusedField = .weight
                    }
                    .onChange(of: displayWeight) { _, newValue in
                        if let display = Double(newValue), display > 0 {
                            // Convert from display unit to storage (kg)
                            let storage = unitManager.convertWeightToStorage(display)
                            set.weight = storage
                        } else if newValue.isEmpty {
                            set.weight = nil
                        }
                    }
            }
            
            // Reps input
            VStack(alignment: .leading, spacing: 4) {
                Text("Reps")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(StepCompColors.textSecondary)
                    .textCase(.uppercase)
                
                TextField("0", text: $displayReps)
                    .keyboardType(.numberPad)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(StepCompColors.textPrimary)
                    .padding(12)
                    .background(StepCompColors.textSecondary.opacity(0.1))
                    .cornerRadius(12)
                    .focused($focusedField, equals: .reps)
                    .onTapGesture {
                        displayReps = ""
                        focusedField = .reps
                    }
                    .onChange(of: displayReps) { _, newValue in
                        set.reps = Int(newValue)
                    }
            }
        }
    }
}

#Preview {
    EditCompletedSessionView(
        viewModel: WorkoutViewModel.shared,
        session: CompletedWorkoutSession(
            id: UUID(),
            workoutId: UUID(),
            workoutName: "Upper Body Day",
            startTime: Date(),
            endTime: Date(),
            exercises: []
        )
    )
}
