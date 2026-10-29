//
//  HealthTrackerAppTests.swift
//  HealthTrackerTests
//

@testable import HealthTracker
import Testing

@MainActor
struct HealthTrackerAppTests {
    @Test func startUp_migratesThenRequestsNotificationPermission() async {
        var steps: [String] = []

        await HealthTrackerApp.startUp(
            isTesting: false,
            migrate: { steps.append("migrate") },
            requestPermission: { steps.append("requestPermission") }
        )?.value

        #expect(steps == ["migrate", "requestPermission"])
    }

    @Test func startUp_whenTesting_skipsMigrationAndPermissionRequest() {
        var steps: [String] = []

        let task = HealthTrackerApp.startUp(
            isTesting: true,
            migrate: { steps.append("migrate") },
            requestPermission: { steps.append("requestPermission") }
        )

        #expect(task == nil)
        #expect(steps.isEmpty)
    }
}
