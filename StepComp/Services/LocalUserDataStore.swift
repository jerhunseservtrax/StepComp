//
//  LocalUserDataStore.swift
//  FitComp
//
//  Clears account-scoped local state when an authenticated user signs out.
//

import Foundation

@MainActor
enum LocalUserDataStore {
    private static let accountScopedDefaultsKeys = [
        "currentUser",
        "hasCompletedOnboarding",
        "selectedAvatarURL",
        "selectedAvatarPhotoData",
        "selectedAvatarEmoji",
        "active_workout_draft",
        "saved_workouts",
        "completed_workout_sessions",
        "weight_entries",
        "food_log_entries",
        "food_log_cached_foods",
        "transformation_photos",
        "comprehensive_body_metrics",
        "comprehensive_nutrition_logs",
        "challenges",
        "leaderboard",
        "metrics_synced_session_ids",
        "metrics_synced_weight_entry_ids",
        "userHeight",
        "userWeight",
        "user_weight",
        "dailyStepGoal",
        "daily_calorie_goal",
        "daily_protein_goal_g",
        "calorie_goal_is_manual",
        "user_age",
        "user_biological_sex",
        "user_activity_level",
        "user_weight_goal",
        "user_goal_aggressiveness",
        "calorie_workout_days_per_week"
    ]

    static func clearAll() {
        WorkoutViewModel.shared.clearLocalUserData()
        WeightViewModel.shared.clearLocalUserData()
        FoodLogViewModel.shared.clearLocalUserData()
        TransformationPhotoViewModel.shared.clearLocalUserData()
        ComprehensiveMetricsStore.shared.clearLocalUserData()
        ChallengeService.shared.clearLocalUserData()
        MetricsService.shared.clearLocalUserData()
        OfflineCacheService.clearAll()

        accountScopedDefaultsKeys.forEach {
            UserDefaults.standard.removeObject(forKey: $0)
        }
        removeDocumentDirectory(named: "MealPhotos")
        removeDocumentDirectory(named: "transformation_photos")
    }

    private static func removeDocumentDirectory(named name: String) {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(name, isDirectory: true)
        try? FileManager.default.removeItem(at: directory)
    }
}
