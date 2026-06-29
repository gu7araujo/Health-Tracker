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
