//
//  ActiveWorkoutView.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 2/16/26.
//

import SwiftUI

// MARK: - Field Identifier

enum SetFieldType: Equatable {
    case weight
    case reps
}

struct SetFieldIdentifier: Hashable {
    let setId: UUID
    let fieldType: SetFieldType
}

// MARK: - Custom Number Pad

struct WorkoutNumberPad: View {
    let showDecimal: Bool
    let onKey: (String) -> Void
    let onDelete: () -> Void
    let onDone: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(FitCompColors.textSecondary.opacity(0.3))

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(["1","2","3","4","5","6","7","8","9"], id: \.self) { key in
                    NumberPadButton(label: key) { onKey(key) }
                }
                if showDecimal {
                    NumberPadButton(label: ".") { onKey(".") }
                } else {
                    Color.clear.frame(height: 48)
                }
                NumberPadButton(label: "0") { onKey("0") }
                NumberPadButton(systemImage: "delete.left.fill") { onDelete() }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Button(action: onDone) {
                Text("Done")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(FitCompColors.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .background(FitCompColors.surface)
    }
}

private struct NumberPadButton: View {
    let label: String
    var systemImage: String? = nil
    let action: () -> Void

    init(label: String, action: @escaping () -> Void) {
        self.label = label
        self.systemImage = nil
        self.action = action
    }

    init(systemImage: String, action: @escaping () -> Void) {
        self.label = ""
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.light()
            action()
        }) {
            Group {
                if let img = systemImage {
                    Image(systemName: img)
                        .font(.system(size: 20, weight: .medium))
                } else {
                    Text(label)
                        .font(.system(size: 22, weight: .semibold))
                }
            }
            .foregroundColor(FitCompColors.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(FitCompColors.textSecondary.opacity(0.12))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Active Workout View

struct ActiveWorkoutView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @ObservedObject var unitManager = UnitPreferenceManager.shared
    @StateObject private var restTimerManager = RestTimerManager()
    @State private var showingFinishConfirmation = false
    @State private var activeField: SetFieldIdentifier? = nil
    @State private var editBuffer: String = ""
    @State private var collapsedExerciseIds: Set<UUID> = []

    private var isEditing: Bool { activeField != nil }

    var body: some View {
        ZStack {
            FitCompColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            if let session = viewModel.currentSession {
                                ForEach(session.exercises) { workoutExercise in
                                    ExerciseCard(
                                        workoutExercise: workoutExercise,
                                        viewModel: viewModel,
                                        unitManager: unitManager,
                                        activeField: $activeField,
                                        editBuffer: $editBuffer,
                                        collapsedExerciseIds: $collapsedExerciseIds,
                                        restTimerManager: restTimerManager
                                    )
                                }
                            }
                        }
                        .padding(20)
                        .padding(.bottom, isEditing ? 320 : 150)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            commitAndDismiss()
                        }
                    }
                    .scrollDismissesKeyboard(.never)
                    .onChange(of: activeField) { _, newValue in
                        if let fieldId = newValue {
                            withAnimation(.easeOut(duration: 0.25)) {
                                scrollProxy.scrollTo(fieldId.setId, anchor: .center)
                            }
                        }
                    }
                }

                // Compact rest timer bar (visible when timer running but overlay dismissed)
                if restTimerManager.isRunning && !restTimerManager.showOverlay && !isEditing {
                    RestTimerCompactBar(timerManager: restTimerManager)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: restTimerManager.isRunning)
                }

                if !isEditing {
                    Spacer()
                    bottomActionArea
                }
            }

            // Custom number pad overlay
            if isEditing {
                VStack {
                    Spacer()
                    WorkoutNumberPad(
                        showDecimal: activeField?.fieldType == .weight,
                        onKey: { key in
                            if key == "." {
                                if !editBuffer.contains(".") { editBuffer += key }
                            } else {
                                if editBuffer == "0" {
                                    editBuffer = key
                                } else {
                                    editBuffer += key
                                }
                            }
                        },
                        onDelete: {
                            if !editBuffer.isEmpty {
                                editBuffer.removeLast()
                            }
                        },
                        onDone: {
                            commitAndDismiss()
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isEditing)
            }

            // Rest timer overlay
            if restTimerManager.showOverlay {
                RestTimerOverlayView(timerManager: restTimerManager)
            }

            // Auto-finish overlay
            if viewModel.isAutoFinishing {
                autoFinishOverlay
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .onChange(of: viewModel.isAutoFinishing) { _, isAutoFinishing in
            if isAutoFinishing {
                commitAndDismiss()
                restTimerManager.resetForNewSession()
            }
        }
        .confirmationDialog("End Workout", isPresented: $showingFinishConfirmation, titleVisibility: .visible) {
            Button("Finish Workout") {
                restTimerManager.resetForNewSession()
                viewModel.finishWorkout()
            }
            Button("Cancel Workout", role: .destructive) {
                restTimerManager.resetForNewSession()
                viewModel.cancelWorkout()
            }
            Button("Keep Training", role: .cancel) {}
        } message: {
            Text("Would you like to finish and save this workout, or cancel without saving?")
        }
    }

    // MARK: - Auto-Finish Overlay

    private var autoFinishOverlay: some View {
        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
                    .scaleEffect(viewModel.isAutoFinishing ? 1.0 : 0.5)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: viewModel.isAutoFinishing)

                Text("Workout Complete!")
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(FitCompColors.textPrimary)

                Text("Saving your session...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(FitCompColors.textSecondary)
            }

            Spacer()

            Button(action: {
                withAnimation(.easeOut(duration: 0.2)) {
                    viewModel.cancelAutoFinish()
                }
            }) {
                Text("Keep Training")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(FitCompColors.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(FitCompColors.primary.opacity(0.12))
                    .cornerRadius(24)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FitCompColors.background.opacity(0.95))
    }

    private func commitAndDismiss() {
        if let field = activeField {
            commitValue(field: field, text: editBuffer)
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            activeField = nil
            editBuffer = ""
        }
    }

    private func commitValue(field: SetFieldIdentifier, text: String) {
        guard let session = viewModel.currentSession,
              let exercise = session.exercises.first(where: { $0.sets.contains(where: { $0.id == field.setId }) }),
              let set = exercise.sets.first(where: { $0.id == field.setId }) else { return }

        switch field.fieldType {
        case .weight:
            if let displayVal = Double(text), displayVal > 0 {
                // Store in kg with full decimal precision
                let storageKg = unitManager.convertWeightToStorage(displayVal)
                viewModel.updateSet(exerciseId: exercise.id, setId: set.id, weight: storageKg, reps: set.reps)
            } else if text.isEmpty {
                viewModel.updateSet(exerciseId: exercise.id, setId: set.id, weight: nil, reps: set.reps)
            }
        case .reps:
            if let reps = Int(text), reps > 0 {
                viewModel.updateSet(exerciseId: exercise.id, setId: set.id, weight: set.weight, reps: reps)
            } else if text.isEmpty {
                viewModel.updateSet(exerciseId: exercise.id, setId: set.id, weight: set.weight, reps: nil)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Text(viewModel.currentSession?.workoutName ?? "Workout")
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(FitCompColors.textPrimary)

                Spacer()

                HStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.system(size: 12, weight: .bold))
                        Text(viewModel.formattedElapsedTime())
                            .font(.system(size: 13, weight: .black))
                            .monospacedDigit()
                    }
                    .foregroundColor(FitCompColors.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(FitCompColors.textSecondary.opacity(0.1))
                    .cornerRadius(16)

                    Button(action: {
                        HapticManager.shared.light()
                        restTimerManager.startTimer()
                    }) {
                        Image(systemName: "bed.double.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(restTimerManager.isRunning ? FitCompColors.buttonTextOnPrimary : FitCompColors.textPrimary)
                            .frame(width: 28, height: 28)
                            .background(restTimerManager.isRunning ? FitCompColors.primary : FitCompColors.textSecondary.opacity(0.1))
                            .cornerRadius(14)
                    }

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
                        .foregroundColor(FitCompColors.textSecondary)
                    Text("•")
                        .foregroundColor(FitCompColors.textSecondary)
                    Text("\(session.exercises.count) Exercises")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(FitCompColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(FitCompColors.surface.opacity(0.9))
        .overlay(
            Rectangle()
                .fill(FitCompColors.divider.opacity(0.1))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Bottom Action Area

    private var bottomActionArea: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [
                    FitCompColors.background.opacity(0),
                    FitCompColors.background,
                    FitCompColors.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)

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
                .background(FitCompColors.primary)
                .foregroundColor(FitCompColors.buttonTextOnPrimary)
                .cornerRadius(26)
                .shadow(color: FitCompColors.primary.opacity(0.25), radius: 12, x: 0, y: 6)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .background(FitCompColors.background)
        }
    }
}

// MARK: - Exercise Card

struct ExerciseCard: View {
    let workoutExercise: WorkoutExercise
    @ObservedObject var viewModel: WorkoutViewModel
    @ObservedObject var unitManager: UnitPreferenceManager
    @Binding var activeField: SetFieldIdentifier?
    @Binding var editBuffer: String
    @Binding var collapsedExerciseIds: Set<UUID>
    @ObservedObject var restTimerManager: RestTimerManager
    @State private var expandedSetId: UUID?
    @State private var overloadApplied = false
    @State private var originalSetValues: [UUID: (weight: Double?, reps: Int?)] = [:]

    @Environment(\.colorScheme) private var colorScheme

    private static let overloadBlue = Color(red: 0.25, green: 0.47, blue: 0.95)

    private var allSetsCompleted: Bool {
        workoutExercise.sets.allSatisfy { $0.isCompleted }
    }

    private var exerciseWeightInputMode: WorkoutSet.WeightInputMode {
        workoutExercise.sets.first?.weightInputMode ?? .total
    }

    private var completedSetCount: Int {
        workoutExercise.sets.filter(\.isCompleted).count
    }

    private var plannedReps: Int {
        workoutExercise.sets.reduce(0) { total, set in
            total + (set.reps ?? set.suggestedReps ?? 0)
        }
    }

    private var completedReps: Int {
        workoutExercise.sets.reduce(0) { total, set in
            guard set.isCompleted else { return total }
            return total + (set.reps ?? set.suggestedReps ?? 0)
        }
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
        .shadow(color: FitCompColors.shadowSecondary, radius: 10, x: 0, y: 4)
    }

    private var expandedView: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                ExerciseDemoButton(exercise: workoutExercise.exercise)

                VStack(alignment: .leading, spacing: 4) {
                    Text(workoutExercise.exercise.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(FitCompColors.textPrimary)
                    Text("Target: \(workoutExercise.exercise.targetMuscles)")
                        .font(.system(size: 12))
                        .foregroundColor(FitCompColors.textSecondary)

                    if let summary = getProgressiveSummary(for: workoutExercise) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(summary.lastBest)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(FitCompColors.textSecondary)
                            Text(summary.suggested)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(overloadApplied ? Self.overloadBlue : FitCompColors.textSecondary)
                        }
                        .padding(.top, 4)
                    } else if !allSetsCompleted {
                        Text("First time - set your baseline")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(FitCompColors.textSecondary)
                            .padding(.top, 4)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    exerciseWeightModeSelector

                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            collapsedExerciseIds.insert(workoutExercise.id)
                        }
                        HapticManager.shared.light()
                    }) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(FitCompColors.textSecondary)
                            .frame(width: 28, height: 28)
                            .background(FitCompColors.textSecondary.opacity(0.12))
                            .cornerRadius(14)
                    }
                    .buttonStyle(.plain)

                    if hasProgressiveOverloadSuggestions && !allSetsCompleted {
                        HStack(spacing: 8) {
                            Text("Progressive Overload")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(FitCompColors.textSecondary)

                            Button(action: toggleProgressiveOverload) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(overloadApplied ? Self.overloadBlue : FitCompColors.cardBackground)
                                        .frame(width: 44, height: 26)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(overloadApplied ? Self.overloadBlue : FitCompColors.textSecondary.opacity(0.3), lineWidth: 2)
                                        )

                                    Circle()
                                        .fill(.white)
                                        .frame(width: 20, height: 20)
                                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                        .offset(x: overloadApplied ? 9 : -9)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: overloadApplied)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(12)
            .opacity(allSetsCompleted ? 0.5 : 1.0)

            VStack(spacing: 8) {
                ForEach(Array(workoutExercise.sets.enumerated()), id: \.element.id) { index, set in
                    let contextText = calculateContextText(for: set, at: index, in: workoutExercise)
                    SetRow(
                        set: set,
                        exerciseId: workoutExercise.id,
                        exerciseName: workoutExercise.exercise.name,
                        viewModel: viewModel,
                        unitManager: unitManager,
                        activeField: $activeField,
                        editBuffer: $editBuffer,
                        collapsedExerciseIds: $collapsedExerciseIds,
                        restTimerManager: restTimerManager,
                        contextText: contextText,
                        overloadApplied: overloadApplied
                    )
                    .id(set.id)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)

            Button(action: {
                viewModel.addSet(exerciseId: workoutExercise.id)
            }) {
                Text("+ ADD SET")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(FitCompColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(FitCompColors.textSecondary.opacity(0.05))
            }

            exerciseFooterVolumeTracker
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
        }
    }

    private var collapsedView: some View {
        HStack(spacing: 12) {
            if allSetsCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.green)
            } else {
                Image(systemName: "circle.dotted")
                    .font(.system(size: 16))
                    .foregroundColor(.orange)
            }

            Text(workoutExercise.exercise.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(FitCompColors.textPrimary)

            Text("|")
                .foregroundColor(FitCompColors.textSecondary.opacity(0.3))

            Text(collapsedSummary)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(FitCompColors.textSecondary)

            Spacer()
        }
        .padding(16)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                _ = collapsedExerciseIds.remove(workoutExercise.id)
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
            guard let effectiveWeight = set.effectiveWeightForVolume, let reps = set.reps else { return total }
            let displayWeight = unitManager.convertWeightFromStorage(effectiveWeight)
            return total + Int((displayWeight * Double(reps)).rounded())
        }

        let progression = calculateProgression()

        if allSetsCompleted {
            if progression > 0 {
                let displayProgression = unitManager.convertWeightFromStorage(progression)
                let progressionStr = displayProgression.truncatingRemainder(dividingBy: 1) == 0
                    ? String(Int(displayProgression))
                    : String(format: "%.1f", displayProgression)
                return "\(totalSets) sets • \(volume.formatted()) \(unitManager.weightUnit.lowercased()) • +\(progressionStr) \(unitManager.weightUnit.lowercased())"
            } else {
                return "\(totalSets) sets • \(volume.formatted()) \(unitManager.weightUnit.lowercased())"
            }
        } else {
            return "\(completedSets)/\(totalSets) sets • \(volume.formatted()) \(unitManager.weightUnit.lowercased())"
        }
    }

    private func calculateProgression() -> Double {
        guard let firstSet = workoutExercise.sets.first,
              let weight = firstSet.weight,
              let prevWeight = firstSet.previousWeight else {
            return 0
        }
        return weight - prevWeight
    }

    private func calculateContextText(for set: WorkoutSet, at index: Int, in exercise: WorkoutExercise) -> String? {
        if index == 0 {
            if let prevWeight = set.previousWeight, let prevReps = set.previousReps {
                let displayWeight = unitManager.convertWeightFromStorage(prevWeight)
                // Format weight nicely
                let weightStr = displayWeight.truncatingRemainder(dividingBy: 1) == 0
                    ? String(Int(displayWeight))
                    : String(format: "%.1f", displayWeight)
                return "Last: \(weightStr) x \(prevReps)"
            }
        }
        if index == 1 {
            if let sugWeight = set.suggestedWeight, let prevWeight = set.previousWeight {
                let delta = sugWeight - prevWeight
                if delta > 0 {
                    let displayDelta = unitManager.convertWeightFromStorage(delta)
                    return String(format: "+%.1f \(unitManager.weightUnit.lowercased()) suggested", displayDelta)
                }
            }
        }
        return nil
    }

    private func toggleProgressiveOverload() {
        if overloadApplied {
            for set in workoutExercise.sets where !set.isCompleted {
                if let original = originalSetValues[set.id] {
                    viewModel.updateSet(exerciseId: workoutExercise.id, setId: set.id, weight: original.weight, reps: original.reps)
                }
            }
            overloadApplied = false
            originalSetValues.removeAll()
        } else {
            for set in workoutExercise.sets where !set.isCompleted {
                originalSetValues[set.id] = (weight: set.weight, reps: set.reps)
                guard let sugWeight = set.suggestedWeight, let sugReps = set.suggestedReps else { continue }
                viewModel.updateSet(exerciseId: workoutExercise.id, setId: set.id, weight: sugWeight, reps: sugReps)
            }
            overloadApplied = true
        }
        HapticManager.shared.light()
    }

    private func getProgressiveSummary(for exercise: WorkoutExercise) -> (lastBest: String, suggested: String)? {
        guard let firstSet = exercise.sets.first,
              let prevWeight = firstSet.previousWeight,
              let prevReps = firstSet.previousReps,
              let sugWeight = firstSet.suggestedWeight,
              let sugReps = firstSet.suggestedReps else {
            return nil
        }

        let displayPrevWeight = unitManager.convertWeightFromStorage(prevWeight)
        let displaySugWeight = unitManager.convertWeightFromStorage(sugWeight)

        let prevWeightStr = displayPrevWeight.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(displayPrevWeight))
            : String(format: "%.1f", displayPrevWeight)

        let lastBest = "Last best: \(prevWeightStr) x \(prevReps)"

        // Use smart engine reasoning if available
        let history = viewModel.getExerciseHistory(exerciseName: exercise.exercise.name)
        let analytics = WorkoutAnalyticsEngine()
        if let smartSuggestion = analytics.smartOverloadSuggestion(history: history, exerciseName: exercise.exercise.name) {
            return (lastBest, smartSuggestion.reasoning)
        }

        let delta = displaySugWeight - displayPrevWeight
        let suggested: String
        if delta > 0.1 {
            suggested = String(format: "Suggested: Add %.1f %@ next session", delta, unitManager.weightUnit.lowercased())
        } else {
            suggested = "Suggested: Hold weight, push reps to \(sugReps)"
        }

        return (lastBest, suggested)
    }

    private var exerciseWeightModeSelector: some View {
        HStack(spacing: 6) {
            exerciseModeButton(title: "Total", mode: .total)
            exerciseModeButton(title: "Per Side", mode: .perSide)
        }
    }

    @ViewBuilder
    private func exerciseModeButton(title: String, mode: WorkoutSet.WeightInputMode) -> some View {
        let selected = exerciseWeightInputMode == mode
        Button(action: {
            guard exerciseWeightInputMode != mode else { return }
            viewModel.updateExerciseWeightInputMode(exerciseId: workoutExercise.id, mode: mode)
            HapticManager.shared.light()
        }) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(selected ? .white : FitCompColors.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(selected ? FitCompColors.primary : FitCompColors.textSecondary.opacity(0.12))
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private var exerciseFooterVolumeTracker: some View {
        let totalSets = max(1, workoutExercise.sets.count)
        let progress = Double(completedSetCount) / Double(totalSets)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Exercise Volume")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(FitCompColors.textSecondary)
                Spacer()
                Text("\(completedReps) / \(plannedReps) reps")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(FitCompColors.textPrimary)
            }

            ProgressView(value: progress)
                .tint(FitCompColors.primary)
                .scaleEffect(x: 1, y: 1.4, anchor: .center)

            Text("\(completedSetCount)/\(workoutExercise.sets.count) sets complete")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(FitCompColors.textSecondary)
        }
        .padding(12)
        .background(FitCompColors.textSecondary.opacity(0.08))
        .cornerRadius(14)
    }
}

// MARK: - Set Row

struct SetRow: View {
    let set: WorkoutSet
    let exerciseId: UUID
    let exerciseName: String
    @ObservedObject var viewModel: WorkoutViewModel
    @ObservedObject var unitManager: UnitPreferenceManager
    @Binding var activeField: SetFieldIdentifier?
    @Binding var editBuffer: String
    @Binding var collapsedExerciseIds: Set<UUID>
    @ObservedObject var restTimerManager: RestTimerManager
    let contextText: String?
    let overloadApplied: Bool

    @Environment(\.colorScheme) private var colorScheme

    private static let setCompleteCheckmarkBlue = Color(red: 0.45, green: 0.78, blue: 0.95)
    private static let overloadBlue = Color(red: 0.25, green: 0.47, blue: 0.95)

    private var weightFieldId: SetFieldIdentifier { SetFieldIdentifier(setId: set.id, fieldType: .weight) }
    private var repsFieldId: SetFieldIdentifier { SetFieldIdentifier(setId: set.id, fieldType: .reps) }

    private var displayWeight: String {
        if activeField == weightFieldId { return editBuffer }
        guard let w = set.weight else { return "" }
        let display = unitManager.convertWeightFromStorage(w)
        // Show decimals if present, otherwise show as integer
        return display.truncatingRemainder(dividingBy: 1) == 0 
            ? String(Int(display)) 
            : String(format: "%.1f", display)
    }

    private var displayReps: String {
        if activeField == repsFieldId { return editBuffer }
        guard let r = set.reps else { return "" }
        return String(r)
    }

    var body: some View {
        VStack(spacing: 4) {
                HStack(spacing: 12) {
                    Text("\(set.setNumber)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(set.isCompleted ? FitCompColors.textSecondary.opacity(0.3) : FitCompColors.textSecondary)
                        .frame(width: 30, alignment: .leading)

                    // Weight — tappable display
                    inputCell(
                        value: displayWeight,
                        placeholder: unitManager.weightUnit,
                        fieldId: weightFieldId,
                        isWeight: true
                    )

                    Text("x")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(FitCompColors.textSecondary)

                    // Reps — tappable display
                    inputCell(
                        value: displayReps,
                        placeholder: "Reps",
                        fieldId: repsFieldId,
                        isWeight: false
                    )

                    Spacer()

                    if set.isCompleted {
                        Button(action: {
                            viewModel.removeSet(exerciseId: exerciseId, setId: set.id)
                        }) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(FitCompColors.textSecondary.opacity(0.5))
                                .cornerRadius(20)
                        }
                    } else {
                        Button(action: {
                            handleSetTap()
                        }) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Self.setCompleteCheckmarkBlue)
                                .frame(width: 40, height: 40)
                                .background(FitCompColors.textSecondary.opacity(0.2))
                                .cornerRadius(20)
                        }
                    }
                }

                if let contextText = contextText, !set.isCompleted {
                    Text(contextText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(FitCompColors.textSecondary)
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
        .onLongPressGesture(minimumDuration: 0.5) {
            HapticManager.shared.light()
        }
        .contextMenu {
            if !set.isCompleted {
                Button(action: {
                    activateField(weightFieldId)
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
        .accessibilityHint("Tap checkmark to complete set, long press for more options")
        .accessibilityAddTraits(set.isCompleted ? [.isSelected] : [])
    }

    @ViewBuilder
    private func inputCell(value: String, placeholder: String, fieldId: SetFieldIdentifier, isWeight: Bool) -> some View {
        let isFocused = activeField == fieldId
        let textColor: Color = overloadApplied ? Self.overloadBlue : FitCompColors.textPrimary

        Text(value.isEmpty ? placeholder : value)
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(value.isEmpty ? FitCompColors.textSecondary.opacity(0.5) : textColor)
            .frame(width: 100, height: 44)
            .background(set.isCompleted ? FitCompColors.textSecondary.opacity(0.1) : (colorScheme == .dark ? FitCompColors.surface : Color.white))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor(focused: isFocused), lineWidth: isFocused ? 2 : 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                guard !set.isCompleted else { return }
                activateField(fieldId)
            }
            .allowsHitTesting(!set.isCompleted)
    }

    private func activateField(_ fieldId: SetFieldIdentifier) {
        // Commit any previous field first
        if let prev = activeField, prev != fieldId {
            commitCurrentField(prev)
        }

        // Clear the buffer to allow fresh input
        editBuffer = ""

        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            activeField = fieldId
        }
    }

    private func commitCurrentField(_ field: SetFieldIdentifier) {
        switch field.fieldType {
        case .weight:
            if let displayVal = Double(editBuffer), displayVal > 0 {
                let storageWeight = unitManager.convertWeightToStorage(displayVal)
                viewModel.updateSet(exerciseId: exerciseId, setId: set.id, weight: storageWeight, reps: set.reps)
            }
        case .reps:
            if let reps = Int(editBuffer), reps > 0 {
                viewModel.updateSet(exerciseId: exerciseId, setId: set.id, weight: set.weight, reps: reps)
            }
        }
    }

    private var accessibilityLabel: String {
        let weightValue = displayWeight.isEmpty ? "empty" : "\(displayWeight) \(unitManager.weightUnit)"
        let repsValue = displayReps.isEmpty ? "empty" : "\(displayReps) reps"
        let status = set.isCompleted ? "completed" : "incomplete"
        return "Set \(set.setNumber), \(status), weight \(weightValue), \(repsValue)"
    }

    private func handleSetTap() {
        if let field = activeField {
            commitCurrentField(field)
            activeField = nil
            editBuffer = ""
        }

        viewModel.completeSet(exerciseId: exerciseId, setId: set.id)

        let allComplete = viewModel.allSetsCompleted(in: exerciseId)
        if allComplete {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                _ = withAnimation(.spring(response: 0.3)) {
                    collapsedExerciseIds.insert(exerciseId)
                }
            }
        } else {
            // Smart rest timer: suggest duration based on set exertion
            let weight = set.weight ?? 0
            let reps = set.reps ?? 0
            if weight > 0 && reps > 0 {
                let suggestion = viewModel.suggestRestDuration(
                    exerciseName: exerciseName,
                    weight: weight,
                    reps: reps
                )
                restTimerManager.startTimer(duration: suggestion.duration, reasoning: suggestion.reasoning)
            } else {
                restTimerManager.startTimer()
            }
        }
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

    private func borderColor(focused: Bool) -> Color {
        if focused {
            return FitCompColors.primary
        } else if targetMetOrExceeded && !set.isCompleted {
            return Color.green.opacity(0.5)
        }
        return FitCompColors.textSecondary.opacity(0.2)
    }

    private var targetMetOrExceeded: Bool {
        guard let weight = set.weight, let reps = set.reps,
              let sugWeight = set.suggestedWeight, let sugReps = set.suggestedReps else {
            return false
        }
        return weight >= sugWeight || reps >= sugReps
    }

    private func applySuggestion() {
        guard let sugWeight = set.suggestedWeight, let sugReps = set.suggestedReps else { return }
        let displayWeight = unitManager.convertWeightFromStorage(sugWeight)
        editBuffer = displayWeight.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(displayWeight))
            : String(format: "%.1f", displayWeight)
        viewModel.updateSet(exerciseId: exerciseId, setId: set.id, weight: sugWeight, reps: sugReps)
        HapticManager.shared.light()
    }

    private var previousSetText: String {
        if let prevWeight = set.previousWeight, let prevReps = set.previousReps {
            let displayWeight = unitManager.convertWeightFromStorage(prevWeight)
            let weightStr = displayWeight.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(displayWeight))
                : String(format: "%.1f", displayWeight)
            return "\(weightStr)x\(prevReps)"
        }
        return "-"
    }

    private var suggestedText: String {
        if let sugWeight = set.suggestedWeight, let sugReps = set.suggestedReps {
            let displayWeight = unitManager.convertWeightFromStorage(sugWeight)
            let weightStr = displayWeight.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(displayWeight))
                : String(format: "%.1f", displayWeight)
            return "\(weightStr)x\(sugReps)"
        }
        return "-"
    }
}

#Preview {
    ActiveWorkoutView(viewModel: WorkoutViewModel.shared)
}
