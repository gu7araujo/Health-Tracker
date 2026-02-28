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
final class MockNotificationService: NotificationServiceProtocol {
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

    /// Tracks whether setDelegate was called
    var setDelegateCalled = false

    // MARK: - Scheduling Methods

    /// Tracking properties for scheduling methods
    var scheduleNotificationCalled = false
    var scheduleNotificationIdentifiers: [String] = []
    var scheduleNotificationTitles: [String] = []
    var scheduleNotificationBodies: [String] = []
    var scheduleNotificationRepeats: [Bool] = []
    var scheduleNotificationDateComponents: [DateComponents] = []

    var cancelAllNotificationsCalled = false

    // Tracking properties for cancellation methods
    var cancelNotificationsCalled = false
    var cancelNotificationsIdentifiers: [[String]] = []

    var removeDeliveredNotificationsCalled = false
    var removeDeliveredNotificationsIdentifiers: [[String]] = []

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

    func setDelegate(_: NotificationCenterDelegate?) {
        setDelegateCalled = true
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
    }

    func cancelAllNotifications() {
        cancelAllNotificationsCalled = true
    }

    func cancelNotifications(withIdentifiers identifiers: [String]) {
        cancelNotificationsCalled = true
        cancelNotificationsIdentifiers.append(identifiers)
    }

    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        removeDeliveredNotificationsCalled = true
        removeDeliveredNotificationsIdentifiers.append(identifiers)
    }

    /// Resets cancellation tracking state for fresh test assertions.
    func resetCancellationTracking() {
        cancelNotificationsCalled = false
        cancelNotificationsIdentifiers = []
        removeDeliveredNotificationsCalled = false
        removeDeliveredNotificationsIdentifiers = []
    }
}
