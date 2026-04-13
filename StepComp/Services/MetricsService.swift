//
//  MetricsService.swift
//  FitComp
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
    private var nutritionLogTableUnavailable = false

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

        let sessionPayload = sessionPayload(for: session)

        do {
            _ = try await SupabaseRequestExecutor.executeWithAuthRetry(context: "sync_workout_session") {
                try await supabase
                    .rpc("sync_workout_session", params: [
                        "p_session": .object(sessionPayload)
                    ] as [String: AnyJSON])
                    .execute()
            }

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
            _ = try await SupabaseRequestExecutor.executeWithAuthRetry(context: "sync_weight_entry") {
                try await supabase
                    .rpc("sync_weight_entry", params: [
                        "p_date": dateString,
                        "p_weight_kg": String(entry.weightKg),
                        "p_source": entry.source == .healthKit ? "healthKit" : "manual"
                    ])
                    .execute()
            }

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
            let batchPayload = unsyncedSessions.map { AnyJSON.object(sessionPayload(for: $0)) }
            do {
                _ = try await SupabaseRequestExecutor.executeWithAuthRetry(context: "sync_workout_sessions_batch") {
                    try await supabase
                        .rpc("sync_workout_sessions_batch", params: ["p_sessions": .array(batchPayload)] as [String: AnyJSON])
                        .execute()
                }
                unsyncedSessions.forEach { markSessionSynced($0.id) }
            } catch {
                for session in unsyncedSessions {
                    await syncWorkoutSession(session)
                }
            }
        }

        let syncedWeightIds = getSyncedWeightEntryIds()
        let unsyncedEntries = weightVM.entries.filter { !syncedWeightIds.contains($0.id.uuidString) }

        if !unsyncedEntries.isEmpty {
            print("🔄 [MetricsService] Syncing \(unsyncedEntries.count) unsynced weight entries...")
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let batchPayload: [AnyJSON] = unsyncedEntries.map { entry in
                .object([
                    "date": .string(formatter.string(from: entry.date)),
                    "weight_kg": .string(String(entry.weightKg)),
                    "source": .string(entry.source == .healthKit ? "healthKit" : "manual")
                ])
            }
            do {
                _ = try await SupabaseRequestExecutor.executeWithAuthRetry(context: "sync_weight_entries_batch") {
                    try await supabase
                        .rpc("sync_weight_entries_batch", params: ["p_entries": .array(batchPayload)] as [String: AnyJSON])
                        .execute()
                }
                unsyncedEntries.forEach { markWeightEntrySynced($0.id) }
            } catch {
                for entry in unsyncedEntries {
                    await syncWeightEntry(entry)
                }
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
        return await OfflineCacheService.fetchWithFallback(key: "metrics_summary_\(days)") {
            try await SupabaseRequestExecutor.executeWithAuthRetry(context: "fetch_metrics_summary") {
                try await supabase
                    .rpc("get_user_metrics_summary", params: ["p_days": String(days)])
                    .execute()
                    .value
            }
        }
        #else
        return nil
        #endif
    }

    // MARK: - Fetch: Exercise History

    func fetchExerciseHistory(exerciseName: String, days: Int = 90) async -> [ExerciseHistoryPoint] {
        #if canImport(Supabase)
        do {
            let results: [ExerciseHistoryPoint] = try await SupabaseRequestExecutor.executeWithAuthRetry(context: "fetch_exercise_history") {
                try await supabase
                    .rpc("get_exercise_history", params: [
                        "p_exercise_name": exerciseName,
                        "p_days": String(days)
                    ])
                    .execute()
                    .value
            }
            return results
        } catch {
            print("❌ [MetricsService] Failed to fetch exercise history: \(error.localizedDescription)")
            return []
        }
        #else
        return []
        #endif
    }

    // MARK: - Fetch: Personal Records

    func fetchPersonalRecords(exerciseName: String? = nil) async -> [PersonalRecord] {
        #if canImport(Supabase)
        do {
            let query = supabase.from("personal_records").select().order("achieved_at", ascending: false).limit(100)
            struct PersonalRecordRow: Codable {
                let id: UUID
                let exercise_name: String
                let record_type: String
                let value: Double
                let achieved_at: Date
            }
            let rows: [PersonalRecordRow] = try await SupabaseRequestExecutor.executeWithAuthRetry(context: "fetch_personal_records") {
                try await query.execute().value
            }
            return rows.compactMap { row in
                if let exerciseName, !exerciseName.isEmpty, row.exercise_name != exerciseName {
                    return nil
                }
                let mappedType: PersonalRecordType
                switch row.record_type {
                case "max_weight": mappedType = .maxWeight
                case "max_reps": mappedType = .maxReps
                case "max_volume": mappedType = .maxVolume
                default: return nil
                }
                return PersonalRecord(
                    id: row.id,
                    exerciseName: row.exercise_name,
                    type: mappedType,
                    value: row.value,
                    achievedAt: row.achieved_at
                )
            }
        } catch {
            print("❌ [MetricsService] Failed to fetch personal records: \(error.localizedDescription)")
            return []
        }
        #else
        return []
        #endif
    }

    // MARK: - Sync: Body Metrics

    func syncBodyMetric(bodyFatPercent: Double?, waistCm: Double?, date: Date = Date()) async {
        #if canImport(Supabase)
        do {
            _ = try await supabase.auth.session
        } catch {
            return
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let payload: [String: AnyJSON] = [
            "recorded_on": .string(dateFormatter.string(from: date)),
            "body_fat_pct": bodyFatPercent.map { .string(String($0)) } ?? .null,
            "waist_cm": waistCm.map { .string(String($0)) } ?? .null,
            "source": .string("manual")
        ]
        do {
            _ = try await supabase.from("body_metrics").upsert(payload).execute()
        } catch {
            print("❌ [MetricsService] Failed to sync body metrics: \(error.localizedDescription)")
        }
        #endif
    }

    // MARK: - Sync: Nutrition Log

    func syncNutritionLog(_ log: NutritionLog) async {
        #if canImport(Supabase)
        do {
            _ = try await supabase.auth.session
        } catch {
            return
        }

        if nutritionLogTableUnavailable {
            return
        }

        let iso = ISO8601DateFormatter().string(from: log.loggedAt)
        let payload: [String: AnyJSON] = [
            "logged_at": .string(iso),
            "calories": .integer(log.calories),
            "protein_g": .integer(log.proteinG),
            "carbs_g": .integer(log.carbsG),
            "fat_g": .integer(log.fatG),
            "water_ml": .integer(log.waterMl)
        ]
        do {
            _ = try await supabase.from("nutrition_log").insert(payload).execute()
        } catch {
            let lowercasedError = error.localizedDescription.lowercased()
            let isMissingNutritionLogTable =
                (lowercasedError.contains("public.nutrition_log") && lowercasedError.contains("schema cache"))
                || (lowercasedError.contains("nutrition_log") && lowercasedError.contains("could not find the table"))

            if isMissingNutritionLogTable {
                nutritionLogTableUnavailable = true
                print("⚠️ [MetricsService] Supabase table public.nutrition_log is missing. Run scripts/sql/CREATE_COMPREHENSIVE_METRICS_TABLES.sql in your Supabase SQL editor, then relaunch the app.")
                return
            }
            print("❌ [MetricsService] Failed to sync nutrition log: \(error.localizedDescription)")
        }
        #endif
    }

    // MARK: - Fetch: Weight History

    func fetchWeightHistory(days: Int = 90) async -> [WeightHistoryPoint] {
        #if canImport(Supabase)
        return await OfflineCacheService.fetchArrayWithFallback(key: "weight_history_\(days)") {
            try await SupabaseRequestExecutor.executeWithAuthRetry(context: "fetch_weight_history") {
                try await supabase
                    .rpc("get_weight_history", params: ["p_days": String(days)])
                    .execute()
                    .value
            }
        }
        #else
        return []
        #endif
    }

    // MARK: - Fetch: Workout History

    func fetchWorkoutHistory(days: Int = 90) async -> [WorkoutHistoryPoint] {
        #if canImport(Supabase)
        return await OfflineCacheService.fetchArrayWithFallback(key: "workout_history_\(days)") {
            try await SupabaseRequestExecutor.executeWithAuthRetry(context: "fetch_workout_history") {
                try await supabase
                    .rpc("get_workout_history", params: ["p_days": String(days)])
                    .execute()
                    .value
            }
        }
        #else
        return []
        #endif
    }

    // MARK: - Sync Tracking (UserDefaults)

    private func sessionPayload(for session: CompletedWorkoutSession) -> [String: AnyJSON] {
        var setsArray: [AnyJSON] = []
        for exercise in session.exercises {
            for workoutSet in exercise.sets {
                var setDict: [String: AnyJSON] = [
                    "exercise_name": .string(exercise.exercise.name),
                    "target_muscles": .string(exercise.exercise.targetMuscles),
                    "set_number": .integer(workoutSet.setNumber),
                    "is_completed": .bool(workoutSet.isCompleted)
                ]
                if let w = workoutSet.effectiveWeightForVolume { setDict["weight_kg"] = .integer(Int(w.rounded())) }
                if let r = workoutSet.reps { setDict["reps"] = .integer(r) }
                setsArray.append(.object(setDict))
            }
        }

        let isoFormatter = ISO8601DateFormatter()
        return [
            "workout_id": .string(session.workoutId.uuidString),
            "workout_name": .string(session.workoutName),
            "started_at": .string(isoFormatter.string(from: session.startTime)),
            "ended_at": .string(isoFormatter.string(from: session.endTime)),
            "source": .string("app"),
            "sets": .array(setsArray)
        ]
    }

    private func getSyncedSessionIds() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: syncedSessionsKey) ?? [])
    }

    private let maxTrackedSyncIds = 500

    private func markSessionSynced(_ id: UUID) {
        var ids = UserDefaults.standard.stringArray(forKey: syncedSessionsKey) ?? []
        let idString = id.uuidString
        guard !ids.contains(idString) else { return }
        ids.append(idString)
        if ids.count > maxTrackedSyncIds {
            ids = Array(ids.suffix(maxTrackedSyncIds))
        }
        UserDefaults.standard.set(ids, forKey: syncedSessionsKey)
    }

    private func getSyncedWeightEntryIds() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: syncedWeightEntriesKey) ?? [])
    }

    private func markWeightEntrySynced(_ id: UUID) {
        var ids = UserDefaults.standard.stringArray(forKey: syncedWeightEntriesKey) ?? []
        let idString = id.uuidString
        guard !ids.contains(idString) else { return }
        ids.append(idString)
        if ids.count > maxTrackedSyncIds {
            ids = Array(ids.suffix(maxTrackedSyncIds))
        }
        UserDefaults.standard.set(ids, forKey: syncedWeightEntriesKey)
    }
}
