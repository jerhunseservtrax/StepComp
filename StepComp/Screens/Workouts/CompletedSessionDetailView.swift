//
//  CompletedSessionDetailView.swift
//  FitComp
//

import SwiftUI

struct CompletedSessionDetailView: View {
    let session: CompletedWorkoutSession
    @ObservedObject var viewModel: WorkoutViewModel
    @ObservedObject var unitManager: UnitPreferenceManager

    @Environment(\.dismiss) private var dismiss
    @State private var expandedExerciseIDs: Set<UUID> = []
    @State private var showingEdit = false

    private var durationText: String {
        let total = Int(session.duration)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }

    private var estimatedCalories: Int {
        Int((session.duration / 60.0) * 5.0)
    }

    private var prCount: Int {
        session.exercises.reduce(0) { running, exercise in
            running + exercise.sets.filter { isPRSet($0, exerciseName: exercise.exercise.name) }.count
        }
    }

    private var sessionDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: session.endTime)
    }

    private var sessionInfoText: String {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        return "\(dayFormatter.string(from: session.endTime)), \(timeFormatter.string(from: session.startTime)) - \(timeFormatter.string(from: session.endTime))"
    }

    private var sessionMuscleGroups: [MuscleGroup] {
        let allTargetStrings = session.exercises.map { $0.exercise.targetMuscles.lowercased() }
        return MuscleGroup.allCases.filter { group in
            allTargetStrings.contains(where: { target in
                group.matchKeywords.contains(where: { target.contains($0.lowercased()) })
            })
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FitCompColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text(sessionDateText)
                            .font(.system(size: 34, weight: .heavy))
                            .foregroundColor(FitCompColors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .center)

                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color.green)
                                .frame(width: 32, height: 32)
                                .background(Color.green.opacity(0.18))
                                .clipShape(Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(sessionInfoText)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(FitCompColors.textPrimary)
                                Text(session.workoutName)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(FitCompColors.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(.top, 6)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Workout Details")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(FitCompColors.textPrimary)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                DetailMetricCard(title: "Duration", value: durationText, tint: Color.yellow)
                                DetailMetricCard(title: "Energy", value: "\(estimatedCalories) Kcal", tint: Color.red)
                                DetailMetricCard(
                                    title: "Volume",
                                    value: "\(unitManager.formatWeight(session.totalVolume, decimals: 0)) \(unitManager.weightUnit.lowercased())",
                                    tint: Color.green
                                )
                                DetailMetricCard(title: "Records", value: "\(prCount)", tint: Color.blue)
                            }

                            HStack(spacing: 8) {
                                Text("Muscles")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(FitCompColors.textSecondary)
                                HStack(spacing: 6) {
                                    ForEach(Array(sessionMuscleGroups.prefix(4)), id: \.id) { group in
                                        Image(systemName: group.icon)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(FitCompColors.textPrimary)
                                            .frame(width: 26, height: 26)
                                            .background(Color.white.opacity(0.08))
                                            .cornerRadius(8)
                                    }
                                }
                                Spacer()
                                Text("Exercises \(session.exercises.count)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(FitCompColors.textSecondary)
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(18)

                        Text("Exercises")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(FitCompColors.textPrimary)

                        VStack(spacing: 14) {
                            ForEach(session.exercises) { workoutExercise in
                                exerciseCard(for: workoutExercise)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 10) {
                        Button(action: { showingEdit = true }) {
                            Image(systemName: "pencil")
                        }
                        Button(action: {}) {
                            Image(systemName: "bookmark")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingEdit) {
                EditCompletedSessionView(viewModel: viewModel, session: session)
            }
        }
    }

    @ViewBuilder
    private func exerciseCard(for workoutExercise: WorkoutExercise) -> some View {
        let completedSets = workoutExercise.sets.filter(\.isCompleted)
        let isExpanded = expandedExerciseIDs.contains(workoutExercise.id)
        let records = exerciseRecords(for: workoutExercise.exercise.name)

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.08))
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(FitCompColors.textPrimary)
                }
                .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 6) {
                    Text(workoutExercise.exercise.name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(FitCompColors.textPrimary)

                    ForEach(completedSets) { set in
                        HStack(spacing: 8) {
                            Text(setDisplayText(for: set))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(FitCompColors.textPrimary)

                            if isPRSet(set, exerciseName: workoutExercise.exercise.name) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color.green)
                            }
                        }
                    }
                }
                Spacer()
            }

            Button {
                toggleExpansion(for: workoutExercise.id)
            } label: {
                HStack(spacing: 6) {
                    Text(isExpanded ? "Hide records" : "Show records")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(FitCompColors.textSecondary)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(FitCompColors.textSecondary)
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .center)

            if isExpanded {
                VStack(spacing: 10) {
                    ExerciseRecordRow(title: "Projected 1 rep max", value: "\(unitManager.formatWeight(records.projected1RM, decimals: 1)) \(unitManager.weightUnit.lowercased())")
                    ExerciseRecordRow(title: "Max weight", value: "\(unitManager.formatWeight(records.maxWeight, decimals: 1)) \(unitManager.weightUnit.lowercased())")
                    ExerciseRecordRow(title: "Max repetitions", value: "\(records.maxReps) reps")
                    ExerciseRecordRow(title: "Max volume", value: "\(unitManager.formatWeight(records.maxVolume, decimals: 0)) \(unitManager.weightUnit.lowercased())")
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }

    private func toggleExpansion(for exerciseID: UUID) {
        if expandedExerciseIDs.contains(exerciseID) {
            expandedExerciseIDs.remove(exerciseID)
        } else {
            expandedExerciseIDs.insert(exerciseID)
        }
    }

    private func setDisplayText(for set: WorkoutSet) -> String {
        guard let reps = set.reps, let weight = set.weight else { return "-" }
        return "\(reps) x \(unitManager.formatWeight(weight, decimals: 0)) \(unitManager.weightUnit.lowercased())"
    }

    private func exerciseRecords(for exerciseName: String) -> (projected1RM: Double, maxWeight: Double, maxReps: Int, maxVolume: Double) {
        var projected1RM: Double = 0
        var maxWeight: Double = 0
        var maxReps: Int = 0
        var maxVolume: Double = 0

        let sessions = viewModel.completedSessions
        for item in sessions {
            for exercise in item.exercises where namesMatch(exercise.exercise.name, exerciseName) {
                for set in exercise.sets where set.isCompleted {
                    guard let weight = set.weight, let reps = set.reps else { continue }
                    projected1RM = max(projected1RM, viewModel.calculateEstimated1RM(weight: weight, reps: reps))
                    maxWeight = max(maxWeight, weight)
                    maxReps = max(maxReps, reps)
                    maxVolume = max(maxVolume, weight * Double(reps))
                }
            }
        }
        return (projected1RM, maxWeight, maxReps, maxVolume)
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

struct DetailMetricCard: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(FitCompColors.textSecondary)
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(tint)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.04))
        .cornerRadius(12)
    }
}

private struct ExerciseRecordRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.yellow)
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(FitCompColors.textPrimary)
            }
            Spacer()
            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(FitCompColors.textPrimary)
        }
    }
}
