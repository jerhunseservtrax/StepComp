//
//  WorkoutViewModel.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 2/16/26.
//

import Foundation
import Combine

class WorkoutViewModel: ObservableObject {
    static let shared = WorkoutViewModel()
    
    @Published var workouts: [Workout] = []
    @Published var currentSession: WorkoutSession?
    @Published var sessionStartTime: Date?
    @Published var elapsedTime: TimeInterval = 0
    @Published var isPaused: Bool = false
    @Published var completedSessions: [CompletedWorkoutSession] = []
    @Published var workoutTargetDate: Date? // The date this workout should be logged for
    
    private var timer: Timer?
    private var pauseStartTime: Date?
    private var totalPausedTime: TimeInterval = 0
    
    private init() {
        loadWorkouts()
        loadCompletedSessions()
        migrateWeightsToKgIfNeeded()
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
        return workouts.filter { $0.assignedDays.contains(day) }
    }
    
    func getWorkoutsForToday() -> [Workout] {
        let today = DayOfWeek.from(date: Date())
        return getWorkoutsForDay(today)
    }
    
    func getNextWorkout() -> (workout: Workout, date: Date)? {
        let calendar = Calendar.current
        let today = Date()
        
        // Check today first
        let todayDay = DayOfWeek.from(date: today)
        if let todayWorkout = getWorkoutsForDay(todayDay).first {
            return (todayWorkout, today)
        }
        
        // Check next 7 days
        for daysAhead in 1...7 {
            guard let futureDate = calendar.date(byAdding: .day, value: daysAhead, to: today) else { continue }
            let futureDay = DayOfWeek.from(date: futureDate)
            if let workout = getWorkoutsForDay(futureDay).first {
                return (workout, futureDate)
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
                
                // Calculate progressive overload suggestions
                let (suggestedWeight, suggestedReps) = calculateProgressiveOverload(
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
        pushWidgetState()
    }
    
    func pauseWorkout() {
        isPaused = true
        pauseStartTime = Date()
        stopTimer()
        pushWidgetState()
    }
    
    func resumeWorkout() {
        if let pauseStart = pauseStartTime {
            totalPausedTime += Date().timeIntervalSince(pauseStart)
        }
        isPaused = false
        pauseStartTime = nil
        startTimer()
        pushWidgetState()
    }
    
    func finishWorkout() {
        guard var session = currentSession else { return }
        
        // Use the target date if set, otherwise use current date/time
        let calendar = Calendar.current
        
        // Set endTime to a time on the target date (use current time of day but on target date)
        let endTime: Date
        if let workoutTargetDate = workoutTargetDate,
           !calendar.isDateInToday(workoutTargetDate) {
            // If target date is not today, set endTime to 11:59 PM on that date
            let components = calendar.dateComponents([.year, .month, .day], from: workoutTargetDate)
            endTime = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: calendar.date(from: components) ?? workoutTargetDate) ?? Date()
        } else {
            // If target date is today or not set, use current time
            endTime = Date()
        }
        
        session.endTime = endTime
        session.isActive = false
        
        // Save completed session
        let completedSession = CompletedWorkoutSession(
            id: session.id,
            workoutId: session.workoutId,
            workoutName: session.workoutName,
            startTime: session.startTime,
            endTime: endTime,
            exercises: session.exercises
        )
        completedSessions.append(completedSession)
        saveCompletedSessions()
        
        // Update the workout's last completed date
        if let workoutIndex = workouts.firstIndex(where: { $0.id == session.workoutId }) {
            workouts[workoutIndex].lastCompletedAt = Date()
            saveWorkouts()
        }
        
        stopTimer()
        currentSession = nil
        sessionStartTime = nil
        elapsedTime = 0
        totalPausedTime = 0
        WorkoutLiveActivityManager.end()
        WorkoutWidgetStore.clear()
    }
    
    func cancelWorkout() {
        stopTimer()
        currentSession = nil
        sessionStartTime = nil
        elapsedTime = 0
        totalPausedTime = 0
        isPaused = false
        WorkoutLiveActivityManager.end()
        WorkoutWidgetStore.clear()
    }
    
    // MARK: - Set Management
    
    func updateSet(exerciseId: UUID, setId: UUID, weight: Int?, reps: Int?) {
        guard var session = currentSession else { return }
        
        if let exerciseIndex = session.exercises.firstIndex(where: { $0.id == exerciseId }),
           let setIndex = session.exercises[exerciseIndex].sets.firstIndex(where: { $0.id == setId }) {
            session.exercises[exerciseIndex].sets[setIndex].weight = weight
            session.exercises[exerciseIndex].sets[setIndex].reps = reps
            currentSession = session
        }
    }
    
    func completeSet(exerciseId: UUID, setId: UUID) {
        guard var session = currentSession else { return }
        
        if let exerciseIndex = session.exercises.firstIndex(where: { $0.id == exerciseId }),
           let setIndex = session.exercises[exerciseIndex].sets.firstIndex(where: { $0.id == setId }) {
            session.exercises[exerciseIndex].sets[setIndex].isCompleted = true
            currentSession = session
            HapticManager.shared.success()
            pushWidgetState()
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
        guard var session = currentSession else { return }
        
        if let exerciseIndex = session.exercises.firstIndex(where: { $0.id == exerciseId }) {
            let setNumber = session.exercises[exerciseIndex].sets.count + 1
            
            // Try to base suggestions on the last set in this exercise
            let lastSet = session.exercises[exerciseIndex].sets.last
            let (suggestedWeight, suggestedReps) = calculateProgressiveOverload(
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
        }
    }
    
    func removeSet(exerciseId: UUID, setId: UUID) {
        guard var session = currentSession else { return }
        
        if let exerciseIndex = session.exercises.firstIndex(where: { $0.id == exerciseId }) {
            // Remove the set
            session.exercises[exerciseIndex].sets.removeAll { $0.id == setId }
            
            // Renumber remaining sets
            for (index, _) in session.exercises[exerciseIndex].sets.enumerated() {
                session.exercises[exerciseIndex].sets[index].setNumber = index + 1
            }
            
            currentSession = session
            HapticManager.shared.light()
        }
    }
    
    // MARK: - Timer Management
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.sessionStartTime else { return }
            self.elapsedTime = Date().timeIntervalSince(startTime) - self.totalPausedTime
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
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
    
    /// Calculates progressive overload suggestions based on previous performance.
    /// Progressive overload strategy:
    /// - If previous reps >= 12: suggest weight increase (smaller weights get +2.5kg/5lbs, larger get +5kg/10lbs)
    /// - If previous reps 8-11: suggest +2 reps (maintain weight)
    /// - If previous reps < 8: suggest +2-3 reps (maintain weight)
    /// - If no previous data: return nil so user can set their starting weight
    private func calculateProgressiveOverload(previousWeight: Int?, previousReps: Int?) -> (suggestedWeight: Int?, suggestedReps: Int?) {
        guard let prevWeight = previousWeight, let prevReps = previousReps else {
            return (nil, nil)
        }
        
        var suggestedWeight = prevWeight
        var suggestedReps = prevReps
        
        // Progressive overload logic (weights stored in kg)
        if prevReps >= 12 {
            // High reps - suggest weight increase
            // For smaller weights (<25kg/55lbs), increase by 2.5kg (5lbs)
            // For larger weights, increase by 5kg (10lbs)
            let weightIncrement = prevWeight < 25 ? 2 : 5  // kg increments
            suggestedWeight = prevWeight + weightIncrement
            suggestedReps = max(8, prevReps - 2) // Drop reps slightly when increasing weight
        } else if prevReps >= 8 {
            // Mid range (8-11 reps) - suggest rep increase to hit upper range
            suggestedReps = min(12, prevReps + 2) // Cap at 12 reps
        } else {
            // Low reps (<8) - suggest more reps to build volume
            suggestedReps = min(10, prevReps + 3) // Build up to 8-10 rep range
        }
        
        return (suggestedWeight, suggestedReps)
    }
    
    func calculateEstimated1RM(weight: Int, reps: Int) -> Int {
        // Only calculate 1RM for rep ranges between 1-10 for best accuracy
        // Reps above 10 involve more endurance and less strength
        guard reps >= 1 && reps <= 10 else { return weight }
        
        // For 1 rep, the weight IS the 1RM
        if reps == 1 { return weight }
        
        // Epley formula: 1RM = weight × (1 + reps/30)
        // This is more conservative than Brzycki for higher reps
        let oneRM = Double(weight) * (1.0 + Double(reps) / 30.0)
        return Int(oneRM.rounded())
    }
    
    func getMaxEstimated1RM() -> Int {
        var maxOneRM = 0
        
        for session in completedSessions {
            for exercise in session.exercises {
                for set in exercise.sets where set.weight != nil && set.reps != nil && set.reps! <= 10 && set.reps! >= 1 {
                    let estimated = calculateEstimated1RM(weight: set.weight!, reps: set.reps!)
                    maxOneRM = max(maxOneRM, estimated)
                }
            }
        }
        
        return maxOneRM
    }
    
    func getMaxEstimated1RMForExercise(exerciseName: String) -> (weight: Int, exerciseName: String)? {
        var maxOneRM = 0
        var foundExercise = false
        
        for session in completedSessions {
            for exercise in session.exercises {
                // Check if exercise name matches (case insensitive, contains)
                if exerciseMatchesBigThree(exerciseName: exercise.exercise.name, category: exerciseName) {
                    foundExercise = true
                    for set in exercise.sets where set.weight != nil && set.reps != nil && set.reps! <= 10 && set.reps! >= 1 {
                        let estimated = calculateEstimated1RM(weight: set.weight!, reps: set.reps!)
                        maxOneRM = max(maxOneRM, estimated)
                    }
                }
            }
        }
        
        return foundExercise && maxOneRM > 0 ? (maxOneRM, exerciseName) : nil
    }
    
    /// Returns estimated 1RMs for squat, bench, and deadlift from all completed sessions.
    /// Uses Brzycki formula on best set per lift; nil for a lift if no matching data exists.
    func getBigThreeEstimated1RMs() -> (squat: Int?, bench: Int?, deadlift: Int?) {
        var squatRM: Int?
        var benchRM: Int?
        var deadliftRM: Int?
        
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
    
    func getPersonalBests() -> (maxWeight: Int, maxVolume: Int) {
        var maxWeight = 0
        var maxVolume = 0
        
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
                        newSet.weight = Int((Double(weight) / 2.20462).rounded())
                        didMigrate = true
                    }
                    if let prevWeight = set.previousWeight {
                        newSet.previousWeight = Int((Double(prevWeight) / 2.20462).rounded())
                        didMigrate = true
                    }
                    if let sugWeight = set.suggestedWeight {
                        newSet.suggestedWeight = Int((Double(sugWeight) / 2.20462).rounded())
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
                        newSet.weight = Int((Double(weight) / 2.20462).rounded())
                        didMigrate = true
                    }
                    if let prevWeight = set.previousWeight {
                        newSet.previousWeight = Int((Double(prevWeight) / 2.20462).rounded())
                        didMigrate = true
                    }
                    if let sugWeight = set.suggestedWeight {
                        newSet.suggestedWeight = Int((Double(sugWeight) / 2.20462).rounded())
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
}
