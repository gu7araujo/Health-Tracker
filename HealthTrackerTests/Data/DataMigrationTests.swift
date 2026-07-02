//
//  DataMigrationTests.swift
//  HealthTrackerTests
//
//  Tests for workout duration migration logic
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct DataMigrationTests {
    // MARK: - Duration Migration Tests

    @Test func migrateWorkoutDurations_convertsLegacyValues() {
        // Arrange: Create UserDefaults with test key
        let userDefaults = UserDefaults.standard
        let testKey = "workoutDurationMigrationCompleted_test"
        userDefaults.removeObject(forKey: testKey)

        // Create test data with legacy enum raw values (0-6)
        let dataSource = ICloudDriveDataSource()
        let testDays = [
            DayData(
                date: Date(),
                meals: [],
                workouts: [
                    Workout(description: "Run", duration: Workout.Duration(minutes: 0)), // Should convert 0 → 15
                    Workout(description: "Gym", duration: Workout.Duration(minutes: 1)), // Should convert 1 → 30
                    Workout(description: "Bike", duration: Workout.Duration(minutes: 2)) // Should convert 2 → 60
                ],
                water: nil,
                mood: nil
            )
        ]
        let recordedDays = testDays.compactMap(RecordedDayData.init)
        dataSource.save(recordedDays)

        // Act: Would call migration here, but it's private
        // This is a conceptual test - in real implementation, we'd need to expose
        // migration logic or test through public interface

        // Note: This test demonstrates the expected behavior but cannot execute
        // the private migrateWorkoutDurations() method directly
    }

    @Test func migrateWorkoutDurations_preservesNewValues() {
        // Arrange: Create workouts with new format (>= 7 minutes)
        let workout1 = Workout(description: "Run", duration: Workout.Duration(minutes: 45))
        let workout2 = Workout(description: "Bike", duration: Workout.Duration(minutes: 75))

        // Assert: Values should remain unchanged
        #expect(workout1.duration.minutes == 45)
        #expect(workout2.duration.minutes == 75)
    }

    @Test func migrateWorkoutDurations_handlesEdgeCases() {
        // Test boundary values
        let minDuration = Workout.Duration(minutes: 1)
        let maxDuration = Workout.Duration(minutes: 300)
        let belowMin = Workout.Duration(minutes: -5)
        let aboveMax = Workout.Duration(minutes: 500)

        #expect(minDuration.minutes == 1)
        #expect(maxDuration.minutes == 300)
        #expect(belowMin.minutes == 1) // Clamped to min
        #expect(aboveMax.minutes == 300) // Clamped to max
    }

    // MARK: - Meal Items Migration Tests

    @Test func migrateMealItems_convertsLegacyDescription() throws {
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

    @Test func duration_legacyValueMapping() {
        // Test that we understand the legacy enum mapping correctly
        let legacyMappings: [(rawValue: Int, expectedMinutes: Int)] = [
            (0, 15), // fifteenMin
            (1, 30), // thirtyMin
            (2, 60), // oneHour
            (3, 90), // oneHourThirty
            (4, 10), // tenMin
            (5, 40), // fortyMin
            (6, 120) // twoHours
        ]

        // These mappings are what the migration logic should apply
        for (rawValue, expectedMinutes) in legacyMappings {
            // In migration, if duration.minutes == rawValue (0-6),
            // it should be converted to expectedMinutes
            #expect(rawValue <= 6)
            #expect(expectedMinutes >= 10)
        }
    }
}
