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
        guard !UITestingSupport.isActive, !UITestingSupport.isHostingUnitTests else { return }

        DataMigration.migrateIfNeeded()

        // Request notification permission on first launch
        Task {
            await NotificationPermissionManager.requestIfFirstLaunch()
        }
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
