//
//  DataMigration.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 02/07/26.
//

import Foundation

/// Handles one-time data migration from UserDefaults to iCloud Drive.
/// Checks a migration flag to ensure the migration runs only once.
enum DataMigration {
    private static let migrationKey = "iCloudMigrationCompleted"

    /// Migrates existing data from UserDefaults to iCloud Drive if not already done.
    /// - Safe to call multiple times; only runs the actual migration once.
    /// - Empty day entries are automatically filtered out during the load (via `RecordedDayData` parsing).
    /// - Cleans up old UserDefaults data after successful migration.
    static func migrateIfNeeded() {
        let userDefaults = UserDefaults.standard

        guard !userDefaults.bool(forKey: migrationKey) else {
            return
        }

        let oldDataSource = UserDefaultsDataSource()
        let existingData = oldDataSource.load()

        // Only migrate if there's actual data to move
        guard !existingData.isEmpty else {
            userDefaults.set(true, forKey: migrationKey)
            return
        }

        let newDataSource = ICloudDriveDataSource()
        newDataSource.save(existingData)

        // Clean up old UserDefaults data
        userDefaults.removeObject(forKey: "store")
        userDefaults.set(true, forKey: migrationKey)

        #if DEBUG
            print("DataMigration: Successfully migrated \(existingData.count) day(s) to iCloud Drive")
        #endif
    }
}
