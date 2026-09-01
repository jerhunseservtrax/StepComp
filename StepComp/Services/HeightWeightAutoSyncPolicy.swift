//
//  HeightWeightAutoSyncPolicy.swift
//  FitComp
//
//  Rules for first-run HealthKit → profile height/weight sync.
//  Display defaults (175 cm / 68 kg) are valid body measurements and must
//  never be treated as "user has not set a value".
//

import Foundation

enum HeightWeightAutoSyncPolicy {
    /// `UserDefaults.integer` returns 0 when a key is missing.
    static func isMissingStoredMeasurement(_ stored: Int) -> Bool {
        stored <= 0
    }

    /// Auto-load only fields that have never been persisted.
    static func shouldAutoLoad(storedHeight: Int, storedWeight: Int) -> Bool {
        isMissingStoredMeasurement(storedHeight) || isMissingStoredMeasurement(storedWeight)
    }

    /// Persist only values actually read from HealthKit. Unloaded fields stay
    /// nil so a UI default (68 kg / 175 cm) is not written to `profiles`.
    static func profileWritePayload(
        loadedHeight: Int?,
        loadedWeight: Int?
    ) -> (height: Int?, weight: Int?) {
        (height: sanitized(loadedHeight), weight: sanitized(loadedWeight))
    }

    /// A nil incoming field must keep the existing cloud value.
    static func mergedProfileValues(
        incomingHeight: Int?,
        incomingWeight: Int?,
        existingHeight: Int?,
        existingWeight: Int?
    ) -> (height: Int?, weight: Int?) {
        (
            height: incomingHeight ?? existingHeight,
            weight: incomingWeight ?? existingWeight
        )
    }

    private static func sanitized(_ value: Int?) -> Int? {
        guard let value, value > 0 else { return nil }
        return value
    }
}
