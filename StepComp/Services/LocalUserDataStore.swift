//
//  LocalUserDataStore.swift
//  FitComp
//

import Foundation

@MainActor
enum LocalUserDataStore {
    static let privateUserDefaultsKeys: [String] = [
        WorkoutViewModel.workoutsStorageKey,
        WorkoutViewModel.completedSessionsStorageKey,
        WorkoutViewModel.activeWorkoutDraftStorageKey,
        WeightViewModel.entriesStorageKey,
        TransformationPhotoViewModel.photosStorageKey,
        FoodLogViewModel.entriesStorageKey,
        FoodLogViewModel.cachedFoodsStorageKey,
        ComprehensiveMetricsStore.bodyMetricsStorageKey,
        ComprehensiveMetricsStore.nutritionLogsStorageKey,
        MetricsService.syncedSessionsStorageKey,
        MetricsService.syncedWeightEntriesStorageKey,
        ChallengeService.challengesStorageKey,
        ChallengeService.leaderboardStorageKey,
        "userHeight",
        "userWeight",
        "user_weight",
        "dailyStepGoal",
        "daily_calorie_goal",
        "daily_protein_goal_g",
        "calorie_workout_days_per_week",
        "calorie_goal_is_manual",
        "user_age",
        "user_biological_sex",
        "user_activity_level",
        "user_weight_goal",
        "user_goal_aggressiveness",
        "selectedAvatarURL",
        "selectedAvatarPhotoData",
        "selectedAvatarEmoji"
    ]

    static func clearPrivateLocalDataForSignedOutUser() {
        WorkoutViewModel.shared.clearPrivateLocalDataForSignedOutUser()
        WeightViewModel.shared.clearPrivateLocalDataForSignedOutUser()
        TransformationPhotoViewModel.shared.clearPrivateLocalDataForSignedOutUser()
        FoodLogViewModel.shared.clearPrivateLocalDataForSignedOutUser()
        ComprehensiveMetricsStore.shared.clearPrivateLocalDataForSignedOutUser()
        MetricsService.shared.clearPrivateLocalDataForSignedOutUser()
        ChallengeService.shared.clearPrivateLocalDataForSignedOutUser()
        OfflineCacheService.clearAll()

        // Defense in depth: ensure any private key added to the registry is removed
        // even if a service-specific reset path changes.
        for key in privateUserDefaultsKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
