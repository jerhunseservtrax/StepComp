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

@MainActor
final class WorkoutSignOutCleanupTests: XCTestCase {
    override func tearDown() {
        WorkoutViewModel.shared.cancelWorkout()
        super.tearDown()
    }

    func testClearAllActiveWorkoutStateStopsInMemorySession() {
        let workout = Workout(name: "Private Workout", exercises: [], assignedDays: [])
        WorkoutViewModel.shared.startWorkout(workout)
        XCTAssertNotNil(WorkoutViewModel.shared.currentSession)

        WorkoutViewModel.clearAllActiveWorkoutState()

        XCTAssertNil(WorkoutViewModel.shared.currentSession)
        XCTAssertNil(WorkoutViewModel.shared.sessionStartTime)
        XCTAssertEqual(WorkoutViewModel.shared.elapsedTime, 0)
        XCTAssertFalse(WorkoutViewModel.shared.isPaused)
    }
}

final class OfflineCacheServiceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        OfflineCacheService.clearAll()
    }

    override func tearDown() {
        OfflineCacheService.clearAll()
        super.tearDown()
    }

    func testFetchWithFallbackDoesNotServeCacheForPermissionErrors() async {
        let cacheKey = "private_metrics_summary"
        OfflineCacheService.save(["previous-user-private-data"], key: cacheKey)
        let permissionError = NSError(
            domain: "PostgREST",
            code: 403,
            userInfo: [NSLocalizedDescriptionKey: "permission denied for table metrics"]
        )

        let value: [String]? = await OfflineCacheService.fetchWithFallback(key: cacheKey) {
            throw permissionError
        }

        XCTAssertNil(value)
    }
}
