//
//  MockNotificationService.swift
//  HealthTrackerTests
//
//  Created by Gustavo Araujo Santos on 02/28/26.
//

import Foundation
@testable import HealthTracker

/// Mock implementation of NotificationServiceProtocol for unit testing.
///
/// This mock allows tests to simulate various notification scenarios without
/// interacting with the real iOS notification system. It follows the same pattern
/// as MockHealthDataRepository, with configurable results and call tracking.
///
/// Tests can configure the mock to simulate:
/// - Permission granted (requestAuthorizationResult = true)
/// - Permission denied (requestAuthorizationResult = false)
/// - Authorization errors (set requestAuthorizationError)
/// - Different authorization statuses (notDetermined, authorized, denied, etc.)
final nonisolated class MockNotificationService: NotificationServiceProtocol, @unchecked Sendable {
    // MARK: - Stored Results

    /// The authorization status to return from authorizationStatus()
    var authorizationStatusResult: NotificationAuthorizationStatus = .notDetermined

    /// The result to return from requestAuthorization(options:)
    var requestAuthorizationResult: Bool = true

    /// Optional error to throw from requestAuthorization(options:)
    var requestAuthorizationError: Error?

    // MARK: - Call Tracking

    /// Tracks whether requestAuthorization was called
    var requestAuthorizationCalled = false

    /// Stores the options passed to requestAuthorization
    var requestAuthorizationOptionsUsed: NotificationAuthorizationOptions?

    /// Tracks whether authorizationStatus was called
    var authorizationStatusCalled = false

    // MARK: - Scheduling Methods

    /// Tracking properties for scheduling methods
    var scheduleNotificationCalled = false
    var scheduleNotificationIdentifiers: [String] = []
    var scheduleNotificationTitles: [String] = []
    var scheduleNotificationBodies: [String] = []
    var scheduleNotificationRepeats: [Bool] = []
    var scheduleNotificationDateComponents: [DateComponents] = []

    /// Optional error to throw from scheduleNotification (after recording the call)
    var scheduleNotificationError: Error?

    var cancelAllNotificationsCalled = false
    var cancelAllNotificationsRanOnMainThread: Bool?

    // Tracking properties for cancellation methods
    var cancelNotificationsCalled = false
    var cancelNotificationsIdentifiers: [[String]] = []
    var cancelNotificationsRanOnMainThread: Bool?

    var removeDeliveredNotificationsCalled = false
    var removeDeliveredNotificationsIdentifiers: [[String]] = []

    /// Called from inside `cancelNotifications`, on whatever thread the caller used.
    var onCancelNotifications: (@Sendable () -> Void)?

    /// The notification use cases call the cancel methods from parallel off-main calls.
    private let lock = NSLock()

    // MARK: - NotificationServiceProtocol Implementation

    func requestAuthorization(options: NotificationAuthorizationOptions) async throws -> Bool {
        requestAuthorizationCalled = true
        requestAuthorizationOptionsUsed = options

        if let error = requestAuthorizationError {
            throw error
        }

        return requestAuthorizationResult
    }

    func authorizationStatus() async -> NotificationAuthorizationStatus {
        authorizationStatusCalled = true
        return authorizationStatusResult
    }

    func scheduleNotification(
        identifier: String,
        title: String,
        body: String,
        dateComponents: DateComponents,
        repeats: Bool
    ) async throws {
        scheduleNotificationCalled = true
        scheduleNotificationIdentifiers.append(identifier)
        scheduleNotificationTitles.append(title)
        scheduleNotificationBodies.append(body)
        scheduleNotificationRepeats.append(repeats)
        scheduleNotificationDateComponents.append(dateComponents)

        if let error = scheduleNotificationError {
            throw error
        }
    }

    func cancelAllNotifications() {
        lock.withLock {
            cancelAllNotificationsCalled = true
            cancelAllNotificationsRanOnMainThread = Thread.isMainThread
        }
    }

    func cancelNotifications(withIdentifiers identifiers: [String]) {
        lock.withLock {
            cancelNotificationsCalled = true
            cancelNotificationsIdentifiers.append(identifiers)
            cancelNotificationsRanOnMainThread = Thread.isMainThread
        }
        onCancelNotifications?()
    }

    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        lock.withLock {
            removeDeliveredNotificationsCalled = true
            removeDeliveredNotificationsIdentifiers.append(identifiers)
        }
    }
}
