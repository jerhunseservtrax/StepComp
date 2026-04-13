//
//  WorkoutViewModel.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 2/16/26.
//

import Foundation
import Combine

// MARK: - Active Workout Draft Model
/// Persisted state for in-progress workouts to survive app suspension/termination
private struct ActiveWorkoutDraft: Codable {
    let session: WorkoutSession
    let sessionStartTime: Date
    let totalPausedTime: TimeInterval
    let isPaused: Bool
    let pauseStartTime: Date?
    let workoutTargetDate: Date?
}

@MainActor
class WorkoutViewModel: ObservableObject {
    static let shared = WorkoutViewModel()

    struct WeeklyWorkoutProgress {
        let scheduledCount: Int
        let completedCount: Int

        var progress: Double {
            guard scheduledCount > 0 else { return 0 }
            return Double(completedCount) / Double(scheduledCount)
        }
    }
    
    @Published var workouts: [Workout] = []
    @Published var currentSession: WorkoutSession?
    @Published var sessionStartTime: Date?
    @Published var elapsedTime: TimeInterval = 0
    @Published var isPaused: Bool = false
    @Published var completedSessions: [CompletedWorkoutSession] = []
    @Published var finishedSession: CompletedWorkoutSession?
    @Published var workoutTargetDate: Date? // The date this workout should be logged for
    @Published var isAutoFinishing: Bool = false
    
    private var timer: Timer?
    private var pauseStartTime: Date?
    private var totalPausedTime: TimeInterval = 0
    private let autoFinishThreshold: TimeInterval = 6 * 3600
    private let analytics = WorkoutAnalyticsEngine()
    private var autoFinishTask: Task<Void, Never>?
    
    private init() {
        loadWorkouts()
        loadCompletedSessions()
        backfillPerSideWeightInputModeIfNeeded()
        migrateWeightsToKgIfNeeded()
        loadActiveWorkoutDraftIfAny()
    }
    
    // MARK: - Workout Management
    
    func addWorkout(_ workout: Workout) {
        workouts.append(workout)
        saveWorkouts()
    }
    
    func updateWorkout(_ workout: Workout) {
        if let index = workouts.firstIndex(where: { $0.id == workout.id }) {
            workouts[index] = workout
            saveWorkouts()
        }
    }
    
    func deleteWorkout(_ workout: Workout) {
        workouts.removeAll { $0.id == workout.id }
        saveWorkouts()
    }
    
    func getWorkoutsForDay(_ day: DayOfWeek) -> [Workout] {
        return workouts.filter { !$0.isOneTime && $0.assignedDays.contains(day) }
    }

    func getWorkoutsForDate(_ date: Date) -> [Workout] {
        let day = DayOfWeek.from(date: date)
        let calendar = Calendar.current
        return workouts.filter { workout in
            if let oneTime = workout.oneTimeDate {
                return calendar.isDate(oneTime, inSameDayAs: date)
            }
            return workout.assignedDays.contains(day)
        }
    }

    func getWorkoutsForToday() -> [Workout] {
        return getWorkoutsForDate(Date())
    }
    
    func getNextWorkout() -> (workout: Workout, date: Date)? {
        let calendar = Calendar.current
        let today = Date()

        // Check today first, then the next 7 days
        for daysAhead in 0...7 {
            guard let date = calendar.date(byAdding: .day, value: daysAhead, to: today) else { continue }
            if let workout = getWorkoutsForDate(date).first {
                return (workout, date)
            }
        }

        return nil
    }
    
    // MARK: - Workout Session Management
    
    func startWorkout(_ workout: Workout, targetDate: Date = Date()) {
        workoutTargetDate = targetDate
        
        // Find the last completed session for this workout
        let lastSession = getLastCompletedSession(for: workout)
        
        let workoutExercises = workout.exercises.map { workoutExercise in
            // Find matching exercise in last session (case-insensitive name matching)
            let lastExercise = lastSession?.exercises.first { lastEx in
                lastEx.exercise.id == workoutExercise.exercise.id ||
                lastEx.exercise.name.lowercased() == workoutExercise.exercise.name.lowercased()
            }
            
            let sets = workoutExercise.sets.enumerated().map { (index, set) in
                // Get the corresponding set from last session by set number
                // If not found by set number, try to get any completed set as reference
                var lastSet = lastExercise?.sets.first { $0.setNumber == set.setNumber && $0.isCompleted }
                
                // If no matching set number, use the first completed set as reference
                if lastSet == nil {
                    lastSet = lastExercise?.sets.first { $0.isCompleted && $0.weight != nil && $0.reps != nil }
                }

                // Fallback to global history for this exercise when this workout has no direct history
                if lastSet == nil {
                    lastSet = latestCompletedSetForExercise(
                        exerciseName: workoutExercise.exercise.name,
                        setNumber: set.setNumber
                    )
                }
                if lastSet == nil {
                    lastSet = latestCompletedSetForExercise(exerciseName: workoutExercise.exercise.name)
                }
                
                // Calculate progressive overload suggestions using smart engine
                let (suggestedWeight, suggestedReps) = calculateProgressiveOverload(
                    exerciseName: workoutExercise.exercise.name,
                    setNumber: set.setNumber,
                    previousWeight: lastSet?.weight,
                    previousReps: lastSet?.reps
                )
                
                return WorkoutSet(
                    setNumber: set.setNumber,
                    previousWeight: lastSet?.weight,
                    previousReps: lastSet?.reps,
                    weight: lastSet?.weight, // Auto-populate with last weight
                    reps: lastSet?.reps,     // Auto-populate with last reps
                    isCompleted: false,
                    suggestedWeight: suggestedWeight,
                    suggestedReps: suggestedReps
                )
            }
            
            return WorkoutExercise(
                id: UUID(),
                exercise: workoutExercise.exercise,
                sets: sets
            )
        }
        
        currentSession = WorkoutSession(
            workoutId: workout.id,
            workoutName: workout.name,
            exercises: workoutExercises
        )
        sessionStartTime = Date()
        totalPausedTime = 0
        isPaused = false
        startTimer()
        saveActiveWorkoutDraft()
        pushWidgetState()
    }
    
    func pauseWorkout() {
        isPaused = true
        pauseStartTime = Date()
        stopTimer()
        saveActiveWorkoutDraft()
        pushWidgetState()
    }
    
    func resumeWorkout() {
        if let pauseStart = pauseStartTime {
            totalPausedTime += Date().timeIntervalSince(pauseStart)
        }
        isPaused = false
        pauseStartTime = nil
        startTimer()
        saveActiveWorkoutDraft()
        pushWidgetState()
    }
    
    func finishWorkout() {
        guard var session = currentSession else { return }
        
        // Use the target date if set, otherwise use current date/time
        let calendar = Calendar.current
        let now = Date()
        let effectiveDuration = max(0, computeActiveWorkoutDuration(at: now))
        
        // Set endTime to a time on the target date (use current time of day but on target date)
        let endTime: Date
        if let workoutTargetDate = workoutTargetDate,
           !calendar.isDateInToday(workoutTargetDate) {
            // If target date is not today, set endTime to 11:59 PM on that date
            let components = calendar.dateComponents([.year, .month, .day], from: workoutTargetDate)
            endTime = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: calendar.date(from: components) ?? workoutTargetDate) ?? Date()
        } else {
            // If target date is today or not set, use current time
            endTime = now
        }
        
        session.endTime = endTime
        session.isActive = false
        
        // Save completed session
        let completedSession = CompletedWorkoutSession(
            id: session.id,
            workoutId: session.workoutId,
            workoutName: session.workoutName,
            startTime: endTime.addingTimeInterval(-effectiveDuration),
            endTime: endTime,
            exercises: session.exercises
        )
        completedSessions.append(completedSession)
        saveCompletedSessions()
        
        // Sync to Supabase in the background (fire-and-forget)
        let sessionToSync = completedSession
        Task.detached(priority: .utility) {
            await MetricsService.shared.syncWorkoutSession(sessionToSync)
        }
        
        // Update the workout's last completed date
        if let workoutIndex = workouts.firstIndex(where: { $0.id == session.workoutId }) {
            workouts[workoutIndex].lastCompletedAt = Date()
            saveWorkouts()
        }

        finishedSession = completedSession

        autoFinishTask?.cancel()
        autoFinishTask = nil
        isAutoFinishing = false
        stopTimer()
        currentSession = nil
        sessionStartTime = nil
        elapsedTime = 0
        totalPausedTime = 0
        clearActiveWorkoutDraft()
        WorkoutLiveActivityManager.end()
        WorkoutWidgetStore.clear()
    }
    
    func cancelWorkout() {
        autoFinishTask?.cancel()
        autoFinishTask = nil
        isAutoFinishing = false
        stopTimer()
        currentSession = nil
        sessionStartTime = nil
        elapsedTime = 0
        totalPausedTime = 0
        isPaused = false
        clearActiveWorkoutDraft()
        WorkoutLiveActivityManager.end()
        WorkoutWidgetStore.clear()
    }
    
    // MARK: - Set Management
    
    func updateSet(
        exerciseId: UUID,
        setId: UUID,
        weight: Double?,
        reps: Int?,
        weightInputMode: WorkoutSet.WeightInputMode? = nil
    ) {
        guard var session = currentSession else { return }

        if let exerciseIndex = session.exercises.firstIndex(where: { $0.id == exerciseId }),
           let setIndex = session.exercises[exerciseIndex].sets.firstIndex(where: { $0.id == setId }) {
            session.exercises[exerciseIndex].sets[setIndex].weight = weight
            session.exercises[exerciseIndex].sets[setIndex].reps = reps
            if let weightInputMode {
                session.exercises[exerciseIndex].sets[setIndex].weightInputMode = weightInputMode
            }
            currentSession = session
            saveActiveWorkoutDraft()
        }
    }

    func updateExerciseWeightInputMode(exerciseId: UUID, mode: WorkoutSet.WeightInputMode) {
        guard var session = currentSession,
              let exerciseIndex = session.exercises.firstIndex(where: { $0.id == exerciseId }) else { return }

        let multiplier = WorkoutSet.perSideCombinedMultiplier
        for setIndex in session.exercises[exerciseIndex].sets.indices {
            let previousMode = session.exercises[exerciseIndex].sets[setIndex].weightInputMode
            guard previousMode != mode else {
                session.exercises[exerciseIndex].sets[setIndex].weightInputMode = mode
                continue
            }

            if let weight = session.exercises[exerciseIndex].sets[setIndex].weight {
                switch (previousMode, mode) {
                case (.total, .perSide):
                    session.exercises[exerciseIndex].sets[setIndex].weight = weight / multiplier
                case (.perSide, .total):
                    session.exercises[exerciseIndex].sets[setIndex].weight = weight * multiplier
                default:
                    break
                }
            }

            session.exercises[exerciseIndex].sets[setIndex].weightInputMode = mode
        }

        currentSession = session
        saveActiveWorkoutDraft()
    }

    func weeklyScheduledWorkoutProgress(for anchorDate: Date, weekStartsOnMonday: Bool = true) -> WeeklyWorkoutProgress {
        let calendar = Calendar.current
        let weekStart = startOfWeek(for: anchorDate, weekStartsOnMonday: weekStartsOnMonday)
        guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return WeeklyWorkoutProgress(scheduledCount: 0, completedCount: 0)
        }

        struct ScheduledWorkoutInstance: Hashable {
            let workoutId: UUID
            let date: Date
        }

        var scheduledInstances = Set<ScheduledWorkoutInstance>()
        for workout in workouts {
            if let oneTimeDate = workout.oneTimeDate {
                let normalizedDate = calendar.startOfDay(for: oneTimeDate)
                if normalizedDate >= weekStart && normalizedDate < weekEnd {
                    scheduledInstances.insert(ScheduledWorkoutInstance(workoutId: workout.id, date: normalizedDate))
                }
                continue
            }

            for offset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: offset, to: weekStart) else { continue }
                let day = DayOfWeek.from(date: date)
                guard workout.assignedDays.contains(day) else { continue }
                scheduledInstances.insert(
                    ScheduledWorkoutInstance(
                        workoutId: workout.id,
                        date: calendar.startOfDay(for: date)
                    )
                )
            }
        }

        var completedInstances = Set<ScheduledWorkoutInstance>()
        for session in completedSessions {
            let sessionDate = calendar.startOfDay(for: session.endTime)
            guard sessionDate >= weekStart, sessionDate < weekEnd else { continue }
            let instance = ScheduledWorkoutInstance(workoutId: session.workoutId, date: sessionDate)
            guard scheduledInstances.contains(instance) else { continue }
            completedInstances.insert(instance)
        }

        return WeeklyWorkoutProgress(
            scheduledCount: scheduledInstances.count,
            completedCount: completedInstances.count
        )
    }
    
    var allWorkoutSetsCompleted: Bool {
        guard let session = currentSession, !session.exercises.isEmpty else { return false }
        return session.exercises.allSatisfy { exercise in
            !exercise.sets.isEmpty && exercise.sets.allSatisfy(\.isCompleted)
        }
    }

    func completeSet(exerciseId: UUID, setId: UUID) {
        guard var session = currentSession else { return }
        
        if let exerciseIndex = session.exercises.firstIndex(where: { $0.id == exerciseId }),
           let setIndex = session.exercises[exerciseIndex].sets.firstIndex(where: { $0.id == setId }) {
            session.exercises[exerciseIndex].sets[setIndex].isCompleted = true
            currentSession = session
            HapticManager.shared.success()
            saveActiveWorkoutDraft()
            pushWidgetState()

            if allWorkoutSetsCompleted {
                scheduleAutoFinish()
            }
        }
    }

    func cancelAutoFinish() {
        autoFinishTask?.cancel()
        autoFinishTask = nil
        isAutoFinishing = false
    }

    private func scheduleAutoFinish() {
        autoFinishTask?.cancel()
        isAutoFinishing = true
        autoFinishTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard let self, !Task.isCancelled, self.isAutoFinishing, self.allWorkoutSetsCompleted else {
                self?.isAutoFinishing = false
                return
            }
            self.finishWorkout()
        }
    }
    
    func getNextIncompleteSet(after setId: UUID, in exerciseId: UUID) -> WorkoutSet? {
        guard let session = currentSession,
              let exerciseIndex = session.exercises.firstIndex(where: { $0.id == exerciseId }) else {
            return nil
        }
        
        let exercise = session.exercises[exerciseIndex]
        
        // Find current set index
        guard let currentSetIndex = exercise.sets.firstIndex(where: { $0.id == setId }) else {
            return nil
        }
        
        // Look for next incomplete set in same exercise
        for set in exercise.sets[(currentSetIndex + 1)...] {
            if !set.isCompleted {
                return set
            }
        }
        
        return nil
    }
    
    func allSetsCompleted(in exerciseId: UUID) -> Bool {
        guard let session = currentSession,
              let exercise = session.exercises.first(where: { $0.id == exerciseId }) else {
            return false
        }
        
        return exercise.sets.allSatisfy { $0.isCompleted }
    }
    
    func addSet(exerciseId: UUID) {
        cancelAutoFinish()
        guard var session = currentSession else { return }
        
        if let exerciseIndex = session.exercises.firstIndex(where: { $0.id == exerciseId }) {
            let setNumber = session.exercises[exerciseIndex].sets.count + 1
            
            // Try to base suggestions on the last set in this exercise
            let lastSet = session.exercises[exerciseIndex].sets.last
            let exerciseName = session.exercises[exerciseIndex].exercise.name
            let (suggestedWeight, suggestedReps) = calculateProgressiveOverload(
                exerciseName: exerciseName,
                setNumber: setNumber,
                previousWeight: lastSet?.weight ?? lastSet?.previousWeight,
                previousReps: lastSet?.reps ?? lastSet?.previousReps
            )
            
            let newSet = WorkoutSet(
                setNumber: setNumber,
                previousWeight: lastSet?.previousWeight,
                previousReps: lastSet?.previousReps,
                suggestedWeight: suggestedWeight,
                suggestedReps: suggestedReps
            )
            session.exercises[exerciseIndex].sets.append(newSet)
            currentSession = session
            saveActiveWorkoutDraft()
        }
    }
    
    func removeSet(exerciseId: UUID, setId: UUID) {
        guard var session = currentSession else { return }
        
        if let exerciseIndex = session.exercises.firstIndex(where: { $0.id == exerciseId }) {
            // Remove the set
            session.exercises[exerciseIndex].sets.removeAll { $0.id == setId }
            
            // If no sets remain, remove the exercise entirely
            if session.exercises[exerciseIndex].sets.isEmpty {
                session.exercises.remove(at: exerciseIndex)
            } else {
                // Renumber remaining sets
                for (index, _) in session.exercises[exerciseIndex].sets.enumerated() {
                    session.exercises[exerciseIndex].sets[index].setNumber = index + 1
                }
            }

            currentSession = session
            HapticManager.shared.light()
            saveActiveWorkoutDraft()
        }
    }
    
    // MARK: - Timer Management
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let startTime = self.sessionStartTime else { return }
                self.elapsedTime = Date().timeIntervalSince(startTime) - self.totalPausedTime

                if self.elapsedTime >= self.autoFinishThreshold {
                    self.finishWorkout()
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    /// Computes active workout duration using tracked pause state.
    /// This keeps completed session duration accurate even when endTime is adjusted to a selected calendar date.
    private func computeActiveWorkoutDuration(at referenceTime: Date) -> TimeInterval {
        guard let startTime = sessionStartTime else { return 0 }

        let pausedDuration: TimeInterval
        if isPaused, let pauseStart = pauseStartTime {
            pausedDuration = totalPausedTime + referenceTime.timeIntervalSince(pauseStart)
        } else {
            pausedDuration = totalPausedTime
        }

        return max(0, referenceTime.timeIntervalSince(startTime) - pausedDuration)
    }

    /// Current exercise for the widget: first with incomplete sets, or last exercise.
    private func currentExerciseName(from session: WorkoutSession) -> String? {
        let firstIncomplete = session.exercises.first { ex in
            !ex.sets.allSatisfy(\.isCompleted)
        }
        if let ex = firstIncomplete {
            return ex.exercise.name
        }
        return session.exercises.last?.exercise.name
    }

    private func pushWidgetState() {
        guard let session = currentSession,
              let start = sessionStartTime else {
            WorkoutLiveActivityManager.end()
            WorkoutWidgetStore.clear()
            return
        }
        let currentName = currentExerciseName(from: session)
        let totalPaused: TimeInterval
        if isPaused, let pauseStart = pauseStartTime {
            totalPaused = totalPausedTime + Date().timeIntervalSince(pauseStart)
        } else {
            totalPaused = totalPausedTime
        }

        if WorkoutLiveActivityManager.currentActivity != nil {
            WorkoutLiveActivityManager.update(
                sessionStartTime: start,
                totalPausedTime: totalPaused,
                isPaused: isPaused,
                currentExerciseName: currentName
            )
        } else {
            WorkoutLiveActivityManager.start(
                workoutName: session.workoutName,
                sessionStartTime: start,
                currentExerciseName: currentName
            )
        }

        WorkoutWidgetStore.update(
            active: true,
            sessionStartTime: start,
            totalPausedTime: totalPaused,
            isPaused: isPaused,
            workoutName: session.workoutName,
            currentExerciseName: currentName
        )
    }
    
    func formattedElapsedTime() -> String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Metrics Calculations
    
    /// Returns the most recent completed session for a given workout.
    /// Matches by workoutId first, falls back to workoutName for resilience.
    private func getLastCompletedSession(for workout: Workout) -> CompletedWorkoutSession? {
        return completedSessions
            .filter { session in
                session.workoutId == workout.id || session.workoutName == workout.name
            }
            .sorted { $0.endTime > $1.endTime }
            .first
    }

    private func latestCompletedSetForExercise(exerciseName: String, setNumber: Int) -> WorkoutSet? {
        let targetName = exerciseName.lowercased()
        let sortedSessions = completedSessions.sorted { $0.endTime > $1.endTime }

        for session in sortedSessions {
            for exercise in session.exercises where exercise.exercise.name.lowercased() == targetName {
                if let matchingSet = exercise.sets.first(where: {
                    $0.setNumber == setNumber && $0.isCompleted && $0.weight != nil && $0.reps != nil
                }) {
                    return matchingSet
                }
            }
        }
        return nil
    }

    private func latestCompletedSetForExercise(exerciseName: String) -> WorkoutSet? {
        let targetName = exerciseName.lowercased()
        let sortedSessions = completedSessions.sorted { $0.endTime > $1.endTime }

        for session in sortedSessions {
            for exercise in session.exercises where exercise.exercise.name.lowercased() == targetName {
                if let completedSet = exercise.sets.first(where: {
                    $0.isCompleted && $0.weight != nil && $0.reps != nil
                }) {
                    return completedSet
                }
            }
        }
        return nil
    }

    /// Gathers up to the last 10 completed sets for a specific exercise and set number
    /// across all completed sessions, sorted newest first.
    func getExerciseHistory(exerciseName: String, setNumber: Int = 1, limit: Int = 10) -> [HistoricalSet] {
        let nameLower = exerciseName.lowercased()
        var results: [HistoricalSet] = []

        // Walk sessions newest-first
        let sortedSessions = completedSessions.sorted { $0.endTime > $1.endTime }

        for session in sortedSessions {
            guard results.count < limit else { break }

            for exercise in session.exercises {
                guard exercise.exercise.name.lowercased() == nameLower else { continue }

                // Find the matching set number (or first completed set as fallback)
                let matchingSet = exercise.sets.first {
                    $0.setNumber == setNumber && $0.isCompleted && $0.weight != nil && $0.reps != nil
                } ?? exercise.sets.first {
                    $0.isCompleted && $0.weight != nil && $0.reps != nil
                }

                if let set = matchingSet, let effectiveWeight = set.effectiveWeightForVolume, let reps = set.reps {
                    results.append(HistoricalSet(date: session.endTime, weight: effectiveWeight, reps: reps))
                }
            }
        }

        return results
    }

    /// Gathers all completed sets for an exercise across recent sessions (for 1RM estimation).
    func getAllExerciseHistory(exerciseName: String, limit: Int = 10) -> [HistoricalSet] {
        let nameLower = exerciseName.lowercased()
        var results: [HistoricalSet] = []

        let sortedSessions = completedSessions.sorted { $0.endTime > $1.endTime }

        for session in sortedSessions.prefix(limit) {
            for exercise in session.exercises {
                guard exercise.exercise.name.lowercased() == nameLower else { continue }
                for set in exercise.sets where set.isCompleted && set.effectiveWeightForVolume != nil && set.reps != nil {
                    results.append(HistoricalSet(date: session.endTime, weight: set.effectiveWeightForVolume!, reps: set.reps!))
                }
            }
        }

        return results
    }

    /// Calculates progressive overload suggestions using the smart engine.
    /// Analyzes up to 10 prior sessions for trend detection.
    /// Falls back to simple logic if no history exists.
    private func calculateProgressiveOverload(
        exerciseName: String,
        setNumber: Int,
        previousWeight: Double?,
        previousReps: Int?
    ) -> (suggestedWeight: Double?, suggestedReps: Int?) {
        let history = getExerciseHistory(exerciseName: exerciseName, setNumber: setNumber)

        if let suggestion = analytics.smartOverloadSuggestion(history: history, exerciseName: exerciseName) {
            return (suggestion.suggestedWeight, suggestion.suggestedReps)
        }

        // Fallback to simple logic when no history
        let simple = analytics.progressiveOverloadSuggestion(
            previousWeight: previousWeight,
            previousReps: previousReps
        )
        return (simple.0, simple.1)
    }
    
    /// Returns a smart rest timer duration based on the exertion of the just-completed set.
    func suggestRestDuration(exerciseName: String, weight: Double, reps: Int) -> RestSuggestion {
        let history = getAllExerciseHistory(exerciseName: exerciseName)
        return analytics.suggestRestDuration(
            completedWeight: weight,
            completedReps: reps,
            exerciseName: exerciseName,
            exerciseHistory: history
        )
    }

    func calculateEstimated1RM(weight: Double, reps: Int) -> Double {
        analytics.estimatedOneRepMax(weight: weight, reps: reps)
    }
    
    func getMaxEstimated1RM() -> Double {
        var maxOneRM: Double = 0
        
        for session in completedSessions {
            for exercise in session.exercises {
                for set in exercise.sets where set.effectiveWeightForVolume != nil && set.reps != nil && set.reps! <= 10 && set.reps! >= 1 {
                    let estimated = calculateEstimated1RM(weight: set.effectiveWeightForVolume!, reps: set.reps!)
                    maxOneRM = max(maxOneRM, estimated)
                }
            }
        }
        
        return maxOneRM
    }
    
    func getMaxEstimated1RMForExercise(exerciseName: String) -> (weight: Double, exerciseName: String)? {
        var maxOneRM: Double = 0
        var foundExercise = false
        
        for session in completedSessions {
            for exercise in session.exercises {
                // Check if exercise name matches (case insensitive, contains)
                if exerciseMatchesBigThree(exerciseName: exercise.exercise.name, category: exerciseName) {
                    foundExercise = true
                    for set in exercise.sets where set.effectiveWeightForVolume != nil && set.reps != nil && set.reps! <= 10 && set.reps! >= 1 {
                        let estimated = calculateEstimated1RM(weight: set.effectiveWeightForVolume!, reps: set.reps!)
                        maxOneRM = max(maxOneRM, estimated)
                    }
                }
            }
        }
        
        return foundExercise && maxOneRM > 0 ? (maxOneRM, exerciseName) : nil
    }
    
    /// Returns estimated 1RMs for squat, bench, and deadlift from all completed sessions.
    /// Uses Brzycki formula on best set per lift; nil for a lift if no matching data exists.
    func getBigThreeEstimated1RMs() -> (squat: Double?, bench: Double?, deadlift: Double?) {
        var squatRM: Double?
        var benchRM: Double?
        var deadliftRM: Double?
        
        if let s = getMaxEstimated1RMForExercise(exerciseName: "Squat") { squatRM = s.weight }
        if let b = getMaxEstimated1RMForExercise(exerciseName: "Bench") { benchRM = b.weight }
        if let d = getMaxEstimated1RMForExercise(exerciseName: "Deadlift") { deadliftRM = d.weight }
        
        return (squat: squatRM, bench: benchRM, deadlift: deadliftRM)
    }
    
    /// Maps exercise names to big-three categories so variants (e.g. Back Squat, Front Squat, Bench Press) all count.
    private func exerciseMatchesBigThree(exerciseName: String, category: String) -> Bool {
        let name = exerciseName.lowercased()
        let cat = category.lowercased()
        if name.contains(cat) { return true }
        // Explicit mappings for common variants
        switch cat {
        case "squat":
            return name.contains("squat") // Back Squat, Front Squat, etc.
        case "bench":
            return name.contains("bench") // Bench Press, Incline Bench, etc.
        case "deadlift":
            return name.contains("deadlift") // Deadlift, Sumo Deadlift, etc.
        default:
            return name.contains(cat)
        }
    }
    
    func getAvailableCompoundLifts() -> [String] {
        let compoundLifts = ["Bench", "Squat", "Deadlift"]
        var available: [String] = []
        
        for lift in compoundLifts {
            if getMaxEstimated1RMForExercise(exerciseName: lift) != nil {
                available.append(lift)
            }
        }
        
        return available
    }
    
    func getPersonalBests() -> (maxWeight: Double, maxVolume: Double) {
        var maxWeight: Double = 0
        var maxVolume: Double = 0
        
        for session in completedSessions {
            maxWeight = max(maxWeight, session.maxWeight)
            maxVolume = max(maxVolume, session.totalVolume)
        }
        
        return (maxWeight, maxVolume)
    }
    
    func getConsistencyData(days: Int = 90) -> [Date: Bool] {
        let calendar = Calendar.current
        var consistencyMap: [Date: Bool] = [:]
        
        // Initialize all days from (days) ago to today
        let today = calendar.startOfDay(for: Date())
        for dayOffset in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                let startOfDay = calendar.startOfDay(for: date)
                consistencyMap[startOfDay] = false
            }
        }
        
        // Mark days with completed workouts as true
        for session in completedSessions {
            let startOfDay = calendar.startOfDay(for: session.endTime)
            // Only mark if within our date range
            if consistencyMap.keys.contains(startOfDay) {
                consistencyMap[startOfDay] = true
            }
        }
        
        return consistencyMap
    }
    
    func getCurrentStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var currentDate = today
        
        while true {
            let hasSessions = completedSessions.contains { session in
                calendar.isDate(session.endTime, inSameDayAs: currentDate)
            }
            
            if hasSessions {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                currentDate = previousDay
            } else {
                // If today doesn't have a session, check yesterday for grace period
                if calendar.isDate(currentDate, inSameDayAs: today) {
                    guard let yesterday = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                    currentDate = yesterday
                    continue
                }
                break
            }
        }
        
        return streak
    }
    
    func getTotalSessions() -> Int {
        return completedSessions.count
    }
    
    /// Returns true if the given workout was completed on the given date.
    /// Matches by workoutId first, falls back to workoutName for resilience.
    func wasWorkoutCompleted(workout: Workout, on date: Date) -> Bool {
        let calendar = Calendar.current
        return completedSessions.contains { session in
            let sameDay = calendar.isDate(session.endTime, inSameDayAs: date)
            let sameWorkout = session.workoutId == workout.id || session.workoutName == workout.name
            return sameDay && sameWorkout
        }
    }
    
    // MARK: - Persistence
    
    private func saveWorkouts() {
        if let encoded = try? JSONEncoder().encode(workouts) {
            UserDefaults.standard.set(encoded, forKey: "saved_workouts")
        }
    }
    
    private func loadWorkouts() {
        if let data = UserDefaults.standard.data(forKey: "saved_workouts"),
           let decoded = try? JSONDecoder().decode([Workout].self, from: data) {
            workouts = decoded
        }
    }
    
    func saveCompletedSessions() {
        if let encoded = try? JSONEncoder().encode(completedSessions) {
            UserDefaults.standard.set(encoded, forKey: "completed_workout_sessions")
        }
    }
    
    private func loadCompletedSessions() {
        if let data = UserDefaults.standard.data(forKey: "completed_workout_sessions"),
           let decoded = try? JSONDecoder().decode([CompletedWorkoutSession].self, from: data) {
            completedSessions = decoded
        }
    }
    
    // MARK: - Active Workout Draft Persistence
    
    /// Saves the current active workout state to survive app suspension/termination
    private func saveActiveWorkoutDraft() {
        guard let session = currentSession,
              let startTime = sessionStartTime else {
            clearActiveWorkoutDraft()
            return
        }
        
        let draft = ActiveWorkoutDraft(
            session: session,
            sessionStartTime: startTime,
            totalPausedTime: totalPausedTime,
            isPaused: isPaused,
            pauseStartTime: pauseStartTime,
            workoutTargetDate: workoutTargetDate
        )
        
        if let encoded = try? JSONEncoder().encode(draft) {
            UserDefaults.standard.set(encoded, forKey: "active_workout_draft")
            print("💾 Active workout draft saved")
        }
    }
    
    /// Loads and restores an active workout draft if one exists
    private func loadActiveWorkoutDraftIfAny() {
        guard let data = UserDefaults.standard.data(forKey: "active_workout_draft"),
              let draft = try? JSONDecoder().decode(ActiveWorkoutDraft.self, from: data) else {
            print("ℹ️ No active workout draft found")
            return
        }
        
        print("🔄 Restoring active workout draft")
        
        // Restore session state
        currentSession = draft.session
        sessionStartTime = draft.sessionStartTime
        totalPausedTime = draft.totalPausedTime
        isPaused = draft.isPaused
        pauseStartTime = draft.pauseStartTime
        workoutTargetDate = draft.workoutTargetDate
        
        // Refresh elapsed time based on saved timestamps
        refreshElapsedTime()
        
        // Restart timer if not paused
        if !isPaused {
            startTimer()
        }
        
        // Sync widget and live activity state
        pushWidgetState()
        
        print("✅ Active workout draft restored successfully")
    }
    
    /// Clears the active workout draft from persistence
    private func clearActiveWorkoutDraft() {
        UserDefaults.standard.removeObject(forKey: "active_workout_draft")
        print("🧹 Active workout draft cleared")
    }
    
    /// Recalculates elapsed time based on stored timestamps and paused duration
    private func refreshElapsedTime() {
        guard let startTime = sessionStartTime else {
            elapsedTime = 0
            return
        }
        
        // Calculate current paused time if currently paused
        let currentPausedTime: TimeInterval
        if isPaused, let pauseStart = pauseStartTime {
            currentPausedTime = totalPausedTime + Date().timeIntervalSince(pauseStart)
        } else {
            currentPausedTime = totalPausedTime
        }
        
        // Calculate elapsed time
        elapsedTime = Date().timeIntervalSince(startTime) - currentPausedTime
    }
    
    /// Public method to reconcile state on app lifecycle transitions
    func reconcileActiveWorkoutState() {
        if currentSession != nil {
            // Refresh elapsed time and save draft
            refreshElapsedTime()
            saveActiveWorkoutDraft()
        } else {
            // No active session, ensure draft and widget are cleared
            clearActiveWorkoutDraft()
            WorkoutWidgetStore.clear()
            WorkoutLiveActivityManager.end()
        }
    }
    
    /// Clears all active workout state (draft, widget, live activity)
    static func clearAllActiveWorkoutState() {
        let vm = WorkoutViewModel.shared
        vm.clearActiveWorkoutDraft()
        WorkoutWidgetStore.clear()
        WorkoutLiveActivityManager.end()
        print("🧹 All active workout state cleared")
    }
    
    // MARK: - Data Migration
    
    /// Migrates workout weights from lbs to kg storage format.
    /// This runs once per installation to convert legacy data.
    /// Assumes user was using imperial units (lbs) before the migration.
    private func migrateWeightsToKgIfNeeded() {
        let migrationKey = "weights_migrated_to_kg_v1"
        
        // Check if migration already completed
        if UserDefaults.standard.bool(forKey: migrationKey) {
            return
        }
        
        print("🔄 Migrating workout weights from lbs to kg...")
        
        // Migrate completed sessions
        var didMigrate = false
        completedSessions = completedSessions.map { session in
            let migratedExercises = session.exercises.map { exercise in
                let migratedSets = exercise.sets.map { set in
                    var newSet = set
                    if let weight = set.weight {
                        newSet.weight = weight / 2.20462
                        didMigrate = true
                    }
                    if let prevWeight = set.previousWeight {
                        newSet.previousWeight = prevWeight / 2.20462
                        didMigrate = true
                    }
                    if let sugWeight = set.suggestedWeight {
                        newSet.suggestedWeight = sugWeight / 2.20462
                        didMigrate = true
                    }
                    return newSet
                }
                return WorkoutExercise(id: exercise.id, exercise: exercise.exercise, sets: migratedSets)
            }
            return CompletedWorkoutSession(
                id: session.id,
                workoutId: session.workoutId,
                workoutName: session.workoutName,
                startTime: session.startTime,
                endTime: session.endTime,
                exercises: migratedExercises
            )
        }
        
        // Migrate current session if active
        if let session = currentSession {
            let migratedExercises = session.exercises.map { exercise in
                let migratedSets = exercise.sets.map { set in
                    var newSet = set
                    if let weight = set.weight {
                        newSet.weight = weight / 2.20462
                        didMigrate = true
                    }
                    if let prevWeight = set.previousWeight {
                        newSet.previousWeight = prevWeight / 2.20462
                        didMigrate = true
                    }
                    if let sugWeight = set.suggestedWeight {
                        newSet.suggestedWeight = sugWeight / 2.20462
                        didMigrate = true
                    }
                    return newSet
                }
                return WorkoutExercise(id: exercise.id, exercise: exercise.exercise, sets: migratedSets)
            }
            currentSession = WorkoutSession(
                id: session.id,
                workoutId: session.workoutId,
                workoutName: session.workoutName,
                startTime: session.startTime,
                endTime: session.endTime,
                exercises: migratedExercises,
                isActive: session.isActive
            )
        }
        
        if didMigrate {
            // Save migrated data
            saveCompletedSessions()
            print("✅ Migration complete: Workout weights converted to kg")
        } else {
            print("✅ No workout data to migrate")
        }
        
        // Mark migration as complete
        UserDefaults.standard.set(true, forKey: migrationKey)
    }

    /// Best-effort migration for legacy set data that was likely entered as per-side load.
    /// Applies only once and only to high-confidence dumbbell naming patterns.
    private func backfillPerSideWeightInputModeIfNeeded() {
        let migrationKey = "set_weight_mode_per_side_backfill_v1"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        var didMigrate = false

        completedSessions = completedSessions.map { session in
            let migratedExercises = session.exercises.map { exercise in
                guard shouldDefaultToPerSide(exerciseName: exercise.exercise.name) else {
                    return exercise
                }
                let migratedSets = exercise.sets.map { set -> WorkoutSet in
                    guard set.weightInputMode == .total else { return set }
                    var updated = set
                    updated.weightInputMode = .perSide
                    didMigrate = true
                    return updated
                }
                return WorkoutExercise(id: exercise.id, exercise: exercise.exercise, sets: migratedSets)
            }
            return CompletedWorkoutSession(
                id: session.id,
                workoutId: session.workoutId,
                workoutName: session.workoutName,
                startTime: session.startTime,
                endTime: session.endTime,
                exercises: migratedExercises
            )
        }

        if didMigrate {
            saveCompletedSessions()
            print("✅ Backfilled per-side logging mode for legacy dumbbell sets")
        }

        UserDefaults.standard.set(true, forKey: migrationKey)
    }

    private func shouldDefaultToPerSide(exerciseName: String) -> Bool {
        let name = exerciseName.lowercased()
        return name.contains("dumbbell")
            || name.contains(" db ")
            || name.hasPrefix("db ")
            || name.contains("(db")
            || name.contains("arnold press")
    }

    private func startOfWeek(for date: Date, weekStartsOnMonday: Bool = true) -> Date {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: normalizedDate)
        let daysFromStart = weekStartsOnMonday ? (weekday + 5) % 7 : (weekday - 1)
        return calendar.date(byAdding: .day, value: -daysFromStart, to: normalizedDate) ?? normalizedDate
    }
}
