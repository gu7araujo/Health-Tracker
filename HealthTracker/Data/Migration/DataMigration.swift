//
//  DataMigration.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 02/07/26.
//

import Foundation

/// Handles one-time data migrations.
/// Checks migration flags to ensure each migration runs only once.
enum DataMigration {
    private static let iCloudMigrationKey = "iCloudMigrationCompleted"
    private static let durationMigrationKey = "workoutDurationMigrationCompleted"

    /// Runs all necessary migrations in sequence.
    /// Safe to call multiple times; each migration checks its own completion flag.
    static func migrateIfNeeded() {
        migrateToICloudDrive()
        migrateWorkoutDurations()
    }

    /// Migrates existing data from UserDefaults to iCloud Drive if not already done.
    /// - Safe to call multiple times; only runs the actual migration once.
    /// - Empty day entries are automatically filtered out during the load (via `RecordedDayData` parsing).
    /// - Cleans up old UserDefaults data after successful migration.
    private static func migrateToICloudDrive() {
        let userDefaults = UserDefaults.standard

        guard !userDefaults.bool(forKey: iCloudMigrationKey) else {
            return
        }

        let oldDataSource = UserDefaultsDataSource()
        let existingData = oldDataSource.load()

        // Only migrate if there's actual data to move
        guard !existingData.isEmpty else {
            userDefaults.set(true, forKey: iCloudMigrationKey)
            return
        }

        let newDataSource = ICloudDriveDataSource()
        newDataSource.save(existingData)

        // Clean up old UserDefaults data
        userDefaults.removeObject(forKey: "store")
        userDefaults.set(true, forKey: iCloudMigrationKey)

        #if DEBUG
            print("DataMigration: Successfully migrated \(existingData.count) day(s) to iCloud Drive")
        #endif
    }

    /// Migrates workout durations from old format to new format on disk.
    /// - Old format stored as single integers (enum raw values 0-6)
    /// - New format stores as {"minutes": X} dictionary
    /// - The Codable implementation automatically converts on load, this migration re-saves in new format
    /// - Safe to call multiple times; only runs once (controlled by flag)
    private static func migrateWorkoutDurations() {
        let userDefaults = UserDefaults.standard

        guard !userDefaults.bool(forKey: durationMigrationKey) else {
            #if DEBUG
                print("DataMigration: Workout duration migration already completed, skipping")
            #endif
            return
        }

        #if DEBUG
            print("DataMigration: Starting workout duration migration...")
        #endif

        let dataSource = ICloudDriveDataSource()
        let allRecordedDays = dataSource.load() // Codable automatically converts old format on load

        #if DEBUG
            // Count workouts that were likely converted from old format
            var convertedCount = 0
            for recordedDay in allRecordedDays {
                for workout in recordedDay.dayData.workouts {
                    // These minute values indicate they were converted from old enum values
                    if [10, 15, 30, 40, 60, 90, 120].contains(workout.duration.minutes) {
                        print("  - Loaded (auto-converted): '\(workout.description)' = \(workout.duration.minutes)min")
                        convertedCount += 1
                    }
                }
            }
            if convertedCount > 0 {
                print("DataMigration: Auto-converted \(convertedCount) workout(s) during load")
            }
        #endif

        // Re-save all data to persist the new format to disk
        // This ensures the JSON file is updated from old format (integers) to new format ({"minutes": X})
        if !allRecordedDays.isEmpty {
            dataSource.save(allRecordedDays)
            #if DEBUG
                print("DataMigration: Re-saved \(allRecordedDays.count) day(s) with new duration format")
            #endif
        } else {
            #if DEBUG
                print("DataMigration: No data to migrate")
            #endif
        }

        userDefaults.set(true, forKey: durationMigrationKey)
    }

    #if DEBUG
        /// Creates test data with old enum values (0-6) for migration testing.
        /// ⚠️ This will reset the migration flag and create workouts with values 0-6.
        /// Use this to test that the migration correctly converts to actual minutes.
        static func createMigrationTestData() {
            let userDefaults = UserDefaults.standard
            // Reset migration flag to allow re-running
            userDefaults.set(false, forKey: durationMigrationKey)

            let dataSource = ICloudDriveDataSource()
            let testDays = [
                DayData(
                    date: Date(),
                    meals: [],
                    workouts: [
                        Workout(description: "Test 0→15min", duration: Workout.Duration(minutes: 0)),
                        Workout(description: "Test 1→30min", duration: Workout.Duration(minutes: 1)),
                        Workout(description: "Test 2→60min", duration: Workout.Duration(minutes: 2)),
                        Workout(description: "Test 3→90min", duration: Workout.Duration(minutes: 3)),
                        Workout(description: "Test 4→10min", duration: Workout.Duration(minutes: 4)),
                        Workout(description: "Test 5→40min", duration: Workout.Duration(minutes: 5)),
                        Workout(description: "Test 6→120min", duration: Workout.Duration(minutes: 6))
                    ],
                    water: nil,
                    mood: nil
                )
            ]
            let recordedDays = testDays.compactMap(RecordedDayData.init)
            dataSource.save(recordedDays)

            print("DataMigration: Created test data with old enum values (0-6)")
            print("  Next app launch will migrate these to actual minutes")
        }
    #endif
}
