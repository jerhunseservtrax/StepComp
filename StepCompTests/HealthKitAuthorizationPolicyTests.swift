//
//  HealthKitAuthorizationPolicyTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class HealthKitAuthorizationPolicyTests: XCTestCase {
    /// Apple's HKAuthorizationStatus raw values.
    private let notDetermined = 0
    private let sharingDenied = 1
    private let sharingAuthorized = 2

    func testReadIsBlockedBeforeUserIsPrompted() {
        XCTAssertFalse(HealthKitAuthorizationPolicy.canAttemptRead(writeStatusRawValue: notDetermined))
        XCTAssertFalse(HealthKitAuthorizationPolicy.canAttemptWrite(writeStatusRawValue: notDetermined))
    }

    func testReadIsAllowedWhenWriteWasDenied() {
        XCTAssertTrue(HealthKitAuthorizationPolicy.canAttemptRead(writeStatusRawValue: sharingDenied))
        XCTAssertFalse(HealthKitAuthorizationPolicy.canAttemptWrite(writeStatusRawValue: sharingDenied))
    }

    func testReadAndWriteAllowedWhenSharingAuthorized() {
        XCTAssertTrue(HealthKitAuthorizationPolicy.canAttemptRead(writeStatusRawValue: sharingAuthorized))
        XCTAssertTrue(HealthKitAuthorizationPolicy.canAttemptWrite(writeStatusRawValue: sharingAuthorized))
    }
}
