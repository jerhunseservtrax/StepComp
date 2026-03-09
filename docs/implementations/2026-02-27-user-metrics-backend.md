# User Metrics Backend - Implementation Summary

**Date:** 2026-02-27  
**Status:** Complete - Migration Applied ✅

## What Was Built

A complete backend infrastructure to capture and store historical user metrics (workout sessions, body weight, steps) in Supabase, enabling future Metrics page development.

## Architecture

### Database Schema (3 New Tables)

#### 1. `workout_sessions` 
One row per completed workout with precomputed aggregates:
- `user_id` (FK to auth.users) - ensures per-user isolation via RLS
- `workout_id`, `workout_name` - links to workout templates
- `started_at`, `ended_at`, `duration_seconds` (generated)
- `total_volume_kg`, `max_weight_kg` - precomputed for fast queries
- UNIQUE constraint on `(user_id, started_at)` - prevents duplicate syncs

#### 2. `workout_session_sets`
Normalized set-level exercise data:
- `session_id` (FK to workout_sessions, CASCADE DELETE)
- `exercise_name`, `target_muscles` - denormalized for querying
- `set_number`, `weight_kg`, `reps`, `is_completed`
- Indexed on `(exercise_name, created_at)` for per-exercise trends

#### 3. `weight_log`
Daily body weight tracking:
- `user_id` (FK to auth.users)
- `recorded_on` (DATE), `weight_kg` (NUMERIC 5,2)
- `source` (manual/healthKit)
- UNIQUE constraint on `(user_id, recorded_on)` - one entry per day

### RPC Functions (6 Total)

**Sync RPCs (write):**
1. `sync_workout_session(p_session JSONB)` - Idempotent session+sets upsert
2. `sync_weight_entry(p_date, p_weight_kg, p_source)` - Daily weight upsert

**Query RPCs (read):**
3. `get_user_metrics_summary(p_days)` - Returns JSONB with aggregates
4. `get_exercise_history(p_exercise_name, p_days)` - Per-exercise time series
5. `get_weight_history(p_days)` - Weight trend data
6. `get_workout_history(p_days)` - Workout activity feed

All RPCs use `SECURITY DEFINER` with `auth.uid()` validation.

## Swift Implementation

### Models (`StepComp/Models/UserMetrics.swift`)
- `SupabaseWorkoutSession`, `SupabaseWorkoutSet` - DB mappings
- `SupabaseWeightEntry` - DB mapping
- `MetricsSummary`, `ExerciseHistoryPoint`, `WeightHistoryPoint`, `WorkoutHistoryPoint` - RPC response types

All structs use snake_case `CodingKeys` to match Supabase conventions.

### Service (`StepComp/Services/MetricsService.swift`)
Singleton service (`@MainActor`) with:
- **Sync methods:** `syncWorkoutSession()`, `syncWeightEntry()`, `syncAllLocalData()`
- **Fetch methods:** `fetchMetricsSummary()`, `fetchExerciseHistory()`, etc.
- **Sync tracking:** Uses UserDefaults to track synced IDs, preventing duplicate syncs

### Integration Points

1. **`WorkoutViewModel.finishWorkout()`** - Fires background sync after saving locally
2. **`WeightViewModel.addEntry()`** - Fires background sync after saving locally  
3. **`StepCompApp.init()`** - Calls `syncAllLocalData()` on launch for offline catch-up

## Data Flow

```
User completes workout
  ↓
Save to UserDefaults (immediate, offline-first)
  ↓
Background Task → MetricsService.syncWorkoutSession()
  ↓
Supabase RPC sync_workout_session(JSONB)
  ↓
Inserts into workout_sessions + workout_session_sets
  ↓
ON CONFLICT → idempotent (safe to retry)
```

## Security

- **RLS policies:** Every table restricts `user_id = auth.uid()` 
- **No client-side user_id:** RPCs extract `auth.uid()` from JWT token
- **Idempotent syncs:** UNIQUE constraints + ON CONFLICT prevent duplicates
- **Validation:** RPCs check weight ranges, required fields, auth status

## Usage (For Future Metrics Page)

```swift
// Fetch summary data
if let summary = await MetricsService.shared.fetchMetricsSummary(days: 30) {
    print("Total workouts: \(summary.totalWorkouts)")
    print("Total volume: \(summary.totalVolume) kg")
    print("Weight change: \(summary.weightChangeKg ?? 0) kg")
    print("Current streak: \(summary.workoutStreak) days")
}

// Fetch exercise trend
let benchHistory = await MetricsService.shared.fetchExerciseHistory(
    exerciseName: "Bench Press", 
    days: 90
)

// Fetch weight trend
let weightTrend = await MetricsService.shared.fetchWeightHistory(days: 90)

// Fetch activity feed
let recentWorkouts = await MetricsService.shared.fetchWorkoutHistory(days: 30)
```

## What Happens Now

1. **Existing data auto-syncs:** On next app launch, all local workout sessions and weight entries will automatically sync to Supabase
2. **New data syncs immediately:** Every completed workout and weight entry now syncs in the background
3. **Offline resilience:** If syncs fail (no network), they'll retry on next launch
4. **Ready for UI:** All fetch methods are ready for the Metrics page UI

## Testing Checklist

- [ ] Clean build the app (Cmd+Shift+K)
- [ ] Launch the app - watch console for bulk sync logs
- [ ] Complete a new workout - verify sync log appears
- [ ] Add a weight entry - verify sync log appears
- [ ] Query Supabase directly: `SELECT COUNT(*) FROM workout_sessions WHERE user_id = 'your-uuid'`
- [ ] Call `MetricsService.shared.fetchMetricsSummary()` from a test view

## Files Modified

**New files:**
- `scripts/sql/CREATE_USER_METRICS_TABLES.sql` (573 lines)
- `scripts/apply-metrics-migration.sh` (executable)
- `StepComp/Models/UserMetrics.swift`
- `StepComp/Services/MetricsService.swift`

**Modified files:**
- `StepComp/ViewModels/WorkoutViewModel.swift` - added sync call in `finishWorkout()`
- `StepComp/ViewModels/WeightViewModel.swift` - added sync call in `addEntry()`
- `StepComp/StepCompApp.swift` - added `syncAllLocalData()` on launch

## Future Enhancements (Out of Scope)

- Metrics UI page with charts and trend visualizations
- HealthKit active minutes / distance syncing to Supabase
- Apple Watch workout integration
- Export/import functionality for user data
- Advanced analytics (PR predictions, volume periodization tracking)
