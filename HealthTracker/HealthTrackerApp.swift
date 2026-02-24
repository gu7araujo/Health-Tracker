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
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                MainView()
                    .tabItem {
                        Label("Hoje", systemImage: "calendar")
                    }

                AnalyticsView()
                    .tabItem {
                        Label("Gráficos", systemImage: "chart.xyaxis.line")
                    }
            }
        }
    }
}
