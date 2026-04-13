//
//  Exercise.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 2/16/26.
//

import Foundation

struct Exercise: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let targetMuscles: String
    let imageURL: String?
    
    init(id: UUID = UUID(), name: String, targetMuscles: String, imageURL: String? = nil) {
        self.id = id
        self.name = name
        self.targetMuscles = targetMuscles
        self.imageURL = imageURL
    }

    var exerciseDBId: String? {
        Exercise.exerciseDBIds[name]
    }
}

extension Exercise {
    private static let searchAliases: [String: [String]] = [
        "v bar push downs": ["v-bar pushdown", "v bar pushdown", "vbar pushdown", "tricep pushdown", "triceps pushdown"]
    ]

    static let exerciseDBIds: [String: String] = [
        "Arnold Press": "0287",
        "Assisted Dip (Machine)": "0251",
        "Assisted Pull-Up": "0017",
        "Ab Wheel Rollout": "0857",
        "Back Extension": "0573",
        "Back Squat": "0043",
        "Barbell Bench Press": "0025",
        "Barbell Bent Over Row": "0027",
        "Barbell Squat": "0043",
        "Bench Press (Barbell)": "0025",
        "Barbell Curl": "0031",
        "Barbell Row": "0027",
        "Bent Over Row (Barbell)": "0027",
        "Bench Press": "0025",
        "Bent Over Row": "0027",
        "Bicep Curl": "0294",
        "Bicep Curl (Dumbbell)": "0294",
        "Dumbbell Bicep Curl": "0294",
        "Box Jump": "1374",
        "Bulgarian Split Squat": "0410",
        "Cable Crunch": "0175",
        "Cable Fly": "0227",
        "Cable Lateral Raise": "0178",
        "Cable Row": "0861",
        "Calf Raise": "1372",
        "Chest Dip": "0251",
        "Chest Fly": "0308",
        "Chest fly": "0308",
        "Chin-Up": "0253",
        "Close Grip Bench Press": "0030",
        "Concentration Curl": "0297",
        "Crunch": "0274",
        "Deadlift": "0032",
        "Decline Bench Press": "0033",
        "Decline Crunch": "0277",
        "Diamond Push-Up": "0283",
        "Dips": "0251",
        "Donkey Kick": "0284",
        "Elliptical": "2141",
        "EZ Bar Curl": "0447",
        "EZ Bar Biceps Curl": "0447",
        "Face Pull": "0075",
        "Farmer's Carry": "2133",
        "Flat Bench Press": "0025",
        "Flutter Kicks": "0459",
        "Front Raise": "0309",
        "Front Squat": "0042",
        "Glute Bridge": "1409",
        "Glute Ham Raise": "3193",
        "Glute Kickback Machine": "0284",
        "Goblet Squat": "0534",
        "Good Morning": "0044",
        "Hack Squat": "0046",
        "Hammer Curl": "0312",
        "Horizontal Leg Press": "0739",
        "Hanging Leg Raise": "0472",
        "Hip Abduction": "0597",
        "Hip Adduction": "0168",
        "Hip Thrust": "3236",
        "Hip Thrust (Machine)": "3236",
        "Incline Bench Press": "0047",
        "Incline Bench Press (Dumbbell)": "0314",
        "Incline DB Bench Press": "0314",
        "Incline Dumbbell Press": "0314",
        "Inverted Row": "0497",
        "Jump Squat": "0053",
        "Jump Rope": "2612",
        "Kettlebell Swing": "0549",
        "Kettlebell Clean": "0518",
        "Kettlebell Snatch": "0517",
        "Lat Pulldown": "0673",
        "Lat Pulldown (Cable)": "0673",
        "Lateral Raise": "0334",
        "Leg Curl": "0586",
        "Seated Leg Curl": "0586",
        "Leg Extension": "0585",
        "Leg Extension (Machine)": "0585",
        "Leg Press": "0739",
        "Leg Press (Machine)": "0739",
        "Leg Raise": "0012",
        "Lunge": "0054",
        "Lunge (Dumbbell)": "0054",
        "Dumbbell Lunges (Per Leg)": "0054",
        "Lying Leg Curl": "0586",
        "Machine Bicep Curl": "0294",
        "Machine Chest Press": "0025",
        "Machine Fly (Chest)": "0308",
        "Machine Incline Chest Press": "0314",
        "Machine Lateral Raise": "0334",
        "Machine Pec Deck": "0308",
        "Machine Preacher Curl": "0059",
        "Machine Shrug": "0406",
        "Machine Triceps Extension": "0194",
        "Mountain Climbers": "0630",
        "Military Press": "0086",
        "Overhead Press": "0426",
        "Pec Deck Fly": "0308",
        "Pendlay Row": "3017",
        "Plank": "3327",
        "Preacher Curl": "0059",
        "Pull-Up": "0651",
        "Pull-Ups": "0651",
        "Pull Up": "0651",
        "Push Press": "0528",
        "Push-Up": "0662",
        "Push-Ups": "0662",
        "Push Up": "0662",
        "Rear Delt Fly": "2292",
        "Romanian Deadlift": "0085",
        "Romanian Deadlift (Barbell)": "0085",
        "Row (Machine)": "0180",
        "Russian Twist": "0014",
        "Seated Calf Raise": "0088",
        "Seated Calf Raise (Machine)": "0088",
        "Seated Hip Abduction (Machine)": "0597",
        "Seated Hip Adduction (Machine)": "0168",
        "Seated Row": "0861",
        "Seated Shoulder Press (Machine)": "0405",
        "Seated Shoulder Press (Dumbbell)": "0405",
        "Shoulder Press (Dumbbell)": "0405",
        "Shoulder Press (Plate Machine)": "0405",
        "Shoulder Press": "0405",
        "Shrugs": "0406",
        "Side Plank": "0664",
        "Sit-Up": "0456",
        "Skull Crushers": "0060",
        "Smith Machine Squat": "0770",
        "Squat (Barbell)": "0043",
        "Standing Calf Raise": "1372",
        "Standing Calf Raise (Machine)": "1372",
        "Standing Leg Curl (Machine)": "0586",
        "Standing Calf Raise (Smith)": "1372",
        "Sprint": "3666",
        "Step-Up": "0431",
        "Straight Arm Pulldown": "0237",
        "Straight Arm Lat Pulldown (Cable)": "0237",
        "Sumo Deadlift": "0117",
        "Thrusters": "0042",
        "Tricep Dip": "1755",
        "Tricep Extension": "0194",
        "Triceps Extension (Dumbbell)": "0194",
        "Dumbbell Triceps Extension": "0194",
        "Triceps Kickback (Dumbbell)": "0202",
        "DB Triceps Kickback": "0202",
        "Treadmill Run": "3666",
        "Vertical Leg Press": "0739",
        "Walking Lunge": "1460",
        "Wall Sit": "1372",
        "Wide Grip Pull-Up": "1429",
    ]
}

struct WorkoutSet: Identifiable, Codable {
    enum WeightInputMode: String, Codable, CaseIterable {
        case total
        case perSide
    }

    let id: UUID
    var setNumber: Int
    var previousWeight: Double?
    var previousReps: Int?
    var weight: Double?
    var reps: Int?
    var isCompleted: Bool
    var suggestedWeight: Double?
    var suggestedReps: Int?
    var weightInputMode: WeightInputMode
    
    init(
        id: UUID = UUID(),
        setNumber: Int,
        previousWeight: Double? = nil,
        previousReps: Int? = nil,
        weight: Double? = nil,
        reps: Int? = nil,
        isCompleted: Bool = false,
        suggestedWeight: Double? = nil,
        suggestedReps: Int? = nil,
        weightInputMode: WeightInputMode = .total
    ) {
        self.id = id
        self.setNumber = setNumber
        self.previousWeight = previousWeight
        self.previousReps = previousReps
        self.weight = weight
        self.reps = reps
        self.isCompleted = isCompleted
        self.suggestedWeight = suggestedWeight
        self.suggestedReps = suggestedReps
        self.weightInputMode = weightInputMode
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case setNumber
        case previousWeight
        case previousReps
        case weight
        case reps
        case isCompleted
        case suggestedWeight
        case suggestedReps
        case weightInputMode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        setNumber = try container.decode(Int.self, forKey: .setNumber)
        previousWeight = try container.decodeIfPresent(Double.self, forKey: .previousWeight)
        previousReps = try container.decodeIfPresent(Int.self, forKey: .previousReps)
        weight = try container.decodeIfPresent(Double.self, forKey: .weight)
        reps = try container.decodeIfPresent(Int.self, forKey: .reps)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        suggestedWeight = try container.decodeIfPresent(Double.self, forKey: .suggestedWeight)
        suggestedReps = try container.decodeIfPresent(Int.self, forKey: .suggestedReps)
        weightInputMode = try container.decodeIfPresent(WeightInputMode.self, forKey: .weightInputMode) ?? .total
    }
}

extension WorkoutSet {
    static let perSideCombinedMultiplier: Double = 2.0

    var effectiveWeightForVolume: Double? {
        guard let weight else { return nil }
        let multiplier = weightInputMode == .perSide ? Self.perSideCombinedMultiplier : 1.0
        return weight * multiplier
    }
}

struct WorkoutExercise: Identifiable, Codable {
    let id: UUID
    let exercise: Exercise
    var sets: [WorkoutSet]
    
    init(id: UUID = UUID(), exercise: Exercise, sets: [WorkoutSet]) {
        self.id = id
        self.exercise = exercise
        self.sets = sets
    }
}

struct Workout: Identifiable, Codable {
    let id: UUID
    var name: String
    var exercises: [WorkoutExercise]
    var assignedDays: [DayOfWeek]
    var createdAt: Date
    var lastCompletedAt: Date?
    /// When set, this workout appears only on this specific date (non-recurring).
    var oneTimeDate: Date?

    init(id: UUID = UUID(), name: String, exercises: [WorkoutExercise], assignedDays: [DayOfWeek], createdAt: Date = Date(), lastCompletedAt: Date? = nil, oneTimeDate: Date? = nil) {
        self.id = id
        self.name = name
        self.exercises = exercises
        self.assignedDays = assignedDays
        self.createdAt = createdAt
        self.lastCompletedAt = lastCompletedAt
        self.oneTimeDate = oneTimeDate
    }

    var isOneTime: Bool { oneTimeDate != nil }
}

struct WorkoutSession: Identifiable, Codable {
    let id: UUID
    let workoutId: UUID
    let workoutName: String
    var startTime: Date
    var endTime: Date?
    var exercises: [WorkoutExercise]
    var isActive: Bool
    
    init(id: UUID = UUID(), workoutId: UUID, workoutName: String, startTime: Date = Date(), endTime: Date? = nil, exercises: [WorkoutExercise], isActive: Bool = true) {
        self.id = id
        self.workoutId = workoutId
        self.workoutName = workoutName
        self.startTime = startTime
        self.endTime = endTime
        self.exercises = exercises
        self.isActive = isActive
    }
    
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
    
    var activeDuration: TimeInterval {
        if let endTime = endTime {
            return endTime.timeIntervalSince(startTime)
        }
        return Date().timeIntervalSince(startTime)
    }
}

// Completed workout session for history tracking
struct CompletedWorkoutSession: Identifiable, Codable {
    let id: UUID
    let workoutId: UUID
    let workoutName: String
    let startTime: Date
    let endTime: Date
    let exercises: [WorkoutExercise]
    
    init(id: UUID = UUID(), workoutId: UUID, workoutName: String, startTime: Date, endTime: Date, exercises: [WorkoutExercise]) {
        self.id = id
        self.workoutId = workoutId
        self.workoutName = workoutName
        self.startTime = startTime
        self.endTime = endTime
        self.exercises = exercises
    }
    
    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }
    
    var totalVolume: Double {
        return exercises.reduce(0) { total, exercise in
            total + exercise.sets.reduce(0) { setTotal, set in
                guard let effectiveWeight = set.effectiveWeightForVolume, let reps = set.reps else { return setTotal }
                return setTotal + (effectiveWeight * Double(reps))
            }
        }
    }
    
    var maxWeight: Double {
        return exercises.reduce(0) { max, exercise in
            let exerciseMax = exercise.sets.compactMap(\.effectiveWeightForVolume).max() ?? 0
            return Swift.max(max, exerciseMax)
        }
    }
}

enum DayOfWeek: String, Codable, CaseIterable, Identifiable {
    case sunday = "Sun"
    case monday = "Mon"
    case tuesday = "Tue"
    case wednesday = "Wed"
    case thursday = "Thu"
    case friday = "Fri"
    case saturday = "Sat"
    
    var id: String { rawValue }
    
    var fullName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
    
    static func from(date: Date) -> DayOfWeek {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        switch weekday {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .monday
        }
    }
}

// Predefined exercises database
extension Exercise {
    static let allExercises: [Exercise] = [
        // A
        Exercise(name: "Arnold Press", targetMuscles: "Shoulders, Triceps"),
        Exercise(name: "Assisted Dip (Machine)", targetMuscles: "Chest, Triceps"),
        Exercise(name: "Assisted Pull-Up", targetMuscles: "Back, Biceps"),
        Exercise(name: "Ab Wheel Rollout", targetMuscles: "Core, Abs"),
        
        // B
        Exercise(name: "Back Extension", targetMuscles: "Lower Back"),
        Exercise(name: "Back Squat", targetMuscles: "Quads, Glutes"),
        Exercise(name: "Barbell Curl", targetMuscles: "Biceps"),
        Exercise(name: "Barbell Row", targetMuscles: "Back, Lats"),
        Exercise(name: "Battle Ropes", targetMuscles: "Full Body, Cardio"),
        Exercise(name: "Bench Press", targetMuscles: "Chest, Triceps"),
        Exercise(name: "Bicep Curl", targetMuscles: "Biceps"),
        Exercise(name: "Bicep Curl (Dumbbell)", targetMuscles: "Biceps"),
        Exercise(name: "Box Jump", targetMuscles: "Legs, Plyometric"),
        Exercise(name: "Bulgarian Split Squat", targetMuscles: "Quads, Glutes"),
        
        // C
        Exercise(name: "Cable Crunch", targetMuscles: "Core, Abs"),
        Exercise(name: "Cable Fly", targetMuscles: "Chest"),
        Exercise(name: "Cable Lateral Raise", targetMuscles: "Shoulders"),
        Exercise(name: "Cable Row", targetMuscles: "Back"),
        Exercise(name: "Calf Raise", targetMuscles: "Calves"),
        Exercise(name: "Chest Fly", targetMuscles: "Chest"),
        Exercise(name: "Chin-Up", targetMuscles: "Back, Biceps"),
        Exercise(name: "Close Grip Bench Press", targetMuscles: "Triceps, Chest"),
        Exercise(name: "Concentration Curl", targetMuscles: "Biceps"),
        Exercise(name: "Crunch", targetMuscles: "Core, Abs"),
        
        // D
        Exercise(name: "Deadlift", targetMuscles: "Back, Hamstrings, Glutes"),
        Exercise(name: "Decline Bench Press", targetMuscles: "Lower Chest"),
        Exercise(name: "Decline Crunch", targetMuscles: "Core, Abs"),
        Exercise(name: "Diamond Push-Up", targetMuscles: "Triceps, Chest"),
        Exercise(name: "Dips", targetMuscles: "Triceps, Chest"),
        Exercise(name: "Donkey Kick", targetMuscles: "Glutes"),
        
        // E
        Exercise(name: "Elliptical", targetMuscles: "Cardio"),
        Exercise(name: "EZ Bar Curl", targetMuscles: "Biceps"),
        
        // F
        Exercise(name: "Face Pull", targetMuscles: "Rear Delts, Upper Back"),
        Exercise(name: "Farmer's Carry", targetMuscles: "Grip, Core"),
        Exercise(name: "Flutter Kicks", targetMuscles: "Core, Abs"),
        Exercise(name: "Front Raise", targetMuscles: "Shoulders"),
        Exercise(name: "Front Squat", targetMuscles: "Quads, Core"),
        
        // G
        Exercise(name: "Glute Bridge", targetMuscles: "Glutes, Hamstrings"),
        Exercise(name: "Glute Ham Raise", targetMuscles: "Hamstrings, Glutes"),
        Exercise(name: "Glute Kickback Machine", targetMuscles: "Glutes"),
        Exercise(name: "Goblet Squat", targetMuscles: "Quads, Glutes"),
        Exercise(name: "Good Morning", targetMuscles: "Hamstrings, Lower Back"),
        
        // H
        Exercise(name: "Hack Squat", targetMuscles: "Quads"),
        Exercise(name: "Hammer Curl", targetMuscles: "Biceps, Forearms"),
        Exercise(name: "Horizontal Leg Press", targetMuscles: "Quads, Glutes"),
        Exercise(name: "Hanging Leg Raise", targetMuscles: "Core, Abs"),
        Exercise(name: "Hip Abduction", targetMuscles: "Glutes, Hip"),
        Exercise(name: "Hip Adduction", targetMuscles: "Inner Thighs"),
        Exercise(name: "Hip Thrust", targetMuscles: "Glutes"),
        Exercise(name: "Hip Thrust (Machine)", targetMuscles: "Glutes"),
        
        // I
        Exercise(name: "Incline Bench Press", targetMuscles: "Upper Chest"),
        Exercise(name: "Incline Bench Press (Dumbbell)", targetMuscles: "Upper Chest"),
        Exercise(name: "Inverted Row", targetMuscles: "Back, Biceps"),
        
        // J
        Exercise(name: "Jump Squat", targetMuscles: "Legs, Plyometric"),
        Exercise(name: "Jump Rope", targetMuscles: "Cardio, Calves"),
        
        // K
        Exercise(name: "Kettlebell Swing", targetMuscles: "Glutes, Hamstrings"),
        Exercise(name: "Kettlebell Clean", targetMuscles: "Full Body"),
        Exercise(name: "Kettlebell Snatch", targetMuscles: "Full Body"),
        
        // L
        Exercise(name: "Lat Pulldown", targetMuscles: "Back, Lats"),
        Exercise(name: "Lateral Raise", targetMuscles: "Shoulders"),
        Exercise(name: "Leg Curl", targetMuscles: "Hamstrings"),
        Exercise(name: "Seated Leg Curl", targetMuscles: "Hamstrings"),
        Exercise(name: "Leg Extension", targetMuscles: "Quads"),
        Exercise(name: "Leg Press", targetMuscles: "Quads, Glutes"),
        Exercise(name: "Leg Raise", targetMuscles: "Core, Abs"),
        Exercise(name: "Lunge", targetMuscles: "Quads, Glutes"),
        Exercise(name: "Lunge (Dumbbell)", targetMuscles: "Quads, Glutes"),
        Exercise(name: "Lying Leg Curl", targetMuscles: "Hamstrings"),
        
        // M
        Exercise(name: "Machine Bicep Curl", targetMuscles: "Biceps"),
        Exercise(name: "Machine Chest Press", targetMuscles: "Chest, Triceps"),
        Exercise(name: "Machine Fly (Chest)", targetMuscles: "Chest"),
        Exercise(name: "Machine Incline Chest Press", targetMuscles: "Upper Chest"),
        Exercise(name: "Machine Lateral Raise", targetMuscles: "Shoulders"),
        Exercise(name: "Machine Preacher Curl", targetMuscles: "Biceps"),
        Exercise(name: "Machine Shrug", targetMuscles: "Traps"),
        Exercise(name: "Machine Triceps Extension", targetMuscles: "Triceps"),
        Exercise(name: "Mountain Climbers", targetMuscles: "Core, Cardio"),
        Exercise(name: "Military Press", targetMuscles: "Shoulders, Triceps"),
        
        // N
        Exercise(name: "Neck Flexion", targetMuscles: "Neck"),
        Exercise(name: "Neck Extension", targetMuscles: "Neck"),
        Exercise(name: "Neck Lateral Flexion", targetMuscles: "Neck"),
        Exercise(name: "Neck Rotation", targetMuscles: "Neck"),
        
        // O
        Exercise(name: "Overhead Press", targetMuscles: "Shoulders, Triceps"),
        
        // P
        Exercise(name: "Pec Deck Fly", targetMuscles: "Chest"),
        Exercise(name: "Pendlay Row", targetMuscles: "Back"),
        Exercise(name: "Plank", targetMuscles: "Core, Abs"),
        Exercise(name: "Preacher Curl", targetMuscles: "Biceps"),
        Exercise(name: "Pull-Up", targetMuscles: "Back, Biceps"),
        Exercise(name: "Push Press", targetMuscles: "Shoulders, Legs"),
        Exercise(name: "Push-Up", targetMuscles: "Chest, Triceps"),
        
        // R
        Exercise(name: "Rear Delt Fly", targetMuscles: "Rear Delts"),
        Exercise(name: "Romanian Deadlift", targetMuscles: "Hamstrings, Glutes"),
        Exercise(name: "Row (Machine)", targetMuscles: "Back"),
        Exercise(name: "Russian Twist", targetMuscles: "Core, Obliques"),
        
        // S
        Exercise(name: "Seated Calf Raise", targetMuscles: "Calves"),
        Exercise(name: "Seated Hip Abduction (Machine)", targetMuscles: "Glutes, Hip"),
        Exercise(name: "Seated Hip Adduction (Machine)", targetMuscles: "Inner Thighs"),
        Exercise(name: "Seated Shoulder Press (Dumbbell)", targetMuscles: "Shoulders, Triceps"),
        Exercise(name: "Seated Shoulder Press (Machine)", targetMuscles: "Shoulders, Triceps"),
        Exercise(name: "Seated Row", targetMuscles: "Back"),
        Exercise(name: "Shoulder Press (Plate Machine)", targetMuscles: "Shoulders, Triceps"),
        Exercise(name: "Shoulder Press", targetMuscles: "Shoulders, Triceps"),
        Exercise(name: "Shrugs", targetMuscles: "Traps"),
        Exercise(name: "Side Plank", targetMuscles: "Core, Obliques"),
        Exercise(name: "Sit-Up", targetMuscles: "Core, Abs"),
        Exercise(name: "Skull Crushers", targetMuscles: "Triceps"),
        Exercise(name: "Smith Machine Squat", targetMuscles: "Quads, Glutes"),
        Exercise(name: "Standing Calf Raise", targetMuscles: "Calves"),
        Exercise(name: "Standing Calf Raise (Smith)", targetMuscles: "Calves"),
        Exercise(name: "Standing Leg Curl (Machine)", targetMuscles: "Hamstrings"),
        Exercise(name: "Sprint", targetMuscles: "Cardio, Legs"),
        Exercise(name: "Step-Up", targetMuscles: "Quads, Glutes"),
        Exercise(name: "Straight Arm Pulldown", targetMuscles: "Lats"),
        Exercise(name: "Sumo Deadlift", targetMuscles: "Hamstrings, Glutes"),
        
        // T
        Exercise(name: "Thrusters", targetMuscles: "Full Body"),
        Exercise(name: "Triceps Kickback (Dumbbell)", targetMuscles: "Triceps"),
        Exercise(name: "Tricep Dip", targetMuscles: "Triceps"),
        Exercise(name: "Tricep Extension", targetMuscles: "Triceps"),
        Exercise(name: "Triceps Extension (Dumbbell)", targetMuscles: "Triceps"),
        Exercise(name: "Treadmill Run", targetMuscles: "Cardio"),
        
        // V
        Exercise(name: "Vertical Leg Press", targetMuscles: "Quads, Glutes"),
        Exercise(name: "V Bar Push Downs", targetMuscles: "Triceps"),
        
        // W
        Exercise(name: "Walking Lunge", targetMuscles: "Quads, Glutes"),
        Exercise(name: "Wall Sit", targetMuscles: "Quads"),
        Exercise(name: "Wide Grip Pull-Up", targetMuscles: "Back, Lats"),
        Exercise(name: "Wrist Curl", targetMuscles: "Forearms"),
        Exercise(name: "Reverse Wrist Curl", targetMuscles: "Forearms"),
        Exercise(name: "Wrist Roller", targetMuscles: "Forearms, Grip"),
    ].sorted { $0.name < $1.name }
    
    static func search(_ query: String) -> [Exercise] {
        guard !query.isEmpty else { return allExercises }
        let normalizedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        return allExercises.filter { exercise in
            let normalizedName = exercise.name.lowercased()

            if normalizedName.contains(normalizedQuery) ||
                exercise.targetMuscles.lowercased().contains(normalizedQuery) {
                return true
            }

            if let aliases = searchAliases[normalizedName] {
                return aliases.contains { $0.contains(normalizedQuery) || normalizedQuery.contains($0) }
            }

            return false
        }
    }
}
