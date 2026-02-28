//
//  RequestNotificationPermissionUseCase.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 02/28/26.
//

import Foundation

/// Use case for requesting notification permissions from the user.
///
/// This Use Case encapsulates the business logic for the notification permission flow.
/// It coordinates with the NotificationServiceProtocol to handle authorization requests
/// and status checks without directly depending on iOS frameworks.
///
/// ViewModels should use this Use Case rather than importing UserNotifications framework
/// directly, maintaining Clean Architecture separation of concerns.
final class RequestNotificationPermissionUseCase {
    private let notificationService: NotificationServiceProtocol

    /// Initializes the use case with a notification service dependency.
    ///
    /// - Parameter notificationService: The service that handles notification operations.
    ///   This is typically a NotificationService instance but can be a mock for testing.
    init(notificationService: NotificationServiceProtocol) {
        self.notificationService = notificationService
    }

    // MARK: - Public Methods

    /// Requests notification permission from the user with alert, sound, and badge options.
    ///
    /// This method requests all standard notification types (alert, sound, badge).
    /// On the first call, iOS will show the system permission dialog. Subsequent calls
    /// will return the cached authorization result without showing the dialog again.
    ///
    /// - Returns: `true` if permission was granted, `false` if denied
    /// - Throws: An error if the authorization request fails
    func execute() async throws -> Bool {
        let options: NotificationAuthorizationOptions = [.alert, .sound, .badge]
        return try await notificationService.requestAuthorization(options: options)

        // Future: Could track permission status in analytics
        // Future: Could persist status in UserDefaults for first-run tracking
    }

    /// Checks if notification permission is currently authorized.
    ///
    /// This method queries the current authorization status without requesting permission.
    /// Use this to check authorization before scheduling notifications (NOTIF-02 requirement).
    ///
    /// - Returns: `true` if authorized, `false` for any other status (denied, notDetermined, etc.)
    func isAuthorized() async -> Bool {
        let status = await notificationService.authorizationStatus()
        return status == .authorized
    }
}
