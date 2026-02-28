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
        mockService.authorizationStatusResult = .authorized

        let useCase = ScheduleNotificationsUseCase(notificationService: mockService)
        try await useCase.execute()

        // Verify scheduling was called
        #expect(mockService.scheduleNotificationCalled == true)

        // Verify both notifications scheduled (NOTIF-05, NOTIF-06)
        #expect(mockService.scheduleNotificationIdentifiers.count == 2)
        #expect(mockService.scheduleNotificationIdentifiers.contains("lunch-reminder"))
        #expect(mockService.scheduleNotificationIdentifiers.contains("evening-reminder"))

        // Verify repeats enabled for daily recurrence (NOTIF-10)
        #expect(mockService.scheduleNotificationRepeats.allSatisfy { $0 == true })

        // Verify Portuguese-BR messages present (NOTIF-07, NOTIF-08)
        #expect(mockService.scheduleNotificationBodies.contains("Registre o que você comeu hoje"))
        #expect(mockService.scheduleNotificationBodies.contains("Registre suas refeições e atividades"))
    }

    @Test func execute_cancelsExistingNotificationsBeforeScheduling() async throws {
        let mockService = MockNotificationService()
        mockService.authorizationStatusResult = .authorized

        let useCase = ScheduleNotificationsUseCase(notificationService: mockService)
        try await useCase.execute()

        // Verify cancellation called to prevent duplicates
        #expect(mockService.cancelAllNotificationsCalled == true)
    }

    @Test func execute_skipsSchedulingWhenNotAuthorized() async throws {
        let mockService = MockNotificationService()
        mockService.authorizationStatusResult = .denied

        let useCase = ScheduleNotificationsUseCase(notificationService: mockService)
        try await useCase.execute()

        // Verify no scheduling occurred (graceful degradation per NOTIF-03)
        #expect(mockService.scheduleNotificationCalled == false)
        // Verify no crash - test completes successfully
    }

    // MARK: - DateComponents Tests

    @Test func execute_schedulesWithDateComponents() async throws {
        let mockService = MockNotificationService()
        mockService.authorizationStatusResult = .authorized

        let useCase = ScheduleNotificationsUseCase(notificationService: mockService)
        try await useCase.execute()

        // Verify DateComponents used (NOTIF-09)
        #expect(mockService.scheduleNotificationDateComponents.count == 2)

        // Verify all components have hour and minute set (calendar-based timing)
        for component in mockService.scheduleNotificationDateComponents {
            #expect(component.hour != nil)
            #expect(component.minute != nil)
        }
    }

    // MARK: - Message Content Tests

    @Test func execute_usesPortugueseBRMessages() async throws {
        let mockService = MockNotificationService()
        mockService.authorizationStatusResult = .authorized

        let useCase = ScheduleNotificationsUseCase(notificationService: mockService)
        try await useCase.execute()

        // Verify exact Portuguese-BR messages (NOTIF-07, NOTIF-08)
        #expect(mockService.scheduleNotificationBodies.contains("Registre o que você comeu hoje"))
        #expect(mockService.scheduleNotificationBodies.contains("Registre suas refeições e atividades"))

        // Verify both messages scheduled
        #expect(mockService.scheduleNotificationBodies.count == 2)
    }

    @Test func execute_usesDynamicAppNameAsTitle() async throws {
        let mockService = MockNotificationService()
        mockService.authorizationStatusResult = .authorized

        let useCase = ScheduleNotificationsUseCase(notificationService: mockService)
        try await useCase.execute()

        let expectedTitle = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "HealthTracker"

        // Verify dynamic app name used as title for both notifications
        #expect(mockService.scheduleNotificationTitles.count == 2)
        #expect(mockService.scheduleNotificationTitles.allSatisfy { $0 == expectedTitle })
    }

    // MARK: - Edge Cases

    @Test func execute_handlesNotDeterminedStatus() async throws {
        let mockService = MockNotificationService()
        mockService.authorizationStatusResult = .notDetermined

        let useCase = ScheduleNotificationsUseCase(notificationService: mockService)
        try await useCase.execute()

        // Verify graceful degradation - no scheduling when not determined
        #expect(mockService.scheduleNotificationCalled == false)
    }

    @Test func execute_handlesProvisionalStatus() async throws {
        let mockService = MockNotificationService()
        mockService.authorizationStatusResult = .provisional

        let useCase = ScheduleNotificationsUseCase(notificationService: mockService)
        try await useCase.execute()

        // Verify graceful degradation - no scheduling when provisional
        #expect(mockService.scheduleNotificationCalled == false)
    }
}
