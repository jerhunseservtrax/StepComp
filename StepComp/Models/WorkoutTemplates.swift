//
//  WorkoutTemplates.swift
//  FitComp
//

import Foundation

// MARK: - Muscle Group

enum MuscleGroup: String, CaseIterable, Identifiable, Codable {
    case chest     = "Chest"
    case back      = "Back"
    case shoulders = "Shoulders"
    case biceps    = "Biceps"
    case triceps   = "Triceps"
    case quads     = "Quads"
    case hamstrings = "Hamstrings"
    case glutes    = "Glutes"
    case calves    = "Calves"
    case core      = "Core"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .chest:      return "figure.strengthtraining.traditional"
        case .back:       return "figure.rowing"
        case .shoulders:  return "figure.boxing"
        case .biceps:     return "figure.curling"
        case .triceps:    return "figure.cooldown"
        case .quads:      return "figure.run"
        case .hamstrings: return "figure.walk"
        case .glutes:     return "figure.hiking"
        case .calves:     return "figure.step.training"
        case .core:       return "figure.core.training"
        }
    }

    /// Keywords used to match against `Exercise.targetMuscles`.
    var matchKeywords: [String] {
        switch self {
        case .chest:      return ["chest", "pectoral"]
        case .back:       return ["back", "lats", "lat"]
        case .shoulders:  return ["shoulder", "delt"]
        case .biceps:     return ["bicep", "brachialis", "brachioradialis"]
        case .triceps:    return ["tricep"]
        case .quads:      return ["quad", "leg press", "leg extension"]
        case .hamstrings: return ["hamstring"]
        case .glutes:     return ["glute"]
        case .calves:     return ["calve", "calf", "soleus", "gastrocnemius"]
        case .core:       return ["core", "abs", "oblique"]
        }
    }

    static func exercisesFor(_ groups: Set<MuscleGroup>) -> [Exercise] {
        let lower = groups.flatMap(\.matchKeywords).map { $0.lowercased() }
        return Exercise.allExercises.filter { ex in
            let target = ex.targetMuscles.lowercased()
            return lower.contains(where: { target.contains($0) })
        }
    }
}

// MARK: - Split Template

struct WorkoutSplitTemplate: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let icon: String
    let days: [SplitDay]
    let daysPerWeek: Int
    let bestFor: String
    let pros: [String]
    let cons: [String]
    let scheduleExample: String
}

struct SplitDay: Identifiable {
    let id = UUID()
    let name: String
    let muscleGroups: [MuscleGroup]
    /// Pinned exercises that should always appear for this day (by name from Exercise.allExercises).
    let pinnedExercises: [String]

    init(name: String, muscleGroups: [MuscleGroup], pinnedExercises: [String] = []) {
        self.name = name
        self.muscleGroups = muscleGroups
        self.pinnedExercises = pinnedExercises
    }
}

extension WorkoutSplitTemplate {
    static let allTemplates: [WorkoutSplitTemplate] = [
        fullBody,
        pushPullLegs,
        upperLower,
        broSplit,
        hybridSplit,
        arnoldSplit,
        athleticSplit,
    ]

    // MARK: - 1. Full Body (best for beginners)

    static let fullBody = WorkoutSplitTemplate(
        name: "Full Body",
        subtitle: "Hit everything 3x/week, great for beginners & fat loss",
        icon: "figure.strengthtraining.traditional",
        days: [
            SplitDay(
                name: "Full Body A",
                muscleGroups: MuscleGroup.allCases,
                pinnedExercises: ["Back Squat", "Bench Press", "Barbell Row", "Overhead Press", "Bicep Curl", "Tricep Extension", "Plank"]
            ),
            SplitDay(
                name: "Full Body B",
                muscleGroups: MuscleGroup.allCases,
                pinnedExercises: ["Deadlift", "Incline Dumbbell Press", "Lat Pulldown", "Lateral Raise", "Hammer Curl", "Skull Crushers", "Hanging Leg Raise"]
            ),
            SplitDay(
                name: "Full Body C",
                muscleGroups: MuscleGroup.allCases,
                pinnedExercises: ["Front Squat", "Chest Dip", "Cable Row", "Arnold Press", "EZ Bar Curl", "Dips", "Russian Twist"]
            ),
        ],
        daysPerWeek: 3,
        bestFor: "Beginners, fat loss + muscle retention, 3-day schedules",
        pros: [
            "High frequency (each muscle 3x/week)",
            "Great for strength gains",
            "Time efficient schedule",
            "Hard to miss muscle groups",
        ],
        cons: [
            "Longer individual workouts",
            "Fatigue management needed",
        ],
        scheduleExample: "Mon / Wed / Fri"
    )

    // MARK: - 2. Push Pull Legs

    static let pushPullLegs = WorkoutSplitTemplate(
        name: "Push Pull Legs",
        subtitle: "Separate by movement function, 3 or 6 days",
        icon: "arrow.left.arrow.right",
        days: [
            SplitDay(
                name: "Push",
                muscleGroups: [.chest, .shoulders, .triceps],
                pinnedExercises: ["Bench Press", "Incline Dumbbell Press", "Overhead Press", "Lateral Raise", "Tricep Extension", "Cable Fly"]
            ),
            SplitDay(
                name: "Pull",
                muscleGroups: [.back, .biceps],
                pinnedExercises: ["Deadlift", "Barbell Row", "Lat Pulldown", "Face Pull", "Barbell Curl", "Hammer Curl"]
            ),
            SplitDay(
                name: "Legs",
                muscleGroups: [.quads, .hamstrings, .glutes, .calves, .core],
                pinnedExercises: ["Back Squat", "Romanian Deadlift", "Leg Press", "Leg Curl", "Calf Raise", "Hanging Leg Raise"]
            ),
        ],
        daysPerWeek: 6,
        bestFor: "Hypertrophy-focused lifters, 5-6 day schedules",
        pros: [
            "Logical push/pull grouping",
            "Great recovery between groups",
            "Popular for hypertrophy",
        ],
        cons: [
            "3-day version = low frequency per muscle",
            "6-day version = very time heavy",
        ],
        scheduleExample: "PPL / Rest / PPL (6-day) or PPL / Rest (3-day)"
    )

    // MARK: - 3. Upper / Lower

    static let upperLower = WorkoutSplitTemplate(
        name: "Upper / Lower",
        subtitle: "Best balance split, 2x frequency per muscle",
        icon: "rectangle.split.2x1.fill",
        days: [
            SplitDay(
                name: "Upper A (Strength)",
                muscleGroups: [.chest, .back, .shoulders, .biceps, .triceps],
                pinnedExercises: ["Bench Press", "Barbell Row", "Overhead Press", "Barbell Curl", "Skull Crushers"]
            ),
            SplitDay(
                name: "Lower A (Strength)",
                muscleGroups: [.quads, .hamstrings, .glutes, .calves, .core],
                pinnedExercises: ["Back Squat", "Romanian Deadlift", "Leg Press", "Calf Raise", "Plank"]
            ),
            SplitDay(
                name: "Upper B (Hypertrophy)",
                muscleGroups: [.chest, .back, .shoulders, .biceps, .triceps],
                pinnedExercises: ["Incline Dumbbell Press", "Cable Row", "Lateral Raise", "Hammer Curl", "Tricep Extension"]
            ),
            SplitDay(
                name: "Lower B (Hypertrophy)",
                muscleGroups: [.quads, .hamstrings, .glutes, .calves, .core],
                pinnedExercises: ["Front Squat", "Hip Thrust", "Leg Curl", "Seated Calf Raise", "Hanging Leg Raise"]
            ),
        ],
        daysPerWeek: 4,
        bestFor: "Intermediates, progressive overload, long-term growth",
        pros: [
            "Great frequency (2x/week per muscle)",
            "Easier recovery than full body",
            "Perfect for progressive overload",
            "Efficient use of training days",
        ],
        cons: [
            "Slightly longer sessions than PPL",
        ],
        scheduleExample: "Mon Upper / Tue Lower / Thu Upper / Fri Lower"
    )

    // MARK: - 4. Bro Split

    static let broSplit = WorkoutSplitTemplate(
        name: "Bro Split",
        subtitle: "Classic bodybuilding, one muscle group per day",
        icon: "flame.fill",
        days: [
            SplitDay(
                name: "Chest",
                muscleGroups: [.chest],
                pinnedExercises: ["Bench Press", "Incline Dumbbell Press", "Cable Fly", "Chest Dip", "Decline Bench Press"]
            ),
            SplitDay(
                name: "Back",
                muscleGroups: [.back],
                pinnedExercises: ["Deadlift", "Barbell Row", "Lat Pulldown", "Seated Row", "Straight Arm Pulldown"]
            ),
            SplitDay(
                name: "Shoulders",
                muscleGroups: [.shoulders],
                pinnedExercises: ["Overhead Press", "Lateral Raise", "Face Pull", "Arnold Press", "Front Raise"]
            ),
            SplitDay(
                name: "Arms",
                muscleGroups: [.biceps, .triceps],
                pinnedExercises: ["Barbell Curl", "Hammer Curl", "Preacher Curl", "Skull Crushers", "Tricep Extension", "Dips"]
            ),
            SplitDay(
                name: "Legs",
                muscleGroups: [.quads, .hamstrings, .glutes, .calves],
                pinnedExercises: ["Back Squat", "Romanian Deadlift", "Leg Press", "Leg Curl", "Calf Raise", "Hip Thrust"]
            ),
        ],
        daysPerWeek: 5,
        bestFor: "Fun, high volume per muscle, bodybuilding-style",
        pros: [
            "Fun and simple to follow",
            "High volume per muscle group",
            "Easy to plan mentally",
        ],
        cons: [
            "Low frequency (once per week per muscle)",
            "Not optimal for natural lifters",
            "Easier to stall on progress",
        ],
        scheduleExample: "Mon Chest / Tue Back / Wed Shoulders / Thu Arms / Fri Legs"
    )

    // MARK: - 5. Hybrid Split (modern approach)

    static let hybridSplit = WorkoutSplitTemplate(
        name: "Hybrid Split",
        subtitle: "Strength + hypertrophy, modern & highly effective",
        icon: "rectangle.split.3x3.fill",
        days: [
            SplitDay(
                name: "Upper Strength",
                muscleGroups: [.chest, .back, .shoulders, .biceps, .triceps],
                pinnedExercises: ["Bench Press", "Barbell Row", "Overhead Press", "Barbell Curl", "Close Grip Bench Press"]
            ),
            SplitDay(
                name: "Lower Strength",
                muscleGroups: [.quads, .hamstrings, .glutes, .calves, .core],
                pinnedExercises: ["Back Squat", "Deadlift", "Leg Press", "Calf Raise", "Plank"]
            ),
            SplitDay(
                name: "Push Hypertrophy",
                muscleGroups: [.chest, .shoulders, .triceps],
                pinnedExercises: ["Incline Dumbbell Press", "Cable Fly", "Lateral Raise", "Arnold Press", "Tricep Extension"]
            ),
            SplitDay(
                name: "Pull Hypertrophy",
                muscleGroups: [.back, .biceps],
                pinnedExercises: ["Cable Row", "Lat Pulldown", "Face Pull", "Hammer Curl", "Concentration Curl"]
            ),
        ],
        daysPerWeek: 4,
        bestFor: "Advanced lifters wanting both strength and size",
        pros: [
            "Highly customizable",
            "Trains both strength and hypertrophy",
            "Used by many serious lifters",
        ],
        cons: [
            "Requires more planning",
            "Not beginner-friendly",
        ],
        scheduleExample: "Mon Upper Str / Tue Lower Str / Thu Push Hyp / Fri Pull Hyp"
    )

    // MARK: - 6. Arnold Split

    static let arnoldSplit = WorkoutSplitTemplate(
        name: "Arnold Split",
        subtitle: "Chest + Back, Shoulders + Arms, Legs (6-day)",
        icon: "star.fill",
        days: [
            SplitDay(
                name: "Chest & Back",
                muscleGroups: [.chest, .back],
                pinnedExercises: ["Bench Press", "Incline Dumbbell Press", "Barbell Row", "Chin-Up", "Cable Fly", "Lat Pulldown"]
            ),
            SplitDay(
                name: "Shoulders & Arms",
                muscleGroups: [.shoulders, .biceps, .triceps],
                pinnedExercises: ["Overhead Press", "Lateral Raise", "Barbell Curl", "Skull Crushers", "Hammer Curl", "Dips"]
            ),
            SplitDay(
                name: "Legs & Core",
                muscleGroups: [.quads, .hamstrings, .glutes, .calves, .core],
                pinnedExercises: ["Back Squat", "Romanian Deadlift", "Leg Press", "Leg Curl", "Calf Raise", "Hanging Leg Raise"]
            ),
        ],
        daysPerWeek: 6,
        bestFor: "High-volume antagonist supersets, advanced lifters",
        pros: [
            "Antagonist pairing (chest + back) is very effective",
            "High frequency (2x/week)",
            "Great pump and time efficiency within sessions",
        ],
        cons: [
            "6 days per week is demanding",
            "High overall volume",
        ],
        scheduleExample: "C+B / S+A / Legs / C+B / S+A / Legs / Rest"
    )

    // MARK: - 7. Athletic / Functional Split

    static let athleticSplit = WorkoutSplitTemplate(
        name: "Athletic / Functional",
        subtitle: "Movement-based, for athletes & conditioning",
        icon: "bolt.fill",
        days: [
            SplitDay(
                name: "Lower Power",
                muscleGroups: [.quads, .hamstrings, .glutes],
                pinnedExercises: ["Back Squat", "Deadlift", "Box Jump", "Kettlebell Swing"]
            ),
            SplitDay(
                name: "Upper Power",
                muscleGroups: [.chest, .back, .shoulders],
                pinnedExercises: ["Bench Press", "Barbell Row", "Push Press", "Pull-Up"]
            ),
            SplitDay(
                name: "Conditioning",
                muscleGroups: [.core, .glutes, .quads],
                pinnedExercises: ["Kettlebell Swing", "Battle Ropes", "Mountain Climbers", "Jump Rope", "Farmer's Carry", "Thrusters"]
            ),
            SplitDay(
                name: "Hypertrophy",
                muscleGroups: [.chest, .back, .shoulders, .biceps, .triceps, .quads, .hamstrings],
                pinnedExercises: ["Incline Dumbbell Press", "Cable Row", "Lateral Raise", "Hammer Curl", "Leg Press", "Leg Curl"]
            ),
        ],
        daysPerWeek: 4,
        bestFor: "Athletes, sport performance, general fitness",
        pros: [
            "Builds functional power + endurance",
            "Includes conditioning",
            "Well-rounded athleticism",
        ],
        cons: [
            "Less hypertrophy focus",
            "Requires space/equipment variety",
        ],
        scheduleExample: "Mon Lower / Tue Upper / Thu Conditioning / Fri Hypertrophy"
    )
}

// MARK: - Workout Generator

enum WorkoutGenerator {
    /// Builds exercises for a `SplitDay`, preferring its pinned exercises
    /// and filling remaining slots from the exercise database.
    static func generate(from splitDay: SplitDay) -> [WorkoutExercise] {
        var result: [WorkoutExercise] = []
        var usedNames: Set<String> = []

        let allExercisesByName = Dictionary(
            Exercise.allExercises.map { ($0.name, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        for name in splitDay.pinnedExercises {
            guard let exercise = allExercisesByName[name] else { continue }
            usedNames.insert(exercise.name)
            let sets = (1...3).map { WorkoutSet(setNumber: $0) }
            result.append(WorkoutExercise(exercise: exercise, sets: sets))
        }

        if result.isEmpty {
            return generate(for: Set(splitDay.muscleGroups), exercisesPerGroup: 2)
        }

        return result
    }

    /// Builds a list of `WorkoutExercise` for the given muscle groups,
    /// picking a sensible number of exercises per group.
    static func generate(for muscles: Set<MuscleGroup>, exercisesPerGroup: Int = 2) -> [WorkoutExercise] {
        var result: [WorkoutExercise] = []
        var usedNames: Set<String> = []

        for group in MuscleGroup.allCases where muscles.contains(group) {
            let candidates = MuscleGroup.exercisesFor([group])
                .filter { !usedNames.contains($0.name) }
                .shuffled()
                .prefix(exercisesPerGroup)

            for exercise in candidates {
                usedNames.insert(exercise.name)
                let sets = (1...3).map { WorkoutSet(setNumber: $0) }
                result.append(WorkoutExercise(exercise: exercise, sets: sets))
            }
        }
        return result
    }

    /// Builds a full `Workout` from a `SplitDay`.
    static func workout(from splitDay: SplitDay) -> Workout {
        let exercises = generate(from: splitDay)
        return Workout(
            name: splitDay.name,
            exercises: exercises,
            assignedDays: []
        )
    }
}
