//
//  NotificationService.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 02/28/26.
//

import Foundation
import UserNotifications

/// Concrete implementation of NotificationServiceProtocol that wraps UNUserNotificationCenter.
///
/// This class is part of the Data layer and is responsible for mapping Domain types
/// to iOS UserNotifications framework types. It follows Clean Architecture principles
/// by implementing a protocol defined in the Domain layer.
///
/// This is the ONLY file in the project that should import UserNotifications framework.
final class NotificationService: NotificationServiceProtocol {
    private let notificationCenter: UNUserNotificationCenter

    /// Initializes the notification service with a notification center.
    ///
    /// - Parameter notificationCenter: The UNUserNotificationCenter instance to use.
    ///   Defaults to the current notification center. The default parameter allows
    ///   dependency injection for testing.
    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }

    // MARK: - NotificationServiceProtocol Implementation

    func requestAuthorization(options: NotificationAuthorizationOptions) async throws -> Bool {
        let unOptions = options.toUNAuthorizationOptions()
        return try await notificationCenter.requestAuthorization(options: unOptions)
    }

    func authorizationStatus() async -> NotificationAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return NotificationAuthorizationStatus.from(settings.authorizationStatus)
    }

    func setDelegate(_ delegate: NotificationCenterDelegate?) {
        // Note: Phase 1 implementation accepts the delegate parameter for interface completeness.
        // Phase 2 will implement actual delegate bridging to handle foreground notifications
        // and user interactions. For now, we just log to indicate the method was called.
        if delegate != nil {
            print("[NotificationService] Delegate set (Phase 2 will implement bridging)")
        } else {
            print("[NotificationService] Delegate removed")
        }
    }

    // MARK: - Scheduling Methods

    func scheduleNotification(
        identifier: String,
        title: String,
        body: String,
        dateComponents: DateComponents,
        repeats: Bool
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        // Calendar-based trigger fires when date components match the current date/time.
        // When only hour/minute are specified (without timeZone), iOS automatically uses
        // the device's local time zone, handling time zone changes and DST transitions.
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: repeats
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    func cancelNotifications(withIdentifiers identifiers: [String]) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
}

// MARK: - Type Mapping Extensions

/// Extension to convert Domain NotificationAuthorizationOptions to iOS UNAuthorizationOptions.
///
/// This mapping keeps the Domain layer independent of iOS frameworks while allowing
/// the Data layer to work with platform-specific types.
private extension NotificationAuthorizationOptions {
    func toUNAuthorizationOptions() -> UNAuthorizationOptions {
        var result: UNAuthorizationOptions = []
        if contains(.alert) { result.insert(.alert) }
        if contains(.sound) { result.insert(.sound) }
        if contains(.badge) { result.insert(.badge) }
        return result
    }
}

/// Extension to convert iOS UNAuthorizationStatus to Domain NotificationAuthorizationStatus.
///
/// This mapping ensures that the Domain layer works with its own types while
/// the Data layer handles the translation from iOS framework types.
///
/// The @unknown default case ensures forward compatibility with future iOS versions
/// that might add new authorization status values.
private extension NotificationAuthorizationStatus {
    static func from(_ unStatus: UNAuthorizationStatus) -> NotificationAuthorizationStatus {
        switch unStatus {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .provisional:
            return .provisional
        case .ephemeral:
            return .ephemeral
        @unknown default:
            // Future iOS versions may add new status values.
            // Default to notDetermined as a safe fallback.
            return .notDetermined
        }
    }
}
