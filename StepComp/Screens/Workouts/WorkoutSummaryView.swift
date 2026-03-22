//
//  WorkoutSummaryView.swift
//  FitComp
//

import SwiftUI

struct WorkoutSummaryView: View {
    let session: CompletedWorkoutSession
    @ObservedObject var viewModel: WorkoutViewModel
    @ObservedObject var unitManager: UnitPreferenceManager
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var appeared = false

    // MARK: - Computed Stats

    private var durationText: String {
        let total = Int(session.duration)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var totalSetsCompleted: Int {
        session.exercises.reduce(0) { $0 + $1.sets.filter(\.isCompleted).count }
    }

    private var totalVolume: String {
        let vol = unitManager.convertWeightFromStorage(session.totalVolume)
        if vol >= 1000 {
            return String(format: "%.1fk", vol / 1000)
        }
        return "\(Int(vol))"
    }

    private var exerciseCount: Int {
        session.exercises.count
    }

    private var estimatedCalories: Int {
        Int((session.duration / 60.0) * 5.0)
    }

    private var prCount: Int {
        session.exercises.reduce(0) { running, exercise in
            running + exercise.sets.filter { isPRSet($0, exerciseName: exercise.exercise.name) }.count
        }
    }

    private var muscleGroups: [MuscleGroup] {
        let allTargets = session.exercises.map { $0.exercise.targetMuscles.lowercased() }
        return MuscleGroup.allCases.filter { group in
            allTargets.contains { target in
                group.matchKeywords.contains { target.contains($0.lowercased()) }
            }
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            FitCompColors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Trophy header
                    headerSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)

                    // Stats grid
                    statsGrid
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 30)

                    // Muscles worked
                    if !muscleGroups.isEmpty {
                        musclesSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 30)
                    }

                    // Exercise breakdown
                    exerciseBreakdown
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 30)

                    // Done button
                    doneButton
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            HapticManager.shared.success()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(FitCompColors.primary.opacity(0.15))
                    .frame(width: 88, height: 88)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 40))
                    .foregroundColor(FitCompColors.primary)
            }

            Text("Workout Complete!")
                .font(.system(size: 28, weight: .black))
                .foregroundColor(FitCompColors.textPrimary)

            Text(session.workoutName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(FitCompColors.textSecondary)

            if prCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    Text("\(prCount) Personal Record\(prCount == 1 ? "" : "s")!")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(16)
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            SummaryStatCard(
                icon: "clock.fill",
                title: "Duration",
                value: durationText,
                color: FitCompColors.cyan
            )
            SummaryStatCard(
                icon: "flame.fill",
                title: "Calories",
                value: "\(estimatedCalories)",
                color: FitCompColors.coral
            )
            SummaryStatCard(
                icon: "scalemass.fill",
                title: "Volume",
                value: "\(totalVolume) \(unitManager.weightUnit)",
                color: FitCompColors.purple
            )
            SummaryStatCard(
                icon: "checkmark.circle.fill",
                title: "Sets",
                value: "\(totalSetsCompleted)",
                color: FitCompColors.green
            )
        }
    }

    // MARK: - Muscles Section

    private var musclesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MUSCLES WORKED")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(FitCompColors.textSecondary)
                .tracking(0.8)

            HStack(spacing: 10) {
                ForEach(muscleGroups.prefix(5)) { group in
                    VStack(spacing: 4) {
                        Image(systemName: group.icon)
                            .font(.system(size: 20))
                            .foregroundColor(FitCompColors.primary)
                        Text(group.rawValue)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(FitCompColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(14)
            .background(FitCompColors.surface)
            .cornerRadius(16)
        }
    }

    // MARK: - Exercise Breakdown

    private var exerciseBreakdown: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("EXERCISES")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(FitCompColors.textSecondary)
                .tracking(0.8)

            VStack(spacing: 0) {
                ForEach(Array(session.exercises.enumerated()), id: \.element.id) { index, exercise in
                    let completedSets = exercise.sets.filter(\.isCompleted)
                    if !completedSets.isEmpty {
                        HStack(spacing: 12) {
                            Text(exercise.exercise.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(FitCompColors.textPrimary)
                                .lineLimit(1)

                            Spacer()

                            Text(exerciseSummary(completedSets))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(FitCompColors.textSecondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)

                        if index < session.exercises.count - 1 {
                            Divider()
                                .padding(.horizontal, 14)
                        }
                    }
                }
            }
            .background(FitCompColors.surface)
            .cornerRadius(16)
        }
    }

    // MARK: - Done Button

    private var doneButton: some View {
        Button(action: onDismiss) {
            Text("DONE")
                .font(.system(size: 16, weight: .black))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(FitCompColors.primary)
                .foregroundColor(FitCompColors.buttonTextOnPrimary)
                .cornerRadius(26)
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func exerciseSummary(_ sets: [WorkoutSet]) -> String {
        let setDescriptions = sets.compactMap { set -> String? in
            guard let reps = set.reps else { return nil }
            if let weight = set.weight {
                let display = unitManager.convertWeightFromStorage(weight)
                let weightStr = display.truncatingRemainder(dividingBy: 1) == 0
                    ? "\(Int(display))"
                    : String(format: "%.1f", display)
                return "\(reps)x\(weightStr)"
            }
            return "\(reps) reps"
        }
        return "\(sets.count) sets"
    }

    private func isPRSet(_ set: WorkoutSet, exerciseName: String) -> Bool {
        guard set.isCompleted, let weight = set.weight, let reps = set.reps else { return false }
        let current1RM = viewModel.calculateEstimated1RM(weight: weight, reps: reps)

        for oldSession in viewModel.completedSessions {
            if oldSession.id == session.id || oldSession.endTime >= session.endTime {
                continue
            }
            for oldExercise in oldSession.exercises where namesMatch(oldExercise.exercise.name, exerciseName) {
                for oldSet in oldExercise.sets where oldSet.isCompleted {
                    guard let oldWeight = oldSet.weight, let oldReps = oldSet.reps else { continue }
                    let old1RM = viewModel.calculateEstimated1RM(weight: oldWeight, reps: oldReps)
                    if old1RM >= current1RM {
                        return false
                    }
                }
            }
        }
        return true
    }

    private func namesMatch(_ lhs: String, _ rhs: String) -> Bool {
        let left = lhs.lowercased()
        let right = rhs.lowercased()
        return left.contains(right) || right.contains(left)
    }
}

// MARK: - Stat Card

struct SummaryStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 22, weight: .black))
                .foregroundColor(FitCompColors.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(FitCompColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(FitCompColors.surface)
        .cornerRadius(16)
    }
}
