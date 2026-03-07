//
//  ScheduleNotificationsUseCase.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 02/28/26.
//

import Foundation

/// Use case for scheduling daily notification reminders.
///
/// Coordinates scheduling of lunch (1 PM) and evening (8 PM) notifications with
/// time-specific Portuguese-BR messages. Handles authorization checks and uses
/// debug-friendly timing in development builds.
///
/// Debug builds use testable times (2-3 minutes from now) for quick verification.
/// Release builds use production times (1 PM, 8 PM) matching user requirements.
final class ScheduleNotificationsUseCase {
    private let notificationService: NotificationServiceProtocol
    private let logger: LoggerProtocol

    init(notificationService: NotificationServiceProtocol, logger: LoggerProtocol) {
        self.notificationService = notificationService
        self.logger = logger
    }

    /// Schedules 30 days of date-specific notifications (lunch and evening reminders).
    ///
    /// Checks authorization status before scheduling. If not authorized, returns
    /// gracefully without throwing (satisfies NOTIF-03 graceful degradation).
    ///
    /// Schedules 60 individual non-repeating notifications (30 days × 2 per day) with
    /// date-specific identifiers (e.g., "lunch-reminder-2026-02-28") to enable
    /// targeted cancellation without affecting future days.
    ///
    /// Debug builds use testable times (2-3 minutes from now) for today's notifications.
    /// Release builds use production times (1 PM, 8 PM).
    ///
    /// - Throws: An error if scheduling fails (e.g., system error)
    func execute() async throws {
        logger.debug("Scheduling notifications for next 30 days")

        // Check authorization (NOTIF-02)
        let status = await notificationService.authorizationStatus()
        guard status == .authorized else {
            logger.warning("Not authorized to schedule notifications, skipping")
            return
        }

        // Clear any existing notifications before scheduling fresh (prevents duplicates)
        notificationService.cancelAllNotifications()

        // Schedule 30 days of notifications upfront
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var scheduledCount = 0

        for dayOffset in 0 ..< 30 {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else {
                continue
            }

            let dateString = formatDateForIdentifier(targetDate)
            let (lunchComponents, eveningComponents) = notificationTiming(for: targetDate)

            // Schedule lunch notification (NOTIF-05, NOTIF-07)
            try await notificationService.scheduleNotification(
                identifier: "lunch-reminder-\(dateString)",
                title: Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "HealthTracker",
                body: String(localized: "notification_lunch"),
                dateComponents: lunchComponents,
                repeats: false
            )

            // Schedule evening notification (NOTIF-06, NOTIF-08)
            try await notificationService.scheduleNotification(
                identifier: "evening-reminder-\(dateString)",
                title: Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "HealthTracker",
                body: String(localized: "notification_evening"),
                dateComponents: eveningComponents,
                repeats: false
            )

            scheduledCount += 2
        }

        logger.info("Successfully scheduled \(scheduledCount) notifications")
    }

    // MARK: - Private Helpers

    /// Returns date components for lunch and evening notification timing for a specific date.
    ///
    /// Debug builds return testable times (2-3 minutes from now) for today's notifications.
    /// Future days use production times (1 PM, 8 PM). Release builds use production times for all days.
    ///
    /// - Parameter date: The target date for the notification
    /// - Returns: Tuple of (lunch, evening) DateComponents with full date (year, month, day, hour, minute)
    private func notificationTiming(for date: Date) -> (lunch: DateComponents, evening: DateComponents) {
        let calendar = Calendar.current

        #if DEBUG
            // Debug builds: testable times (NOTIF-23)
            // Use provided date with testable hour/minute
            let now = Date()
            let isToday = calendar.isDate(date, inSameDayAs: now)

            if isToday {
                // Today: 2-3 minutes from now for immediate testing
                let lunchDate = now.addingTimeInterval(120)
                let eveningDate = now.addingTimeInterval(180)

                let lunchComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: lunchDate)
                let eveningComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: eveningDate)

                return (lunchComponents, eveningComponents)
            } else {
                // Future days: use provided date with testable hours (13:00, 20:00)
                var lunchComponents = calendar.dateComponents([.year, .month, .day], from: date)
                lunchComponents.hour = 13
                lunchComponents.minute = 0

                var eveningComponents = calendar.dateComponents([.year, .month, .day], from: date)
                eveningComponents.hour = 20
                eveningComponents.minute = 0

                return (lunchComponents, eveningComponents)
            }
        #else
            // Release builds: production times (NOTIF-05, NOTIF-06)
            var lunchComponents = calendar.dateComponents([.year, .month, .day], from: date)
            lunchComponents.hour = 13
            lunchComponents.minute = 0

            var eveningComponents = calendar.dateComponents([.year, .month, .day], from: date)
            eveningComponents.hour = 20
            eveningComponents.minute = 0

            return (lunchComponents, eveningComponents)
        #endif
    }

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
