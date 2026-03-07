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
            TabView {
                MainView()
                    .tabItem {
                        Label(String(localized: "tab_today"), systemImage: "calendar")
                    }

                AnalyticsView()
                    .tabItem {
                        Label(String(localized: "tab_analytics"), systemImage: "chart.xyaxis.line")
                    }
            }
        }
    }
}
