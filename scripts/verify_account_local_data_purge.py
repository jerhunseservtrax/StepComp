#!/usr/bin/env python3
"""Regression checks for clearing account-scoped local data on sign-out.

The Linux automation environment cannot run the iOS XCTest target, so this
script verifies the critical Swift wiring that prevents cross-account data
leaks on shared devices.
"""

from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]


def read(relative_path: str) -> str:
    path = ROOT / relative_path
    try:
        return path.read_text()
    except FileNotFoundError:
        print(f"Missing expected file: {relative_path}")
        sys.exit(1)


def require(condition: bool, message: str) -> None:
    if not condition:
        print(f"FAIL: {message}")
        sys.exit(1)


def main() -> None:
    auth = read("StepComp/Services/AuthService.swift")
    local_store = read("StepComp/Services/LocalUserDataStore.swift")
    metrics_service = read("StepComp/Services/MetricsService.swift")
    workout_vm = read("StepComp/ViewModels/WorkoutViewModel.swift")
    weight_vm = read("StepComp/ViewModels/WeightViewModel.swift")
    food_log_vm = read("StepComp/ViewModels/FoodLogViewModel.swift")
    metrics_vm = read("StepComp/ViewModels/MetricsViewModel.swift")

    sign_out_body = re.search(
        r"private func applySignedOutState\([\s\S]*?\n    \}",
        auth,
    )
    require(sign_out_body is not None, "applySignedOutState should exist")
    require(
        "LocalUserDataStore.clearAll()" in sign_out_body.group(0),
        "sign-out must clear account-scoped local data",
    )
    require(
        "authInvalidationVersion += 1" in sign_out_body.group(0),
        "sign-out must invalidate in-flight profile loads",
    )
    require(
        "profileLoadTask?.cancel()" in sign_out_body.group(0),
        "sign-out must cancel the active profile load task",
    )
    require(
        "authInvalidationVersion:" in auth and "isCurrentAuthLoad" in auth,
        "profile loading must be guarded by the current auth generation",
    )

    expected_user_defaults_keys = [
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
    ]
    for key in expected_user_defaults_keys:
        require(
            f'"{key}"' in local_store,
            f"LocalUserDataStore should remove UserDefaults key {key}",
        )

    expected_clear_calls = [
        "WorkoutViewModel.shared.clearLocalUserData()",
        "WeightViewModel.shared.clearLocalUserData()",
        "FoodLogViewModel.shared.clearLocalUserData()",
        "TransformationPhotoViewModel.shared.clearLocalUserData()",
        "ComprehensiveMetricsStore.shared.clearLocalUserData()",
        "ChallengeService.shared.clearLocalUserData()",
        "MetricsService.shared.clearLocalUserData()",
        "OfflineCacheService.clearAll()",
    ]
    for call in expected_clear_calls:
        require(call in local_store, f"LocalUserDataStore should call {call}")

    expected_sync_signatures = [
        "func syncWorkoutSession(_ session: CompletedWorkoutSession, expectedUserId: String)",
        "func syncWeightEntry(_ entry: WeightEntry, expectedUserId: String)",
        "func syncBodyMetric(bodyFatPercent: Double?, waistCm: Double?, date: Date = Date(), expectedUserId: String)",
        "func syncNutritionLog(_ log: NutritionLog, expectedUserId: String)",
    ]
    for signature in expected_sync_signatures:
        require(signature in metrics_service, f"MetricsService should bind sync owner: {signature}")

    require(
        "validateAuthenticatedUser(expectedUserId: expectedUserId" in metrics_service,
        "MetricsService sync methods must validate the active user before RPC writes",
    )
    for source_name, source in [
        ("WorkoutViewModel", workout_vm),
        ("WeightViewModel", weight_vm),
        ("FoodLogViewModel", food_log_vm),
        ("MetricsViewModel", metrics_vm),
    ]:
        require(
            "expectedUserId:" in source,
            f"{source_name} detached sync calls must pass the originating user id",
        )

    print("PASS: account local data purge wiring is present")


if __name__ == "__main__":
    main()
