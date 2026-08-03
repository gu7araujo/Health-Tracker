//
//  DataMigrationTests.swift
//  HealthTrackerTests
//
//  Tests for DataMigration driving the injectable struct against in-memory fakes.
//  Covers, per migration: already-migrated no-op, successful migration, and
//  source-absent (empty) — plus the run() backup-guard orchestration.
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct DataMigrationTests {
    // MARK: - Helpers

    private func makeMigration(
        legacy: MockLocalDataSource = MockLocalDataSource(),
        cloud: MockLocalDataSource = MockLocalDataSource(),
        flags: MockMigrationFlagStore = MockMigrationFlagStore(),
        backUp: @escaping () -> Bool = { true }
    ) -> DataMigration {
        DataMigration(
            legacySource: legacy,
            cloudSource: cloud,
            flags: flags,
            backUp: backUp,
            logger: MockLogger()
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

        makeMigration(legacy: legacy, cloud: cloud, flags: flags).migrateToICloudDrive()

        #expect(cloud.saveCalledWith == days)
        #expect(flags.clearLegacyStoreCalled)
        #expect(flags.isDone(DataMigration.iCloudMigrationKey))
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

        makeMigration(cloud: cloud, flags: flags).migrateWorkoutDurations()

        #expect(cloud.saveCalledWith == days)
        #expect(flags.isDone(DataMigration.durationMigrationKey))
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

        makeMigration(cloud: cloud, flags: flags).migrateMealItems()

        #expect(cloud.saveCalledWith == days)
        #expect(flags.isDone(DataMigration.mealItemsMigrationKey))
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

        makeMigration(cloud: cloud, flags: flags).migrateWorkoutIntensities()

        #expect(cloud.saveCalledWith == days)
        #expect(flags.isDone(DataMigration.workoutIntensityMigrationKey))
    }

    // MARK: - run() orchestration

    @Test("When a file migration is pending and the backup fails, no file migration runs")
    func run_skipsFileMigrations_whenBackupFails() throws {
        let cloud = MockLocalDataSource()
        cloud.loadResult = try recordedDays()
        // iCloud already migrated so only the file migrations are pending.
        let flags = MockMigrationFlagStore(done: [DataMigration.iCloudMigrationKey])

        makeMigration(cloud: cloud, flags: flags, backUp: { false }).run()

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
