//
//  NotificationServiceTests.swift
//  HealthTrackerTests
//
//  Tests for NotificationService: the UNKit bridging (option/status mapping),
//  scheduling, cancellation, delegate wiring, and error propagation, driven
//  through the injected UserNotificationCentering fake.
//

import Foundation
@testable import HealthTracker
import Testing
import UserNotifications

@MainActor
struct NotificationServiceTests {
    private enum TestError: Error {
        case boom
    }

    private final class DummyDelegate: NotificationCenterDelegate {}

    private func makeService(
        center: MockUserNotificationCenter? = nil,
        logger: MockLogger? = nil
    ) -> NotificationService {
        NotificationService(
            notificationCenter: center ?? MockUserNotificationCenter(),
            logger: logger ?? MockLogger()
        )
    }

    private func tag(_ status: NotificationAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: "notDetermined"
        case .denied: "denied"
        case .authorized: "authorized"
        case .provisional: "provisional"
        case .ephemeral: "ephemeral"
        }
    }

    // MARK: - requestAuthorization

    @Test("Maps domain options to UN options and returns the granted result")
    func requestAuthorization_mapsOptionsAndReturnsGranted() async throws {
        let center = MockUserNotificationCenter()
        center.requestAuthorizationResult = true
        let service = makeService(center: center)

        let granted = try await service.requestAuthorization(options: [.alert, .sound, .badge])

        #expect(granted)
        #expect(center.requestAuthorizationOptions == [.alert, .sound, .badge])
    }

    @Test("Maps only the requested option subset")
    func requestAuthorization_mapsPartialOptions() async throws {
        let center = MockUserNotificationCenter()
        let service = makeService(center: center)

        _ = try await service.requestAuthorization(options: [.alert])

        #expect(center.requestAuthorizationOptions == [.alert])
    }

    @Test("Returns false when authorization is denied")
    func requestAuthorization_returnsFalseWhenDenied() async throws {
        let center = MockUserNotificationCenter()
        center.requestAuthorizationResult = false
        let service = makeService(center: center)

        let granted = try await service.requestAuthorization(options: [.alert])

        #expect(!granted)
    }

    @Test("Propagates errors thrown by the notification center")
    func requestAuthorization_propagatesError() async {
        let center = MockUserNotificationCenter()
        center.requestAuthorizationError = TestError.boom
        let service = makeService(center: center)

        await #expect(throws: TestError.self) {
            _ = try await service.requestAuthorization(options: [.alert])
        }
    }

    // MARK: - authorizationStatus

    @Test("Maps every UN authorization status to its domain counterpart", arguments: [
        (UNAuthorizationStatus.notDetermined, "notDetermined"),
        (.denied, "denied"),
        (.authorized, "authorized"),
        (.provisional, "provisional"),
        (.ephemeral, "ephemeral")
    ])
    func authorizationStatus_mapsUNStatusToDomain(unStatus: UNAuthorizationStatus, expected: String) async {
        let center = MockUserNotificationCenter()
        center.authorizationStatusResult = unStatus
        let service = makeService(center: center)

        let status = await service.authorizationStatus()

        #expect(tag(status) == expected)
    }

    // MARK: - scheduleNotification

    @Test("Builds a calendar-triggered request with the given content and timing")
    func scheduleNotification_buildsRequest() async throws {
        let center = MockUserNotificationCenter()
        let service = makeService(center: center)
        var components = DateComponents()
        components.hour = 13
        components.minute = 0

        try await service.scheduleNotification(
            identifier: "lunch-reminder",
            title: "Lunch",
            body: "Time to log lunch",
            dateComponents: components,
            repeats: true
        )

        #expect(center.addedRequests.count == 1)
        let request = try #require(center.addedRequests.first)
        #expect(request.identifier == "lunch-reminder")
        #expect(request.content.title == "Lunch")
        #expect(request.content.body == "Time to log lunch")
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        #expect(trigger.repeats)
        #expect(trigger.dateComponents.hour == 13)
        #expect(trigger.dateComponents.minute == 0)
    }

    @Test("Propagates errors thrown while adding a request")
    func scheduleNotification_propagatesError() async {
        let center = MockUserNotificationCenter()
        center.addError = TestError.boom
        let service = makeService(center: center)

        await #expect(throws: TestError.self) {
            try await service.scheduleNotification(
                identifier: "id",
                title: "T",
                body: "B",
                dateComponents: DateComponents(hour: 20),
                repeats: false
            )
        }
    }

    // MARK: - Cancellation

    @Test("cancelAllNotifications removes all pending requests")
    func cancelAllNotifications_delegatesToCenter() {
        let center = MockUserNotificationCenter()
        let service = makeService(center: center)

        service.cancelAllNotifications()

        #expect(center.removeAllPendingCalled)
    }

    @Test("cancelNotifications forwards the identifiers")
    func cancelNotifications_delegatesToCenter() {
        let center = MockUserNotificationCenter()
        let service = makeService(center: center)

        service.cancelNotifications(withIdentifiers: ["a", "b"])

        #expect(center.removedPendingIdentifiers == [["a", "b"]])
    }

    @Test("removeDeliveredNotifications forwards the identifiers")
    func removeDeliveredNotifications_delegatesToCenter() {
        let center = MockUserNotificationCenter()
        let service = makeService(center: center)

        service.removeDeliveredNotifications(withIdentifiers: ["x"])

        #expect(center.removedDeliveredIdentifiers == [["x"]])
    }

    // MARK: - setDelegate

    @Test("Logs distinct messages for setting and removing the delegate")
    func setDelegate_logsBothBranches() {
        let logger = MockLogger()
        let service = makeService(logger: logger)

        service.setDelegate(DummyDelegate())
        #expect(logger.didLog(level: .debug, containing: "Delegate set"))

        service.setDelegate(nil)
        #expect(logger.didLog(level: .debug, containing: "Delegate removed"))
    }
}
