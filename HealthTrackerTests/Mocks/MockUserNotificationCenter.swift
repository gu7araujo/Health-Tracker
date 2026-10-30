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

    // MARK: - Call Tracking

    var requestAuthorizationOptions: UNAuthorizationOptions?
    var addedRequests: [UNNotificationRequest] = []
    var removeAllPendingCalled = false
    var removedPendingIdentifiers: [[String]] = []
    var removedDeliveredIdentifiers: [[String]] = []

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
    }

    func removeAllPendingNotificationRequests() {
        removeAllPendingCalled = true
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedPendingIdentifiers.append(identifiers)
    }

    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        removedDeliveredIdentifiers.append(identifiers)
    }
}
