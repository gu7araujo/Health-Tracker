//
//  NotificationServiceProtocol.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 02/28/26.
//

import Foundation

/// Protocol defining the contract for notification service operations.
/// The Domain layer depends on this abstraction, NOT on concrete implementations.
/// This follows the Dependency Inversion Principle.
///
/// This protocol abstracts notification operations without coupling the Domain layer
/// to iOS UserNotifications framework. Concrete implementations in the Data layer
/// will handle platform-specific details.
protocol NotificationServiceProtocol {
    /// Requests authorization to display notifications.
    ///
    /// This method requests permission from the user to show notifications.
    /// The user will see a system permission dialog on the first request.
    /// Subsequent calls will return the cached result without showing the dialog.
    ///
    /// - Parameter options: The types of notifications to request (alert, sound, badge)
    /// - Returns: `true` if permission was granted, `false` if denied
    /// - Throws: An error if the request fails
    func requestAuthorization(options: NotificationAuthorizationOptions) async throws -> Bool

    /// Checks the current notification authorization status.
    ///
    /// This method queries the system for the current permission state.
    /// Use this to check authorization before scheduling notifications.
    ///
    /// - Returns: The current authorization status
    func authorizationStatus() async -> NotificationAuthorizationStatus

    /// Schedules a notification with calendar-based trigger.
    ///
    /// This method creates a notification request with the specified content and timing.
    /// The notification will fire when the date components match the current date/time.
    ///
    /// - Parameters:
    ///   - identifier: Unique identifier for the notification. Used to replace or cancel later.
    ///   - title: Notification title (shown in bold)
    ///   - body: Notification body text
    ///   - dateComponents: When to fire (e.g., DateComponents(hour: 13, minute: 0))
    ///   - repeats: Whether notification should recur when date components match again
    /// - Throws: An error if scheduling fails
    func scheduleNotification(
        identifier: String,
        title: String,
        body: String,
        dateComponents: DateComponents,
        repeats: Bool
    ) async throws

    /// Cancels all pending notifications scheduled by this app.
    ///
    /// Use this to clear notifications before rescheduling or when user logs data.
    func cancelAllNotifications()

    /// Cancels pending notifications with the specified identifiers.
    ///
    /// This method removes scheduled notifications that have not yet been delivered.
    /// Use this to prevent future notifications from firing.
    ///
    /// - Parameter identifiers: Array of notification identifiers to cancel
    func cancelNotifications(withIdentifiers identifiers: [String])

    /// Removes delivered notifications with the specified identifiers.
    ///
    /// This method clears notifications that have already been delivered and are
    /// visible in the Notification Center. Use this to clean up notifications
    /// after the user has taken action.
    ///
    /// - Parameter identifiers: Array of notification identifiers to remove
    func removeDeliveredNotifications(withIdentifiers identifiers: [String])
}

// MARK: - Domain Types

/// Domain representation of notification authorization options.
///
/// This type mirrors iOS UNAuthorizationOptions but remains independent of
/// the UserNotifications framework. This allows the Domain layer to compile
/// without iOS framework dependencies.
struct NotificationAuthorizationOptions: OptionSet {
    let rawValue: Int

    /// Permission to display alerts/banners
    static let alert = NotificationAuthorizationOptions(rawValue: 1 << 0)

    /// Permission to play notification sounds
    static let sound = NotificationAuthorizationOptions(rawValue: 1 << 1)

    /// Permission to update the app badge
    static let badge = NotificationAuthorizationOptions(rawValue: 1 << 2)
}

/// Domain representation of notification authorization status.
///
/// This enum represents the user's permission state for notifications.
/// It mirrors iOS UNAuthorizationStatus but remains independent of the
/// UserNotifications framework.
enum NotificationAuthorizationStatus {
    /// The user has not yet been asked for notification permission
    case notDetermined

    /// The user has explicitly denied notification permission
    case denied

    /// The user has granted notification permission
    case authorized

    /// The user has granted provisional notification permission (quiet notifications)
    case provisional

    /// The user has granted ephemeral notification permission (temporary for App Clips)
    case ephemeral
}

/// Protocol for receiving notification-related events.
///
/// This protocol abstracts the notification delegate without coupling to
/// iOS UNUserNotificationCenterDelegate. Implementations in the Data layer
/// will bridge between this protocol and the platform-specific delegate.
///
/// Note: This protocol is minimal in Phase 1. It will be expanded in Phase 2
/// when foreground notification handling and user interaction callbacks are needed.
protocol NotificationCenterDelegate: AnyObject {
    // Phase 2 will add methods for:
    // - Handling notifications while app is in foreground
    // - Responding to user interactions with notifications
}
