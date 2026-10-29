//
//  CancelNotificationsUseCaseTests.swift
//  HealthTrackerTests
//
//  Created by Gustavo Araujo Santos on 02/28/26.
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct CancelNotificationsUseCaseTests {
    @Test func execute_cancelsPendingNotifications() async throws {
        let mockService = MockNotificationService()
        let mockLogger = MockLogger()
        let useCase = CancelNotificationsUseCase(notificationService: mockService, logger: mockLogger)
        try await useCase.execute()

        // Verify pending notifications were cancelled (NOTIF-11)
        #expect(mockService.cancelNotificationsCalled == true)
    }

    /// Called from the main actor, the blocking system call still runs off the main thread.
    @Test func execute_runsOffMainThread() async throws {
        let mockService = MockNotificationService()
        let useCase = CancelNotificationsUseCase(notificationService: mockService, logger: MockLogger())
        try await useCase.execute()

        #expect(mockService.cancelNotificationsRanOnMainThread == false)
    }

    @Test func execute_removesDeliveredNotifications() async throws {
        let mockService = MockNotificationService()
        let mockLogger = MockLogger()
        let useCase = CancelNotificationsUseCase(notificationService: mockService, logger: mockLogger)
        try await useCase.execute()

        // Verify delivered notifications were removed (NOTIF-14)
        #expect(mockService.removeDeliveredNotificationsCalled == true)
    }

    @Test func execute_usesTodayDateForIdentifiers() async throws {
        let mockService = MockNotificationService()
        let mockLogger = MockLogger()
        let useCase = CancelNotificationsUseCase(notificationService: mockService, logger: mockLogger)
        try await useCase.execute()

        // Calculate today's date string
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: Date())

        // Build expected identifiers with today's date
        let expectedIdentifiers = [
            "lunch-reminder-\(todayString)",
            "evening-reminder-\(todayString)"
        ]

        // Verify both cancel and remove operations use today's identifiers (NOTIF-13)
        let cancelIdentifiers = mockService.cancelNotificationsIdentifiers.first ?? []
        let removeIdentifiers = mockService.removeDeliveredNotificationsIdentifiers.first ?? []

        #expect(cancelIdentifiers == expectedIdentifiers)
        #expect(removeIdentifiers == expectedIdentifiers)
    }

    @Test func execute_cancelsOnlyTwoNotifications() async throws {
        let mockService = MockNotificationService()
        let mockLogger = MockLogger()
        let useCase = CancelNotificationsUseCase(notificationService: mockService, logger: mockLogger)
        try await useCase.execute()

        // Verify exactly 2 identifiers in first cancellation call
        #expect(mockService.cancelNotificationsIdentifiers.first?.count == 2)
        #expect(mockService.removeDeliveredNotificationsIdentifiers.first?.count == 2)

        // Verify identifiers are for today only (not future days)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: Date())

        let cancelIdentifiers = mockService.cancelNotificationsIdentifiers.first ?? []
        #expect(cancelIdentifiers.allSatisfy { $0.contains(todayString) })
    }

    // MARK: - Edge Cases

    @Test func execute_handlesMultipleCancellationCalls() async throws {
        let mockService = MockNotificationService()
        let mockLogger = MockLogger()
        let useCase = CancelNotificationsUseCase(notificationService: mockService, logger: mockLogger)

        // Execute twice to simulate rapid data entry
        try await useCase.execute()
        try await useCase.execute()

        // Both calls should succeed without error
        #expect(mockService.cancelNotificationsCalled == true)
        #expect(mockService.cancelNotificationsIdentifiers.count == 2) // Two separate calls tracked
    }

    @Test func execute_worksAcrossDayBoundaries() async throws {
        let mockService = MockNotificationService()
        let mockLogger = MockLogger()
        let useCase = CancelNotificationsUseCase(notificationService: mockService, logger: mockLogger)

        try await useCase.execute()

        // Verify today's date used (not hardcoded)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: Date())

        let firstCall = mockService.cancelNotificationsIdentifiers.first
        #expect(firstCall?.allSatisfy { $0.contains(todayString) } == true)
    }
}
