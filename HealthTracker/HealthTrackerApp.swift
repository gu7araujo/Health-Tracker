//
//  HealthTrackerApp.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/18/25.
//

import SwiftUI

@main
struct HealthTrackerApp: App {
    init() {
        // Skip migration and the system permission alert when running under UI or unit tests
        Self.startUp(
            isTesting: UITestingSupport.isActive || UITestingSupport.isHostingUnitTests,
            migrate: DataMigration.migrateIfNeeded,
            requestPermission: { await NotificationPermissionManager.requestIfFirstLaunch() }
        )
    }

    /// Production startup: runs data migrations, then requests notification permission on first launch.
    /// Does nothing when `isTesting`; returns the permission request's task otherwise.
    @discardableResult
    static func startUp(
        isTesting: Bool,
        migrate: () -> Void,
        requestPermission: @escaping () async -> Void
    ) -> Task<Void, Never>? {
        guard !isTesting else { return nil }
        migrate()
        return Task { await requestPermission() }
    }

    var body: some Scene {
        WindowGroup {
            // The unit-test host shows no UI, so it never wires the production repository
            if !UITestingSupport.isHostingUnitTests {
                MainView()
            }
        }
    }
}
