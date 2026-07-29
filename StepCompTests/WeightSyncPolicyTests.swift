//
//  WeightSyncPolicyTests.swift
//  FitComp Tests
//
//  Regression coverage for HealthKit weight day-keying and remote delete keys.
//

import XCTest
@testable import StepComp

final class WeightSyncPolicyTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
    }

    func testShouldImportWhenNoEntryExistsForSampleDay() {
        let sampleDate = date(year: 2026, month: 7, day: 20, hour: 8)
        let todayEntry = date(year: 2026, month: 7, day: 29, hour: 9)

        let shouldImport = WeightSyncPolicy.shouldImportHealthKitSample(
            sampleDate: sampleDate,
            existingEntryDates: [todayEntry],
            calendar: calendar
        )

        XCTAssertTrue(
            shouldImport,
            "A HealthKit sample from a prior day must import even when today already has an entry"
        )
    }

    func testShouldNotImportWhenSampleDayAlreadyLogged() {
        let sampleDate = date(year: 2026, month: 7, day: 20, hour: 18)
        let existingSameDay = date(year: 2026, month: 7, day: 20, hour: 7)

        let shouldImport = WeightSyncPolicy.shouldImportHealthKitSample(
            sampleDate: sampleDate,
            existingEntryDates: [existingSameDay],
            calendar: calendar
        )

        XCTAssertFalse(shouldImport)
    }

    func testRecordedOnUsesLocalCalendarDayNotUTCShift() {
        // 2026-07-20 23:30 PDT == 2026-07-21 06:30 UTC — local day must stay 2026-07-20
        let localEvening = date(year: 2026, month: 7, day: 20, hour: 23, minute: 30)

        let recordedOn = WeightSyncPolicy.recordedOnString(from: localEvening, calendar: calendar)

        XCTAssertEqual(recordedOn, "2026-07-20")
    }

    func testEntryDateForImportUsesSampleDateNotNow() {
        let sampleDate = date(year: 2026, month: 7, day: 18, hour: 6)
        let now = date(year: 2026, month: 7, day: 29, hour: 12)
        let importedDate = WeightSyncPolicy.entryDateForHealthKitImport(sampleDate: sampleDate)

        XCTAssertEqual(importedDate, sampleDate)
        XCTAssertFalse(
            calendar.isDate(importedDate, inSameDayAs: now),
            "HealthKit import must keep the sample day; stamping Date() corrupts weight_log"
        )
    }

    private func date(year: Int, month: Int, day: Int, hour: Int, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }
}
