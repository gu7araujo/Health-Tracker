//
//  DataMigrationTests.swift
//  HealthTrackerTests
//
//  Tests for DataMigration driving the injectable struct against in-memory fakes.
//  Covers, per migration: already-migrated no-op, successful migration, and
//  source-absent (empty) — plus the run() backup-guard orchestration, and the
//  UserDefaults `MigrationFlagStore` conformance against a throwaway suite.
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct DataMigrationTests {
    // MARK: - Helpers

    private func makeMigration(
        legacy: MockLocalDataSource? = nil,
        cloud: MockLocalDataSource? = nil,
        flags: MockMigrationFlagStore? = nil,
        backUp: @escaping @MainActor () -> Bool = { true },
        logger: MockLogger? = nil
    ) -> DataMigration {
        DataMigration(
            legacySource: legacy ?? MockLocalDataSource(),
            cloudSource: cloud ?? MockLocalDataSource(),
            flags: flags ?? MockMigrationFlagStore(),
            backUp: backUp,
            logger: logger ?? MockLogger()
        )
    }

    private func recordedDays() throws -> [RecordedDayData] {
        let day = try #require(TestDataBuilder.makeRecordedOptimalDay())
        return [day]
    }

    // MARK: - migrateToICloudDrive

    @Test("Already-migrated iCloud flag is a no-op")
    func migrateToICloudDrive_skipsWhenFlagSet() throws {
        let legacy = MockLocalDataSource()
        legacy.loadResult = try recordedDays()
        let cloud = MockLocalDataSource()
        let flags = MockMigrationFlagStore(done: [DataMigration.iCloudMigrationKey])

        makeMigration(legacy: legacy, cloud: cloud, flags: flags).migrateToICloudDrive()

        #expect(cloud.saveCalledWith == nil)
        #expect(!flags.clearLegacyStoreCalled)
    }

    @Test("Empty legacy store just marks the migration done")
    func migrateToICloudDrive_marksDoneWhenLegacyEmpty() {
        let legacy = MockLocalDataSource()
        legacy.loadResult = []
        let cloud = MockLocalDataSource()
        let flags = MockMigrationFlagStore()

        makeMigration(legacy: legacy, cloud: cloud, flags: flags).migrateToICloudDrive()

        #expect(cloud.saveCalledWith == nil)
        #expect(!flags.clearLegacyStoreCalled)
        #expect(flags.isDone(DataMigration.iCloudMigrationKey))
    }

    @Test("Non-empty legacy store is copied to iCloud, cleaned up, and flagged done")
    func migrateToICloudDrive_migratesDataAndCleansUp() throws {
        let days = try recordedDays()
        let legacy = MockLocalDataSource()
        legacy.loadResult = days
        let cloud = MockLocalDataSource()
        let flags = MockMigrationFlagStore()
        let logger = MockLogger()

        makeMigration(legacy: legacy, cloud: cloud, flags: flags, logger: logger).migrateToICloudDrive()

        #expect(cloud.saveCalledWith == days)
        #expect(flags.clearLegacyStoreCalled)
        #expect(flags.isDone(DataMigration.iCloudMigrationKey))
        #expect(logger.didLog(level: .info, containing: "Successfully migrated 1 day(s) to iCloud Drive"))
    }

    // MARK: - migrateWorkoutDurations

    @Test("Duration migration is a no-op once its flag is set")
    func migrateWorkoutDurations_skipsWhenFlagSet() throws {
        let cloud = MockLocalDataSource()
        cloud.loadResult = try recordedDays()
        let flags = MockMigrationFlagStore(done: [DataMigration.durationMigrationKey])

        makeMigration(cloud: cloud, flags: flags).migrateWorkoutDurations()

        #expect(cloud.saveCalledWith == nil)
    }

    @Test("Duration migration marks done without re-saving an empty store")
    func migrateWorkoutDurations_marksDoneWhenEmpty() {
        let cloud = MockLocalDataSource()
        cloud.loadResult = []
        let flags = MockMigrationFlagStore()

        makeMigration(cloud: cloud, flags: flags).migrateWorkoutDurations()

        #expect(cloud.saveCalledWith == nil)
        #expect(flags.isDone(DataMigration.durationMigrationKey))
    }

    @Test("Duration migration re-saves existing data and flags done")
    func migrateWorkoutDurations_reSavesAndFlagsDone() throws {
        let days = try recordedDays()
        let cloud = MockLocalDataSource()
        cloud.loadResult = days
        let flags = MockMigrationFlagStore()
        let logger = MockLogger()

        makeMigration(cloud: cloud, flags: flags, logger: logger).migrateWorkoutDurations()

        #expect(cloud.saveCalledWith == days)
        #expect(flags.isDone(DataMigration.durationMigrationKey))
        #expect(logger.didLog(level: .info, containing: "Re-saved 1 day(s) with new duration format"))
    }

    @Test("Duration migration logs how many workouts carry a legacy-converted duration")
    func migrateWorkoutDurations_logsLegacyConvertedCount() throws {
        let day = try #require(TestDataBuilder.makeRecordedDayData(from: TestDataBuilder.makeDayData(workouts: [
            Workout(description: "Legacy 30", duration: Workout.Duration(minutes: 30)),
            Workout(description: "Custom 45", duration: Workout.Duration(minutes: 45)),
            Workout(description: "Legacy 120", duration: Workout.Duration(minutes: 120))
        ])))
        let cloud = MockLocalDataSource()
        cloud.loadResult = [day]
        let logger = MockLogger()

        makeMigration(cloud: cloud, logger: logger).migrateWorkoutDurations()

        #expect(logger.didLog(level: .debug, containing: "Auto-converted 2 workout(s) during load"))
        #expect(logger.didLog(level: .debug, containing: "'Legacy 120' = 120min"))
        #expect(!logger.didLog(level: .debug, containing: "Custom 45"))
    }

    @Test("Duration migration logs no conversion when no workout has a legacy duration")
    func migrateWorkoutDurations_skipsConversionLog_whenNoLegacyDurations() throws {
        let day = try #require(TestDataBuilder.makeRecordedDayData(from: TestDataBuilder.makeDayData(workouts: [
            Workout(description: "Custom 45", duration: Workout.Duration(minutes: 45))
        ])))
        let cloud = MockLocalDataSource()
        cloud.loadResult = [day]
        let logger = MockLogger()

        makeMigration(cloud: cloud, logger: logger).migrateWorkoutDurations()

        #expect(!logger.didLog(level: .debug, containing: "Auto-converted"))
        #expect(cloud.saveCalledWith == [day])
    }

    // MARK: - migrateMealItems

    @Test("Meal items migration is a no-op once its flag is set")
    func migrateMealItems_skipsWhenFlagSet() throws {
        let cloud = MockLocalDataSource()
        cloud.loadResult = try recordedDays()
        let flags = MockMigrationFlagStore(done: [DataMigration.mealItemsMigrationKey])

        makeMigration(cloud: cloud, flags: flags).migrateMealItems()

        #expect(cloud.saveCalledWith == nil)
    }

    @Test("Meal items migration marks done without re-saving an empty store")
    func migrateMealItems_marksDoneWhenEmpty() {
        let cloud = MockLocalDataSource()
        cloud.loadResult = []
        let flags = MockMigrationFlagStore()

        makeMigration(cloud: cloud, flags: flags).migrateMealItems()

        #expect(cloud.saveCalledWith == nil)
        #expect(flags.isDone(DataMigration.mealItemsMigrationKey))
    }

    @Test("Meal items migration re-saves existing data and flags done")
    func migrateMealItems_reSavesAndFlagsDone() throws {
        let days = try recordedDays()
        let cloud = MockLocalDataSource()
        cloud.loadResult = days
        let flags = MockMigrationFlagStore()
        let logger = MockLogger()

        makeMigration(cloud: cloud, flags: flags, logger: logger).migrateMealItems()

        #expect(cloud.saveCalledWith == days)
        #expect(flags.isDone(DataMigration.mealItemsMigrationKey))
        #expect(logger.didLog(level: .info, containing: "Re-saved 1 day(s) with new meal items format"))
    }

    // MARK: - migrateWorkoutIntensities

    @Test("Intensity migration is a no-op once its flag is set")
    func migrateWorkoutIntensities_skipsWhenFlagSet() throws {
        let cloud = MockLocalDataSource()
        cloud.loadResult = try recordedDays()
        let flags = MockMigrationFlagStore(done: [DataMigration.workoutIntensityMigrationKey])

        makeMigration(cloud: cloud, flags: flags).migrateWorkoutIntensities()

        #expect(cloud.saveCalledWith == nil)
    }

    @Test("Intensity migration marks done without re-saving an empty store")
    func migrateWorkoutIntensities_marksDoneWhenEmpty() {
        let cloud = MockLocalDataSource()
        cloud.loadResult = []
        let flags = MockMigrationFlagStore()

        makeMigration(cloud: cloud, flags: flags).migrateWorkoutIntensities()

        #expect(cloud.saveCalledWith == nil)
        #expect(flags.isDone(DataMigration.workoutIntensityMigrationKey))
    }

    @Test("Intensity migration re-saves existing data and flags done")
    func migrateWorkoutIntensities_reSavesAndFlagsDone() throws {
        let days = try recordedDays()
        let cloud = MockLocalDataSource()
        cloud.loadResult = days
        let flags = MockMigrationFlagStore()
        let logger = MockLogger()

        makeMigration(cloud: cloud, flags: flags, logger: logger).migrateWorkoutIntensities()

        #expect(cloud.saveCalledWith == days)
        #expect(flags.isDone(DataMigration.workoutIntensityMigrationKey))
        #expect(logger.didLog(level: .info, containing: "Re-saved 1 day(s) with workout intensity field"))
    }

    // MARK: - Meal Items Codable Conversion

    @Test("Legacy meal `description` decodes into `items`, which the re-save persists")
    func migrateMealItems_convertsLegacyDescription() throws {
        // Legacy JSON with `description` only (no `items`) decodes into `items: [description]`,
        // which is the conversion migrateMealItems() persists back to disk on re-save.
        let legacyJSON = """
        {
            "id": "\(UUID().uuidString)",
            "description": "Lunch",
            "quantity": 2,
            "satisfaction": 2
        }
        """
        let data = try #require(legacyJSON.data(using: .utf8))

        let decoded = try JSONDecoder().decode(Meal.self, from: data)

        #expect(decoded.items == ["Lunch"])

        // Re-encoding (what the migration's re-save does) persists the new `items` shape
        let reEncoded = try JSONEncoder().encode(decoded)
        let json = try #require(try JSONSerialization.jsonObject(with: reEncoded) as? [String: Any])
        #expect(json["items"] as? [String] == ["Lunch"])
        #expect(json["description"] == nil)
    }
}

// MARK: - run() orchestration and the UserDefaults flag store

extension DataMigrationTests {
    @Test("When a file migration is pending and the backup fails, no file migration runs")
    func run_skipsFileMigrations_whenBackupFails() throws {
        let cloud = MockLocalDataSource()
        cloud.loadResult = try recordedDays()
        // iCloud already migrated so only the file migrations are pending.
        let flags = MockMigrationFlagStore(done: [DataMigration.iCloudMigrationKey])
        let logger = MockLogger()

        makeMigration(cloud: cloud, flags: flags, backUp: { false }, logger: logger).run()

        #expect(logger.didLog(level: .error, containing: "pre-migration backup failed"))
        #expect(cloud.saveCalledWith == nil)
        #expect(!flags.isDone(DataMigration.durationMigrationKey))
        #expect(!flags.isDone(DataMigration.mealItemsMigrationKey))
        #expect(!flags.isDone(DataMigration.workoutIntensityMigrationKey))
    }

    @Test("When a file migration is pending and the backup succeeds, all file migrations run")
    func run_runsFileMigrations_whenBackupSucceeds() throws {
        let cloud = MockLocalDataSource()
        cloud.loadResult = try recordedDays()
        let flags = MockMigrationFlagStore(done: [DataMigration.iCloudMigrationKey])

        makeMigration(cloud: cloud, flags: flags, backUp: { true }).run()

        #expect(cloud.saveCalledWith != nil)
        #expect(flags.isDone(DataMigration.durationMigrationKey))
        #expect(flags.isDone(DataMigration.mealItemsMigrationKey))
        #expect(flags.isDone(DataMigration.workoutIntensityMigrationKey))
    }

    @Test("No backup is taken when every file migration is already complete")
    func run_skipsBackup_whenNothingPending() {
        var backupCalled = false
        let flags = MockMigrationFlagStore(done: [
            DataMigration.iCloudMigrationKey,
            DataMigration.durationMigrationKey,
            DataMigration.mealItemsMigrationKey,
            DataMigration.workoutIntensityMigrationKey
        ])

        makeMigration(flags: flags, backUp: {
            backupCalled = true
            return true
        }).run()

        #expect(!backupCalled)
    }

    @Test(
        "A backup is taken and the migration runs when only that file migration is pending",
        arguments: FileMigration.allCases
    )
    func run_takesBackup_whenOnlyOneFileMigrationPending(pending: FileMigration) throws {
        let pendingKey = pending.key
        var backupCalled = false
        let days = try recordedDays()
        let cloud = MockLocalDataSource()
        cloud.loadResult = days
        let allKeys: Set = [
            DataMigration.iCloudMigrationKey,
            DataMigration.durationMigrationKey,
            DataMigration.mealItemsMigrationKey,
            DataMigration.workoutIntensityMigrationKey
        ]
        let flags = MockMigrationFlagStore(done: allKeys.subtracting([pendingKey]))

        makeMigration(cloud: cloud, flags: flags, backUp: {
            backupCalled = true
            return true
        }).run()

        #expect(backupCalled)
        #expect(cloud.saveCalledWith == days)
        #expect(flags.isDone(pendingKey))
    }

    @Test("The legacy store moves to iCloud even when the file-migration backup fails")
    func run_migratesLegacyStore_whenBackupFails() throws {
        let days = try recordedDays()
        let legacy = MockLocalDataSource()
        legacy.loadResult = days
        let cloud = MockLocalDataSource()
        let flags = MockMigrationFlagStore()

        makeMigration(legacy: legacy, cloud: cloud, flags: flags, backUp: { false }).run()

        #expect(cloud.saveCalledWith == days)
        #expect(flags.clearLegacyStoreCalled)
        #expect(flags.isDone(DataMigration.iCloudMigrationKey))
        #expect(!flags.isDone(DataMigration.durationMigrationKey))
    }

    // MARK: - UserDefaults as MigrationFlagStore

    @Test("UserDefaults reports a flag as done only after markDone")
    func userDefaultsFlagStore_marksFlagDone() throws {
        let suiteName = "test-suite-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        #expect(!defaults.isDone(DataMigration.durationMigrationKey))
        defaults.markDone(DataMigration.durationMigrationKey)

        #expect(defaults.isDone(DataMigration.durationMigrationKey))
        #expect(!defaults.isDone(DataMigration.mealItemsMigrationKey))
    }

    @Test("UserDefaults clearLegacyStore removes only the legacy `store` blob")
    func userDefaultsFlagStore_clearsOnlyLegacyStore() throws {
        let suiteName = "test-suite-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(Data("legacy".utf8), forKey: "store")
        defaults.markDone(DataMigration.iCloudMigrationKey)

        defaults.clearLegacyStore()

        #expect(defaults.object(forKey: "store") == nil)
        #expect(defaults.isDone(DataMigration.iCloudMigrationKey))
    }
}
