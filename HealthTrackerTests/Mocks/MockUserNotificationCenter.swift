//
//  MockUserNotificationCenter.swift
//  HealthTrackerTests
//
//  Created by Gustavo Araujo Santos on 08/03/26.
//

import Foundation
@testable import HealthTracker
import UserNotifications

/// Mock implementation of `UserNotificationCentering` for testing `NotificationService`
/// without touching the real `UNUserNotificationCenter`. Follows the shared mock pattern:
/// `...Result`/`...Error` stubs for return values, and spies for interaction verification.
final nonisolated class MockUserNotificationCenter: UserNotificationCentering, @unchecked Sendable {
    // MARK: - Stored Results

    var requestAuthorizationResult = true
    var requestAuthorizationError: Error?
    var authorizationStatusResult: UNAuthorizationStatus = .notDetermined
    var addError: Error?
    /// Makes every removal wait (up to 1 s) for a signal, like `usernotificationsd` stalling its reply.
    var removalStall: DispatchSemaphore?

    // MARK: - Call Tracking

    var requestAuthorizationOptions: UNAuthorizationOptions?
    var addedRequests: [UNNotificationRequest] = []
    var removeAllPendingCalled = false
    var removedPendingIdentifiers: [[String]] = []
    var removedDeliveredIdentifiers: [[String]] = []
    /// Every add and removal, in the order the center received them.
    private(set) var callOrder: [String] = []
    /// True when a stalled removal was never released: its caller waited out the stall.
    private(set) var removalStallTimedOut = false
    /// Signaled after each removal; wait on it before reading the removal spies.
    let removalFinished = DispatchSemaphore(value: 0)

    // MARK: - UserNotificationCentering Implementation

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        requestAuthorizationOptions = options
        if let requestAuthorizationError {
            throw requestAuthorizationError
        }
        return requestAuthorizationResult
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        authorizationStatusResult
    }

    func add(_ request: UNNotificationRequest) async throws {
        if let addError {
            throw addError
        }
        addedRequests.append(request)
        callOrder.append("add")
    }

    func removeAllPendingNotificationRequests() {
        stallIfAsked()
        removeAllPendingCalled = true
        callOrder.append("removeAllPending")
        removalFinished.signal()
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        stallIfAsked()
        removedPendingIdentifiers.append(identifiers)
        removalFinished.signal()
    }

    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        stallIfAsked()
        removedDeliveredIdentifiers.append(identifiers)
        removalFinished.signal()
    }

    private func stallIfAsked() {
        guard let removalStall else { return }
        removalStallTimedOut = removalStall.wait(timeout: .now() + 1) == .timedOut
    }
}
