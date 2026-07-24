//
//  StepSyncLocalDayTests.swift
//  FitComp Tests
//
//  Guards against UTC ISO-8601 day keys that mis-attribute HealthKit steps.
//

import XCTest
@testable import StepComp

final class StepSyncLocalDayTests: XCTestCase {
    func testLocalDayStringUsesCalendarTimeZoneNotUTC() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: -4 * 3600)! // EDT

        // 2026-07-23 20:00 EDT == 2026-07-24 00:00 UTC
        let date = Date(timeIntervalSince1970: 1_784_851_200)

        let day = StepSyncService.localDayString(for: date, calendar: calendar)
        XCTAssertEqual(day, "2026-07-23")
        XCTAssertNotEqual(day, "2026-07-24", "Must not use the UTC calendar day")
    }

    func testLocalDayStringFormatIsDateOnly() {
        let day = StepSyncService.localDayString(for: Date())
        let regex = try! NSRegularExpression(pattern: #"^\d{4}-\d{2}-\d{2}$"#)
        let range = NSRange(day.startIndex..<day.endIndex, in: day)
        XCTAssertEqual(regex.numberOfMatches(in: day, range: range), 1)
        XCTAssertFalse(day.contains("T"))
    }
}
