//
//  DataMigration.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 02/07/26.
//

import Foundation

/// Abstraction over the small key/value flags that gate each one-time migration, plus the
/// legacy `UserDefaults` "store" cleanup. Lets `DataMigration` run against an in-memory
/// store in tests instead of the real `UserDefaults`.
protocol MigrationFlagStore {
    func isDone(_ key: String) -> Bool
    func markDone(_ key: String)
    /// Removes the legacy `UserDefaults` blob once its data has been migrated to iCloud.
    func clearLegacyStore()
}

extension UserDefaults: MigrationFlagStore {
    func isDone(_ key: String) -> Bool {
        bool(forKey: key)
    }

    func markDone(_ key: String) {
        set(true, forKey: key)
    }

    func clearLegacyStore() {
        removeObject(forKey: "store")
    }
}

/// Handles one-time data migrations.
/// Checks migration flags to ensure each migration runs only once.
///
/// Dependencies are injected so the flag-gated branches can be unit-tested with in-memory
/// fakes; `migrateIfNeeded()` wires the production defaults and is the app's entry point.
struct DataMigration {
    static let iCloudMigrationKey = "iCloudMigrationCompleted"
    static let durationMigrationKey = "workoutDurationMigrationCompleted"
    static let mealItemsMigrationKey = "mealItemsMigrationCompleted"
    static let workoutIntensityMigrationKey = "workoutIntensityMigrationCompleted"

    private let legacySource: LocalDataSourceProtocol
    private let cloudSource: LocalDataSourceProtocol
    private let flags: MigrationFlagStore
    private let backUp: () -> Bool
    private let logger: LoggerProtocol

    init(
        legacySource: LocalDataSourceProtocol = UserDefaultsDataSource(),
        cloudSource: LocalDataSourceProtocol = ICloudDriveDataSource(),
        flags: MigrationFlagStore = UserDefaults.standard,
        backUp: @escaping () -> Bool = { ICloudDriveDataSource().backUpDataFile() },
        logger: LoggerProtocol = LoggerFactory.dataLogger(category: "Data.Migration")
    ) {
        self.legacySource = legacySource
        self.cloudSource = cloudSource
        self.flags = flags
        self.backUp = backUp
        self.logger = logger
    }

    /// App entry point: runs all migrations with production dependencies.
    static func migrateIfNeeded() {
        DataMigration().run()
    }

    /// Runs all necessary migrations in sequence.
    /// Safe to call multiple times; each migration checks its own completion flag.
    /// Before any pending file-rewriting migration, takes a raw-bytes backup of the
    /// data file so the pre-migration state is always recoverable; if the backup
    /// fails, file migrations are skipped and retried on the next launch.
    func run() {
        migrateToICloudDrive()

        // Future migrations that rewrite the data file must OR their flag in here
        let fileMigrationsPending = !flags.isDone(Self.durationMigrationKey)
            || !flags.isDone(Self.mealItemsMigrationKey)
            || !flags.isDone(Self.workoutIntensityMigrationKey)

        if fileMigrationsPending {
            guard backUp() else {
                logger.error("Skipping data migrations: pre-migration backup failed; will retry next launch")
                return
            }
        }

        migrateWorkoutDurations()
        migrateMealItems()
        migrateWorkoutIntensities()
    }

    /// Migrates existing data from UserDefaults to iCloud Drive if not already done.
    /// - Safe to call multiple times; only runs the actual migration once.
    /// - Empty day entries are automatically filtered out during the load (via `RecordedDayData` parsing).
    /// - Cleans up old UserDefaults data after successful migration.
    func migrateToICloudDrive() {
        guard !flags.isDone(Self.iCloudMigrationKey) else {
            return
        }

        let existingData = legacySource.load()

        // Only migrate if there's actual data to move
        guard !existingData.isEmpty else {
            flags.markDone(Self.iCloudMigrationKey)
            return
        }

        cloudSource.save(existingData)

        // Clean up old UserDefaults data
        flags.clearLegacyStore()
        flags.markDone(Self.iCloudMigrationKey)

        logger.info("Successfully migrated \(existingData.count) day(s) to iCloud Drive")
    }

    /// Migrates workout durations from old format to new format on disk.
    /// - Old format stored as single integers (enum raw values 0-6)
    /// - New format stores as {"minutes": X} dictionary
    /// - The Codable implementation automatically converts on load, this migration re-saves in new format
    /// - Safe to call multiple times; only runs once (controlled by flag)
    func migrateWorkoutDurations() {
        guard !flags.isDone(Self.durationMigrationKey) else {
            logger.debug("Workout duration migration already completed, skipping")
            return
        }

        logger.debug("Starting workout duration migration...")

        let allRecordedDays = cloudSource.load() // Codable automatically converts old format on load

        // Count workouts that were likely converted from old format
        var convertedCount = 0
        for recordedDay in allRecordedDays {
            for workout in recordedDay.dayData.workouts
                where [10, 15, 30, 40, 60, 90, 120].contains(workout.duration.minutes)
            {
                logger.debug("Loaded (auto-converted): '\(workout.description)' = \(workout.duration.minutes)min")
                convertedCount += 1
            }
        }
        if convertedCount > 0 {
            logger.debug("Auto-converted \(convertedCount) workout(s) during load")
        }

        // Re-save all data to persist the new format to disk
        // This ensures the JSON file is updated from old format (integers) to new format ({"minutes": X})
        if !allRecordedDays.isEmpty {
            cloudSource.save(allRecordedDays)
            logger.info("Re-saved \(allRecordedDays.count) day(s) with new duration format")
        } else {
            logger.debug("No data to migrate")
        }

        flags.markDone(Self.durationMigrationKey)
    }

    /// Migrates meals from legacy single `description` string to `items` array on disk.
    /// - Old format stored `"description": "..."`
    /// - New format stores `"items": ["..."]`
    /// - The Codable implementation automatically converts on load, this migration re-saves in new format
    /// - Safe to call multiple times; only runs once (controlled by flag)
    func migrateMealItems() {
        guard !flags.isDone(Self.mealItemsMigrationKey) else {
            logger.debug("Meal items migration already completed, skipping")
            return
        }

        logger.debug("Starting meal items migration...")

        let allRecordedDays = cloudSource.load() // Codable automatically converts old format on load

        // Re-save all data to persist the new format to disk
        // This ensures the JSON file is updated from old format ("description") to new format ("items")
        if !allRecordedDays.isEmpty {
            cloudSource.save(allRecordedDays)
            logger.info("Re-saved \(allRecordedDays.count) day(s) with new meal items format")
        } else {
            logger.debug("No data to migrate")
        }

        flags.markDone(Self.mealItemsMigrationKey)
    }

    /// Migrates workouts to persist the newly added `intensity` field on disk.
    /// - Old format had no `intensity` key
    /// - The Codable implementation defaults missing `intensity` to `.medium` on load; this
    ///   migration re-saves so the field is written to disk in the new format
    /// - Safe to call multiple times; only runs once (controlled by flag)
    func migrateWorkoutIntensities() {
        guard !flags.isDone(Self.workoutIntensityMigrationKey) else {
            logger.debug("Workout intensity migration already completed, skipping")
            return
        }

        logger.debug("Starting workout intensity migration...")

        let allRecordedDays = cloudSource.load() // Codable defaults missing intensity to .medium on load

        // Re-save all data to persist the new format to disk
        // This ensures the JSON file gains the `intensity` field for existing workouts
        if !allRecordedDays.isEmpty {
            cloudSource.save(allRecordedDays)
            logger.info("Re-saved \(allRecordedDays.count) day(s) with workout intensity field")
        } else {
            logger.debug("No data to migrate")
        }

        flags.markDone(Self.workoutIntensityMigrationKey)
    }
}
