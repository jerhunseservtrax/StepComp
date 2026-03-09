//
//  MetricsService.swift
//  StepComp
//
//  Syncs workout sessions and weight entries to Supabase and fetches
//  historical metrics data for the Metrics page.
//

import Foundation
import Combine

#if canImport(Supabase)
import Supabase
#endif

@MainActor
final class MetricsService: ObservableObject {
    static let shared = MetricsService()

    private let syncedSessionsKey = "metrics_synced_session_ids"
    private let syncedWeightEntriesKey = "metrics_synced_weight_entry_ids"

    private init() {}

    // MARK: - Sync: Workout Session

    /// Converts a local CompletedWorkoutSession to a JSON payload and syncs to Supabase.
    func syncWorkoutSession(_ session: CompletedWorkoutSession) async {
        #if canImport(Supabase)
        do {
            _ = try await supabase.auth.session
        } catch {
            print("⚠️ [MetricsService] No session, skipping workout sync")
            return
        }

        var setsArray: [AnyJSON] = []
        for exercise in session.exercises {
            for workoutSet in exercise.sets {
                var setDict: [String: AnyJSON] = [
                    "exercise_name": .string(exercise.exercise.name),
                    "target_muscles": .string(exercise.exercise.targetMuscles),
                    "set_number": .integer(workoutSet.setNumber),
                    "is_completed": .bool(workoutSet.isCompleted)
                ]
                if let w = workoutSet.weight { setDict["weight_kg"] = .integer(Int(w.rounded())) }
                if let r = workoutSet.reps { setDict["reps"] = .integer(r) }
                setsArray.append(.object(setDict))
            }
        }

        let isoFormatter = ISO8601DateFormatter()
        let sessionPayload: [String: AnyJSON] = [
            "workout_id": .string(session.workoutId.uuidString),
            "workout_name": .string(session.workoutName),
            "started_at": .string(isoFormatter.string(from: session.startTime)),
            "ended_at": .string(isoFormatter.string(from: session.endTime)),
            "source": .string("app"),
            "sets": .array(setsArray)
        ]

        do {
            _ = try await supabase
                .rpc("sync_workout_session", params: [
                    "p_session": .object(sessionPayload)
                ] as [String: AnyJSON])
                .execute()

            markSessionSynced(session.id)
            print("✅ [MetricsService] Synced workout session: \(session.workoutName)")
        } catch {
            print("❌ [MetricsService] Failed to sync workout session: \(error.localizedDescription)")
        }
        #endif
    }

    // MARK: - Sync: Weight Entry

    /// Syncs a single weight entry to Supabase via the sync_weight_entry RPC.
    func syncWeightEntry(_ entry: WeightEntry) async {
        #if canImport(Supabase)
        do {
            _ = try await supabase.auth.session
        } catch {
            print("⚠️ [MetricsService] No session, skipping weight sync")
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: entry.date)

        do {
            _ = try await supabase
                .rpc("sync_weight_entry", params: [
                    "p_date": dateString,
                    "p_weight_kg": String(entry.weightKg),
                    "p_source": entry.source == .healthKit ? "healthKit" : "manual"
                ])
                .execute()

            markWeightEntrySynced(entry.id)
            print("✅ [MetricsService] Synced weight entry: \(entry.weightKg) kg on \(dateString)")
        } catch {
            print("❌ [MetricsService] Failed to sync weight entry: \(error.localizedDescription)")
        }
        #endif
    }

    // MARK: - Bulk Sync (offline catch-up)

    /// Syncs all local workout sessions and weight entries that haven't been synced yet.
    /// Call this on app launch to recover from any missed syncs.
    func syncAllLocalData() async {
        #if canImport(Supabase)
        do {
            _ = try await supabase.auth.session
        } catch {
            print("⚠️ [MetricsService] No session, skipping bulk sync")
            return
        }

        print("🔄 [MetricsService] Starting bulk sync of local data...")

        let workoutVM = WorkoutViewModel.shared
        let weightVM = WeightViewModel.shared

        let syncedSessionIds = getSyncedSessionIds()
        let unsyncedSessions = workoutVM.completedSessions.filter { !syncedSessionIds.contains($0.id.uuidString) }

        if !unsyncedSessions.isEmpty {
            print("🔄 [MetricsService] Syncing \(unsyncedSessions.count) unsynced workout sessions...")
            for session in unsyncedSessions {
                await syncWorkoutSession(session)
            }
        }

        let syncedWeightIds = getSyncedWeightEntryIds()
        let unsyncedEntries = weightVM.entries.filter { !syncedWeightIds.contains($0.id.uuidString) }

        if !unsyncedEntries.isEmpty {
            print("🔄 [MetricsService] Syncing \(unsyncedEntries.count) unsynced weight entries...")
            for entry in unsyncedEntries {
                await syncWeightEntry(entry)
            }
        }

        if unsyncedSessions.isEmpty && unsyncedEntries.isEmpty {
            print("✅ [MetricsService] All local data already synced")
        } else {
            print("✅ [MetricsService] Bulk sync complete")
        }
        #endif
    }

    // MARK: - Fetch: Metrics Summary

    func fetchMetricsSummary(days: Int = 30) async -> MetricsSummary? {
        #if canImport(Supabase)
        do {
            let result: MetricsSummary = try await supabase
                .rpc("get_user_metrics_summary", params: ["p_days": String(days)])
                .execute()
                .value
            return result
        } catch {
            print("❌ [MetricsService] Failed to fetch metrics summary: \(error.localizedDescription)")
            return nil
        }
        #else
        return nil
        #endif
    }

    // MARK: - Fetch: Exercise History

    func fetchExerciseHistory(exerciseName: String, days: Int = 90) async -> [ExerciseHistoryPoint] {
        #if canImport(Supabase)
        do {
            let results: [ExerciseHistoryPoint] = try await supabase
                .rpc("get_exercise_history", params: [
                    "p_exercise_name": exerciseName,
                    "p_days": String(days)
                ])
                .execute()
                .value
            return results
        } catch {
            print("❌ [MetricsService] Failed to fetch exercise history: \(error.localizedDescription)")
            return []
        }
        #else
        return []
        #endif
    }

    // MARK: - Fetch: Weight History

    func fetchWeightHistory(days: Int = 90) async -> [WeightHistoryPoint] {
        #if canImport(Supabase)
        do {
            let results: [WeightHistoryPoint] = try await supabase
                .rpc("get_weight_history", params: ["p_days": String(days)])
                .execute()
                .value
            return results
        } catch {
            print("❌ [MetricsService] Failed to fetch weight history: \(error.localizedDescription)")
            return []
        }
        #else
        return []
        #endif
    }

    // MARK: - Fetch: Workout History

    func fetchWorkoutHistory(days: Int = 90) async -> [WorkoutHistoryPoint] {
        #if canImport(Supabase)
        do {
            let results: [WorkoutHistoryPoint] = try await supabase
                .rpc("get_workout_history", params: ["p_days": String(days)])
                .execute()
                .value
            return results
        } catch {
            print("❌ [MetricsService] Failed to fetch workout history: \(error.localizedDescription)")
            return []
        }
        #else
        return []
        #endif
    }

    // MARK: - Sync Tracking (UserDefaults)

    private func getSyncedSessionIds() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: syncedSessionsKey) ?? [])
    }

    private func markSessionSynced(_ id: UUID) {
        var ids = UserDefaults.standard.stringArray(forKey: syncedSessionsKey) ?? []
        ids.append(id.uuidString)
        UserDefaults.standard.set(ids, forKey: syncedSessionsKey)
    }

    private func getSyncedWeightEntryIds() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: syncedWeightEntriesKey) ?? [])
    }

    private func markWeightEntrySynced(_ id: UUID) {
        var ids = UserDefaults.standard.stringArray(forKey: syncedWeightEntriesKey) ?? []
        ids.append(id.uuidString)
        UserDefaults.standard.set(ids, forKey: syncedWeightEntriesKey)
    }
}
