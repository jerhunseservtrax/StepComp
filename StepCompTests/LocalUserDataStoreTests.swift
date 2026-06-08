//
//  LocalUserDataStoreTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

@MainActor
final class LocalUserDataStoreTests: XCTestCase {
    override func tearDown() {
        for key in LocalUserDataStore.privateUserDefaultsKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        OfflineCacheService.clearAll()
        super.tearDown()
    }

    func testClearPrivateLocalDataRemovesPrivateUserDefaultsAndOfflineCache() {
        for key in LocalUserDataStore.privateUserDefaultsKeys {
            UserDefaults.standard.set(Data("private-\(key)".utf8), forKey: key)
        }
        OfflineCacheService.save(["private metric"], key: "metrics_summary_30")

        LocalUserDataStore.clearPrivateLocalDataForSignedOutUser()

        for key in LocalUserDataStore.privateUserDefaultsKeys {
            XCTAssertNil(UserDefaults.standard.object(forKey: key), "\(key) should be cleared on sign-out")
        }
        XCTAssertNil(OfflineCacheService.load([String].self, key: "metrics_summary_30"))
    }
}
