//
//  KeychainStoreTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class KeychainStoreTests: XCTestCase {
    private let testAccount = "com.fitcomp.test.keychain"

    override func tearDown() {
        super.tearDown()
        KeychainStore.delete(account: testAccount)
    }

    func testSaveAndLoad() {
        let payload = Data("hello-keychain".utf8)
        let saved = KeychainStore.save(payload, account: testAccount)
        XCTAssertTrue(saved)

        let loaded = KeychainStore.load(account: testAccount)
        XCTAssertEqual(loaded, payload)
    }

    func testDeleteRemovesEntry() {
        let payload = Data("to-delete".utf8)
        KeychainStore.save(payload, account: testAccount)

        let deleted = KeychainStore.delete(account: testAccount)
        XCTAssertTrue(deleted)

        let loaded = KeychainStore.load(account: testAccount)
        XCTAssertNil(loaded)
    }

    func testLoadMissingAccountReturnsNil() {
        let loaded = KeychainStore.load(account: "nonexistent-\(UUID().uuidString)")
        XCTAssertNil(loaded)
    }

    func testSaveOverwritesPreviousValue() {
        let first = Data("first".utf8)
        let second = Data("second".utf8)
        KeychainStore.save(first, account: testAccount)
        KeychainStore.save(second, account: testAccount)

        let loaded = KeychainStore.load(account: testAccount)
        XCTAssertEqual(loaded, second)
    }
}

final class OfflineCacheServiceTests: XCTestCase {
    override func tearDown() {
        OfflineCacheService.clearAll()
        super.tearDown()
    }

    func testUserScopedCacheDoesNotBleedBetweenAccounts() {
        let key = "metrics_summary_30"

        OfflineCacheService.save(["user-a-private"], key: key, userId: "user-a")

        XCTAssertEqual(
            OfflineCacheService.load([String].self, key: key, userId: "user-a"),
            ["user-a-private"]
        )
        XCTAssertNil(OfflineCacheService.load([String].self, key: key, userId: "user-b"))
        XCTAssertNil(OfflineCacheService.load([String].self, key: key))
    }
}
