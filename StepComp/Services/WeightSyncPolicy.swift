//
//  WeightSyncPolicy.swift
//  FitComp
//
//  Pure helpers for weight day-keying and HealthKit import decisions.
//

import Foundation

enum WeightSyncPolicy {
    /// Import a HealthKit sample only when no local entry already covers that sample's calendar day.
    static func shouldImportHealthKitSample(
        sampleDate: Date,
        existingEntryDates: [Date],
        calendar: Calendar = .current
    ) -> Bool {
        !existingEntryDates.contains { calendar.isDate($0, inSameDayAs: sampleDate) }
    }

    /// Persist the HealthKit sample's own timestamp — never stamp `Date()`.
    static func entryDateForHealthKitImport(sampleDate: Date) -> Date {
        sampleDate
    }

    /// Local calendar day key for `weight_log.recorded_on` (yyyy-MM-dd).
    static func recordedOnString(from date: Date, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
