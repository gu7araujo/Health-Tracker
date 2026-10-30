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
/// This file and its `UserNotificationCentering` seam (`UserNotificationCentering.swift`)
/// are the only files in the project that should import the UserNotifications framework.
final class NotificationService: NotificationServiceProtocol {
    private let notificationCenter: UserNotificationCentering
    private let logger: LoggerProtocol

    /// Initializes the notification service with a notification center and logger.
    ///
    /// - Parameters:
    ///   - notificationCenter: The notification center to use, behind the
    ///     `UserNotificationCentering` seam. Defaults to the current
    ///     `UNUserNotificationCenter`; a fake can be injected for testing.
    ///   - logger: Logger instance for tracking notification operations.
    init(
        notificationCenter: UserNotificationCentering = UNUserNotificationCenter.current(),
        logger: LoggerProtocol = LoggerFactory.dataLogger(category: "NotificationService")
    ) {
        self.notificationCenter = notificationCenter
        self.logger = logger
    }

    // MARK: - NotificationServiceProtocol Implementation

    func requestAuthorization(options: NotificationAuthorizationOptions) async throws -> Bool {
        logger.debug("Requesting notification authorization with options: \(options)")
        let unOptions = options.toUNAuthorizationOptions()
        do {
            let granted = try await notificationCenter.requestAuthorization(options: unOptions)
            logger.info("Notification authorization result: \(granted)")
            return granted
        } catch {
            logger.error("Failed to request notification authorization: \(error.localizedDescription)")
            throw error
        }
    }

    func authorizationStatus() async -> NotificationAuthorizationStatus {
        logger.debug("Checking notification authorization status")
        let unStatus = await notificationCenter.authorizationStatus()
        let status = NotificationAuthorizationStatus.from(unStatus)
        logger.debug("Current authorization status: \(status)")
        return status
    }

    func setDelegate(_ delegate: NotificationCenterDelegate?) {
        // Note: Phase 1 implementation accepts the delegate parameter for interface completeness.
        // Phase 2 will implement actual delegate bridging to handle foreground notifications
        // and user interactions. For now, we just log to indicate the method was called.
        if delegate != nil {
            logger.debug("Delegate set (Phase 2 will implement bridging)")
        } else {
            logger.debug("Delegate removed")
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
        logger.debug("Scheduling notification: \(identifier), repeats: \(repeats)")

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

        do {
            try await notificationCenter.add(request)
            logger.info("Notification scheduled successfully: \(identifier)")
        } catch {
            logger.error("Failed to schedule notification \(identifier): \(error.localizedDescription)")
            throw error
        }
    }

    func cancelAllNotifications() {
        logger.debug("Canceling all pending notifications")
        notificationCenter.removeAllPendingNotificationRequests()
        logger.info("All pending notifications canceled")
    }

    nonisolated func cancelNotifications(withIdentifiers identifiers: [String]) {
        logger.debug("Canceling notifications: \(identifiers)")
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        logger.info("Canceled \(identifiers.count) notification(s)")
    }

    nonisolated func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        logger.debug("Removing delivered notifications: \(identifiers)")
        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
        logger.info("Removed \(identifiers.count) delivered notification(s)")
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
