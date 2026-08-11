//
//  InviteAcceptViewModelTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

@MainActor
final class InviteAcceptViewModelTests: XCTestCase {
    func testInitialStateDoesNotMarkInviteConsumed() {
        let vm = InviteAcceptViewModel(service: FriendsService())
        XCTAssertFalse(vm.didConsume)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.inviter)
        XCTAssertNil(vm.errorMessage)
    }
}
