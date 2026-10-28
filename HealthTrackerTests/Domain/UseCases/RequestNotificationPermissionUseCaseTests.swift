//
//  RequestNotificationPermissionUseCaseTests.swift
//  HealthTrackerTests
//
//  Created by Gustavo Araujo Santos on 02/28/26.
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct RequestNotifPermissionUseCaseTests { // "Notif": type_name caps type names at 40 characters
    // MARK: - Execute (Permission Request) Tests

    @Test func execute_requestsPermissionWithCorrectOptions() async throws {
        let mockService = MockNotificationService()
        let mockLogger = MockLogger()
        mockService.requestAuthorizationResult = true

        let useCase = RequestNotificationPermissionUseCase(notificationService: mockService, logger: mockLogger)
        let granted = try await useCase.execute()

        #expect(mockService.requestAuthorizationCalled == true)
        #expect(mockService.requestAuthorizationOptionsUsed?.contains(.alert) == true)
        #expect(mockService.requestAuthorizationOptionsUsed?.contains(.sound) == true)
        #expect(mockService.requestAuthorizationOptionsUsed?.contains(.badge) == true)
        #expect(granted == true)
    }

    @Test func execute_handlesPermissionDenial() async throws {
        let mockService = MockNotificationService()
        let mockLogger = MockLogger()
        mockService.requestAuthorizationResult = false

        let useCase = RequestNotificationPermissionUseCase(notificationService: mockService, logger: mockLogger)
        let granted = try await useCase.execute()

        #expect(granted == false)
        // Verify no crash - graceful handling per NOTIF-03
    }

    // MARK: - Authorization Status Tests

    @Test func isAuthorized_returnsTrueWhenAuthorized() async {
        let mockService = MockNotificationService()
        let mockLogger = MockLogger()
        mockService.authorizationStatusResult = .authorized

        let useCase = RequestNotificationPermissionUseCase(notificationService: mockService, logger: mockLogger)
        let authorized = await useCase.isAuthorized()

        #expect(mockService.authorizationStatusCalled == true)
        #expect(authorized == true)
    }

    @Test func isAuthorized_returnsFalseWhenDenied() async {
        let mockService = MockNotificationService()
        let mockLogger = MockLogger()
        mockService.authorizationStatusResult = .denied

        let useCase = RequestNotificationPermissionUseCase(notificationService: mockService, logger: mockLogger)
        let authorized = await useCase.isAuthorized()

        #expect(mockService.authorizationStatusCalled == true)
        #expect(authorized == false)
    }

    @Test func isAuthorized_returnsFalseWhenNotDetermined() async {
        let mockService = MockNotificationService()
        let mockLogger = MockLogger()
        mockService.authorizationStatusResult = .notDetermined

        let useCase = RequestNotificationPermissionUseCase(notificationService: mockService, logger: mockLogger)
        let authorized = await useCase.isAuthorized()

        #expect(mockService.authorizationStatusCalled == true)
        #expect(authorized == false)
    }

    @Test func isAuthorized_returnsFalseWhenProvisional() async {
        let mockService = MockNotificationService()
        let mockLogger = MockLogger()
        mockService.authorizationStatusResult = .provisional

        let useCase = RequestNotificationPermissionUseCase(notificationService: mockService, logger: mockLogger)
        let authorized = await useCase.isAuthorized()

        #expect(mockService.authorizationStatusCalled == true)
        #expect(authorized == false)
    }
}
