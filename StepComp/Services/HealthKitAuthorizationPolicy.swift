//
//  HealthKitAuthorizationPolicy.swift
//  FitComp
//
//  HKHealthStore.authorizationStatus(for:) reports write/share status only.
//  Read permission cannot be inspected, so reads must be attempted after the
//  user has been prompted — even if they denied write.
//

import Foundation

enum HealthKitAuthorizationPolicy {
    /// Apple's HKAuthorizationStatus raw values, stored as Int so this
    /// policy can be tested without importing HealthKit.
    enum WriteStatusRaw: Int {
        case notDetermined = 0
        case sharingDenied = 1
        case sharingAuthorized = 2
    }

    /// Attempt HealthKit queries after the permission sheet has been shown.
    /// `.sharingDenied` only means write was refused; read may still be granted.
    static func canAttemptRead(writeStatusRawValue: Int) -> Bool {
        writeStatusRawValue != WriteStatusRaw.notDetermined.rawValue
    }

    /// Writes require explicit share authorization for the sample type.
    static func canAttemptWrite(writeStatusRawValue: Int) -> Bool {
        writeStatusRawValue == WriteStatusRaw.sharingAuthorized.rawValue
    }
}
