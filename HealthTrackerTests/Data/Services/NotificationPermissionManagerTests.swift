//
//  NotificationPermissionManagerTests.swift
//  HealthTrackerTests
//
//  Tests for NotificationPermissionManager: the first-launch permission flow, driven
//  through the injected flag store, notification service and logger fakes.
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct NotificationPermissionManagerTests {
    private enum TestError: Error {
        case boom
    }

    private let key = NotificationPermissionManager.hasRequestedKey

    private func run(flags: MockMigrationFlagStore, service: MockNotificationService) async {
        await NotificationPermissionManager.requestIfFirstLaunch(
            flags: flags,
            notificationService: service,
            logger: MockLogger()
        )
    }

    @Test("The flag key is unchanged, so existing users are not prompted again")
    func hasRequestedKey_matchesPersistedKey() {
        #expect(key == "hasRequestedNotificationPermission")
    }

    @Test("Skips the request when permission was already requested")
    func requestIfFirstLaunch_alreadyRequested_doesNotRequest() async {
        let flags = MockMigrationFlagStore(done: [key])
        let service = MockNotificationService()

        await run(flags: flags, service: service)

        #expect(!service.requestAuthorizationCalled)
        #expect(!service.scheduleNotificationCalled)
        #expect(flags.isDone(key))
    }

    @Test("Requests permission, schedules notifications and sets the flag when granted")
    func requestIfFirstLaunch_granted_schedulesAndMarksRequested() async {
        let flags = MockMigrationFlagStore()
        let service = MockNotificationService()
        service.requestAuthorizationResult = true
        service.authorizationStatusResult = .authorized

        await run(flags: flags, service: service)

        #expect(service.requestAuthorizationCalled)
        #expect(service.scheduleNotificationCalled)
        #expect(flags.isDone(key))
    }

    @Test("Sets the flag without scheduling when permission is denied")
    func requestIfFirstLaunch_denied_marksRequestedWithoutScheduling() async {
        let flags = MockMigrationFlagStore()
        let service = MockNotificationService()
        service.requestAuthorizationResult = false

        await run(flags: flags, service: service)

        #expect(service.requestAuthorizationCalled)
        #expect(!service.authorizationStatusCalled)
        #expect(!service.scheduleNotificationCalled)
        #expect(flags.isDone(key))
    }

    @Test("Sets the flag without scheduling when the permission request throws")
    func requestIfFirstLaunch_requestThrows_marksRequested() async {
        let flags = MockMigrationFlagStore()
        let service = MockNotificationService()
        service.requestAuthorizationError = TestError.boom

        await run(flags: flags, service: service)

        #expect(!service.scheduleNotificationCalled)
        #expect(flags.isDone(key))
    }

    @Test("Sets the flag when scheduling throws")
    func requestIfFirstLaunch_schedulingThrows_marksRequested() async {
        let flags = MockMigrationFlagStore()
        let service = MockNotificationService()
        service.authorizationStatusResult = .authorized
        service.scheduleNotificationError = TestError.boom

        await run(flags: flags, service: service)

        #expect(service.scheduleNotificationIdentifiers.count == 1)
        #expect(flags.isDone(key))
    }
}
