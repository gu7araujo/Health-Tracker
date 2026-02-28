//
//  CancelNotificationsUseCase.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 02/28/26.
//

import Foundation

/// Use case for canceling daily notification reminders when user logs health data.
///
/// This use case implements smart cancellation logic to prevent notification fatigue.
/// When the user logs any health data (meal, workout, water, mood), all notifications
/// for today are canceled to avoid nagging the user after they've already engaged.
///
/// The implementation cancels both pending notifications (not yet fired) and delivered
/// notifications (visible in Notification Center). It targets only today's date-specific
/// identifiers, preserving future days' notifications.
///
/// Satisfies requirements NOTIF-11, NOTIF-12, NOTIF-13, NOTIF-14.
final class CancelNotificationsUseCase {
    private let notificationService: NotificationServiceProtocol

    init(notificationService: NotificationServiceProtocol) {
        self.notificationService = notificationService
    }

    /// Cancels all notifications for today (both pending and delivered).
    ///
    /// This method determines today's date using device's current calendar,
    /// constructs date-specific identifiers ("lunch-reminder-2026-02-28",
    /// "evening-reminder-2026-02-28"), and cancels both pending and delivered
    /// notifications for those identifiers.
    ///
    /// The operation persists automatically through iOS notification system, so it
    /// survives force-quit without additional state management (satisfies NOTIF-14).
    ///
    /// Day boundary logic matches app's existing Calendar.current.isDate pattern
    /// for consistency (satisfies NOTIF-13).
    ///
    /// - Throws: An error if cancellation fails (rare system error)
    func execute() async throws {
        // Determine today's date identifiers (NOTIF-13)
        let today = Calendar.current.startOfDay(for: Date())
        let dateString = formatDateForIdentifier(today)

        let identifiers = [
            "lunch-reminder-\(dateString)",
            "evening-reminder-\(dateString)"
        ]

        // Cancel pending notifications (not yet delivered)
        notificationService.cancelNotifications(withIdentifiers: identifiers)

        // Remove delivered notifications (visible in Notification Center)
        notificationService.removeDeliveredNotifications(withIdentifiers: identifiers)

        print("[CancelNotifications] Canceled notifications for \(dateString)")
    }

    // MARK: - Private Helpers

    /// Formats a date as a string for use in notification identifiers.
    /// - Parameter date: The date to format
    /// - Returns: Date string in "yyyy-MM-dd" format (e.g., "2026-02-28")
    private func formatDateForIdentifier(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar.current
        return formatter.string(from: date)
    }
}
