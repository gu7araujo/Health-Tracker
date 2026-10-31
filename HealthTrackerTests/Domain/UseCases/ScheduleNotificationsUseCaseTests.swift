//
//  ScheduleNotificationsUseCaseTests.swift
//  HealthTrackerTests
//
//  Created by Gustavo Araujo Santos on 02/28/26.
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct ScheduleNotificationsUseCaseTests {
    // MARK: - Authorization and Scheduling Tests

    @Test func execute_schedulesBothNotificationsWhenAuthorized() async throws {
        let mockService = MockNotificationService()
        let mockLogger = MockLogger()
        mockService.authorizationStatusResult = .authorized

        let useCase = ScheduleNotificationsUseCase(notificationService: mockService, logger: mockLogger)
        try await useCase.execute()

        // Verify scheduling was called
        #expect(mockService.scheduleNotificationCalled == true)

        // Verify 60 notifications scheduled (30 days × 2 notification types) (NOTIF-05, NOTIF-06)
        #expect(mockService.scheduleNotificationIdentifiers.count == 60)

        // Verify repeats disabled for per-day cancellation (NOTIF-10)
        #expect(mockService.scheduleNotificationRepeats.allSatisfy { $0 == false })

        // Verify localized messages present (NOTIF-07, NOTIF-08)
        #expect(mockService.scheduleNotificationBodies.contains(NSLocalizedString("notification_lunch", comment: "")))
        #expect(mockService.scheduleNotificationBodies.contains(NSLocalizedString("notification_evening", comment: "")))
    }

    @Test func execute_cancelsExistingNotificationsBeforeScheduling() async throws {
        let mockService = MockNotificationService()
        let mockLogger = MockLogger()
        mockService.authorizationStatusResult = .authorized

        let useCase = ScheduleNotificationsUseCase(notificationService: mockService, logger: mockLogger)
        try await useCase.execute()

        // Verify cancellation called to prevent duplicates
        #expect(mockService.cancelAllNotificationsCalled == true)
    }

    /// Called from the main actor, the blocking clear-all system call still runs off the main thread.
    @Test func execute_cancelsAllOffMainThread() async throws {
        let mockService = MockNotificationService()
        mockService.authorizationStatusResult = .authorized

        let useCase = ScheduleNotificationsUseCase(notificationService: mockService, logger: MockLogger())
        try await useCase.execute()

        #expect(mockService.cancelAllNotificationsRanOnMainThread == false)
    }

    @Test func execute_skipsSchedulingWhenNotAuthorized() async throws {
        let mockService = MockNotificationService()
        let mockLogger = MockLogger()
        mockService.authorizationStatusResult = .denied

        let useCase = ScheduleNotificationsUseCase(notificationService: mockService, logger: mockLogger)
        try await useCase.execute()

        // Verify no scheduling occurred (graceful degradation per NOTIF-03)
        #expect(mockService.scheduleNotificationCalled == false)
        // Verify no crash - test completes successfully
    }

    // MARK: - DateComponents Tests

    @Test func execute_schedulesWithDateComponents() async throws {
        let mockService = MockNotificationService()
        let mockLogger = MockLogger()
        mockService.authorizationStatusResult = .authorized

        let useCase = ScheduleNotificationsUseCase(notificationService: mockService, logger: mockLogger)
        try await useCase.execute()

        // Verify DateComponents used (NOTIF-09)
        #expect(mockService.scheduleNotificationDateComponents.count == 60)

        // Verify all components have hour and minute set (calendar-based timing)
        for component in mockService.scheduleNotificationDateComponents {
            #expect(component.hour != nil)
            #expect(component.minute != nil)
        }
    }

    // MARK: - Message Content Tests

    @Test func execute_usesPortugueseBRMessages() async throws {
        let mockService = MockNotificationService()
        let mockLogger = MockLogger()
        mockService.authorizationStatusResult = .authorized

        let useCase = ScheduleNotificationsUseCase(notificationService: mockService, logger: mockLogger)
        try await useCase.execute()

        // Verify exact localized messages (NOTIF-07, NOTIF-08)
        #expect(mockService.scheduleNotificationBodies.contains(NSLocalizedString("notification_lunch", comment: "")))
        #expect(mockService.scheduleNotificationBodies.contains(NSLocalizedString("notification_evening", comment: "")))

        // Verify 60 messages scheduled (30 days × 2 notification types)
        #expect(mockService.scheduleNotificationBodies.count == 60)
    }

    @Test func execute_usesAppNameAsTitle() async throws {
        let mockService = MockNotificationService()
        mockService.authorizationStatusResult = .authorized

        let useCase = ScheduleNotificationsUseCase(
            notificationService: mockService,
            logger: MockLogger(),
            appName: "Clune"
        )
        try await useCase.execute()

        #expect(mockService.scheduleNotificationTitles.count == 60)
        #expect(mockService.scheduleNotificationTitles.allSatisfy { $0 == "Clune" })
    }

    @Test func execute_fallsBackToAppTitleWhenAppNameIsMissing() async throws {
        let mockService = MockNotificationService()
        mockService.authorizationStatusResult = .authorized

        let useCase = ScheduleNotificationsUseCase(
            notificationService: mockService,
            logger: MockLogger(),
            appName: nil
        )
        try await useCase.execute()

        #expect(mockService.scheduleNotificationTitles.count == 60)
        #expect(mockService.scheduleNotificationTitles.allSatisfy { $0 == String(localized: "app_title") })
    }

    // MARK: - Edge Cases

    @Test func execute_handlesNotDeterminedStatus() async throws {
        let mockService = MockNotificationService()
        let mockLogger = MockLogger()
        mockService.authorizationStatusResult = .notDetermined

        let useCase = ScheduleNotificationsUseCase(notificationService: mockService, logger: mockLogger)
        try await useCase.execute()

        // Verify graceful degradation - no scheduling when not determined
        #expect(mockService.scheduleNotificationCalled == false)
    }

    @Test func execute_handlesProvisionalStatus() async throws {
        let mockService = MockNotificationService()
        let mockLogger = MockLogger()
        mockService.authorizationStatusResult = .provisional

        let useCase = ScheduleNotificationsUseCase(notificationService: mockService, logger: mockLogger)
        try await useCase.execute()

        // Verify graceful degradation - no scheduling when provisional
        #expect(mockService.scheduleNotificationCalled == false)
    }

    // MARK: - Date-Specific Scheduling Tests

    @Test func execute_schedulesThirtyDaysOfNotifications() async throws {
        let mockService = MockNotificationService()
        let mockLogger = MockLogger()
        mockService.authorizationStatusResult = .authorized
        let useCase = ScheduleNotificationsUseCase(notificationService: mockService, logger: mockLogger)

        try await useCase.execute()

        // Verify 60 notifications scheduled (30 days × 2 notification types) (NOTIF-05, NOTIF-06)
        #expect(mockService.scheduleNotificationIdentifiers.count == 60)
    }

    @Test func execute_usesDateSpecificIdentifiers() async throws {
        let mockService = MockNotificationService()
        let mockLogger = MockLogger()
        mockService.authorizationStatusResult = .authorized
        let useCase = ScheduleNotificationsUseCase(notificationService: mockService, logger: mockLogger)

        try await useCase.execute()

        // Split identifiers into lunch and evening groups
        let identifiers = mockService.scheduleNotificationIdentifiers
        let lunchIdentifiers = identifiers.filter { $0.contains("lunch-reminder-") }
        let eveningIdentifiers = identifiers.filter { $0.contains("evening-reminder-") }

        // Verify 30 lunch and 30 evening identifiers
        #expect(lunchIdentifiers.count == 30)
        #expect(eveningIdentifiers.count == 30)

        // Verify date portion has valid format (5 components: ["lunch", "reminder", "YYYY", "MM", "DD"])
        for identifier in identifiers {
            let components = identifier.split(separator: "-")
            #expect(components.count == 5) // e.g., "lunch-reminder-2026-03-01"

            // Verify year has 4 digits, month has 2 digits, day has 2 digits
            let year = String(components[2])
            let month = String(components[3])
            let day = String(components[4])
            #expect(year.count == 4)
            #expect(month.count == 2)
            #expect(day.count == 2)
        }
    }

    @Test func execute_schedulesNonRepeatingNotifications() async throws {
        let mockService = MockNotificationService()
        let mockLogger = MockLogger()
        mockService.authorizationStatusResult = .authorized
        let useCase = ScheduleNotificationsUseCase(notificationService: mockService, logger: mockLogger)

        try await useCase.execute()

        // Verify all 60 notifications have repeats: false
        #expect(mockService.scheduleNotificationRepeats.count == 60)
        #expect(mockService.scheduleNotificationRepeats.allSatisfy { $0 == false })
    }

    @Test func execute_schedulesFullDateComponents() async throws {
        let mockService = MockNotificationService()
        let mockLogger = MockLogger()
        mockService.authorizationStatusResult = .authorized
        let useCase = ScheduleNotificationsUseCase(notificationService: mockService, logger: mockLogger)

        try await useCase.execute()

        // Verify each DateComponent has year, month, day, hour, minute set
        #expect(mockService.scheduleNotificationDateComponents.count == 60)
        for component in mockService.scheduleNotificationDateComponents {
            #expect(component.year != nil)
            #expect(component.month != nil)
            #expect(component.day != nil)
            #expect(component.hour != nil)
            #expect(component.minute != nil)
        }
    }
}
