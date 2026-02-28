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

    /// Sets the notification center delegate for handling notification events.
    ///
    /// The delegate will receive callbacks for notification-related events such as
    /// when notifications are delivered while the app is in foreground, or when
    /// the user interacts with a notification.
    ///
    /// - Parameter delegate: The delegate object, or nil to remove the current delegate
    func setDelegate(_ delegate: NotificationCenterDelegate?)
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
