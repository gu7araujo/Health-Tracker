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

    init(notificationService: NotificationServiceProtocol) {
        self.notificationService = notificationService
    }

    /// Schedules both daily notifications (lunch and evening reminders).
    ///
    /// Checks authorization status before scheduling. If not authorized, returns
    /// gracefully without throwing (satisfies NOTIF-03 graceful degradation).
    ///
    /// Debug builds use testable times (2-3 minutes from now) for quick verification.
    /// Release builds use production times (1 PM, 8 PM).
    ///
    /// - Throws: An error if scheduling fails (e.g., system error)
    func execute() async throws {
        // Check authorization (NOTIF-02)
        let status = await notificationService.authorizationStatus()
        guard status == .authorized else {
            print("[ScheduleNotifications] Not authorized, skipping scheduling")
            return
        }

        // Clear any existing notifications before scheduling fresh (prevents duplicates)
        notificationService.cancelAllNotifications()

        // Determine timing based on build configuration
        let (lunchComponents, eveningComponents) = notificationTiming()

        // Schedule lunch notification (NOTIF-05, NOTIF-07)
        try await notificationService.scheduleNotification(
            identifier: "lunch-reminder",
            title: Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "HealthTracker",
            body: "Registre o que você comeu hoje",
            dateComponents: lunchComponents,
            repeats: true
        )

        // Schedule evening notification (NOTIF-06, NOTIF-08)
        try await notificationService.scheduleNotification(
            identifier: "evening-reminder",
            title: Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "HealthTracker",
            body: "Registre suas refeições e atividades",
            dateComponents: eveningComponents,
            repeats: true
        )

        print("[ScheduleNotifications] Notifications scheduled successfully")
    }

    // MARK: - Private Helpers

    /// Returns date components for lunch and evening notification timing.
    ///
    /// Debug builds return testable times (2-3 minutes from now) for quick verification.
    /// Release builds return production times (1 PM, 8 PM).
    ///
    /// - Returns: Tuple of (lunch, evening) DateComponents
    private func notificationTiming() -> (lunch: DateComponents, evening: DateComponents) {
        #if DEBUG
            // Debug builds: testable times (NOTIF-23)
            let now = Date()
            let lunchDate = now.addingTimeInterval(120) // 2 minutes from now
            let eveningDate = now.addingTimeInterval(180) // 3 minutes from now

            let calendar = Calendar.current
            let lunchComponents = calendar.dateComponents([.hour, .minute], from: lunchDate)
            let eveningComponents = calendar.dateComponents([.hour, .minute], from: eveningDate)

            return (lunchComponents, eveningComponents)
        #else
            // Release builds: production times (NOTIF-05, NOTIF-06)
            let lunchComponents = DateComponents(hour: 13, minute: 0) // 1 PM
            let eveningComponents = DateComponents(hour: 20, minute: 0) // 8 PM

            return (lunchComponents, eveningComponents)
        #endif
    }
}
