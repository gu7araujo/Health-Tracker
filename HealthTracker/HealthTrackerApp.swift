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
        // Skip migration and the system permission alert when running under UI tests
        guard !UITestingSupport.isActive else { return }

        DataMigration.migrateIfNeeded()

        // Request notification permission on first launch
        Task {
            await NotificationPermissionManager.requestIfFirstLaunch()
        }
    }

    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
