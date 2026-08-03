//
//  WorkoutTests.swift
//  HealthTrackerTests
//
//  Tests for Workout entity covering enum cases, localized names, and Codable conformance.
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct WorkoutTests {
    // MARK: - Duration Struct Tests

    @Test func duration_initialization_withValidMinutes() {
        let duration = Workout.Duration(minutes: 45)

        #expect(duration.minutes == 45)
    }

    @Test func duration_initialization_clampsTooLow() {
        let duration = Workout.Duration(minutes: -10)

        #expect(duration.minutes == 1) // Minimum 1 minute
    }

    @Test func duration_initialization_clampsTooHigh() {
        let duration = Workout.Duration(minutes: 500)

        #expect(duration.minutes == 300) // Maximum 5 hours (300 minutes)
    }

    @Test(arguments: [
        (10, "10m"),
        (15, "15m"),
        (30, "30m"),
        (45, "45m"),
        (60, "1h"),
        (75, "1h15m"),
        (90, "1h30m"),
        (120, "2h")
    ])
    func duration_localizedName_formatsCorrectly(minutes: Int, expected: String) {
        let duration = Workout.Duration(minutes: minutes)

        #expect(duration.localizedName == expected)
    }

    @Test func duration_codable_roundTrip() throws {
        let original = Workout.Duration(minutes: 47)

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Workout.Duration.self, from: encoded)

        #expect(decoded == original)
    }

    @Test("Legacy bare-integer durations map old enum raw values (0-6) to real minutes", arguments: [
        (0, 15),
        (1, 30),
        (2, 60),
        (3, 90),
        (4, 10),
        (5, 40),
        (6, 120)
    ])
    func duration_decodesLegacyEnumRawValue_toMinutes(rawValue: Int, expectedMinutes: Int) throws {
        // Old format stored the duration as a single Int (enum raw value), not a {"minutes": X} object.
        let json = """
        { "id": "\(UUID().uuidString)", "description": "Legacy", "duration": \(rawValue) }
        """
        let data = try #require(json.data(using: .utf8))

        let decoded = try JSONDecoder().decode(Workout.self, from: data)

        #expect(decoded.duration.minutes == expectedMinutes)
    }

    @Test("Legacy bare integers of 7+ are treated as literal minutes")
    func duration_decodesLegacyValueAboveSix_asLiteralMinutes() throws {
        let json = """
        { "id": "\(UUID().uuidString)", "description": "Legacy", "duration": 45 }
        """
        let data = try #require(json.data(using: .utf8))

        let decoded = try JSONDecoder().decode(Workout.self, from: data)

        #expect(decoded.duration.minutes == 45)
    }

    @Test("Legacy bare integers above the max are clamped to 300")
    func duration_decodesLegacyValueAboveMax_clampsTo300() throws {
        let json = """
        { "id": "\(UUID().uuidString)", "description": "Legacy", "duration": 500 }
        """
        let data = try #require(json.data(using: .utf8))

        let decoded = try JSONDecoder().decode(Workout.self, from: data)

        #expect(decoded.duration.minutes == 300)
    }

    @Test func duration_sumMultipleDurations() {
        let durations = [
            Workout.Duration(minutes: 15),
            Workout.Duration(minutes: 10),
            Workout.Duration(minutes: 10)
        ]
        let total = durations.reduce(0) { $0 + $1.minutes }

        #expect(total == 35) // 15 + 10 + 10 = 35
    }

    // MARK: - Intensity Tests

    @Test func intensity_allCases_areOrdered() {
        #expect(Workout.Intensity.allCases == [.low, .medium, .high])
    }

    @Test(arguments: [
        (Workout.Intensity.low, "workout_intensity_low"),
        (.medium, "workout_intensity_medium"),
        (.high, "workout_intensity_high")
    ])
    func intensity_localizedName_usesLocalizationKey(intensity: Workout.Intensity, key: String) {
        let expected = NSLocalizedString(key, comment: "")

        #expect(intensity.localizedName == expected)
    }

    @Test func intensity_codable_roundTrip() throws {
        for intensity in Workout.Intensity.allCases {
            let encoded = try JSONEncoder().encode(intensity)
            let decoded = try JSONDecoder().decode(Workout.Intensity.self, from: encoded)

            #expect(decoded == intensity)
        }
    }

    // MARK: - Workout Initialization Tests

    @Test func initialization_withDefaults() {
        let workout = Workout(description: "Morning run")

        #expect(workout.description == "Morning run")
        #expect(workout.duration == Workout.Duration(minutes: 30))
        #expect(workout.intensity == .medium)
    }

    @Test func initialization_withAllParameters() {
        let id = UUID()
        let workout = Workout(
            id: id,
            description: "Gym session",
            duration: Workout.Duration(minutes: 60),
            intensity: .high
        )

        #expect(workout.id == id)
        #expect(workout.description == "Gym session")
        #expect(workout.duration == Workout.Duration(minutes: 60))
        #expect(workout.intensity == .high)
    }

    // MARK: - Codable Tests

    @Test func codable_roundTrip_preservesAllData() throws {
        let original = Workout(
            description: "Cycling",
            duration: Workout.Duration(minutes: 90),
            intensity: .high
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Workout.self, from: encoded)

        #expect(decoded.id == original.id)
        #expect(decoded.description == original.description)
        #expect(decoded.duration == original.duration)
        #expect(decoded.intensity == .high)
    }

    @Test func codable_roundTrip_withDefaults() throws {
        let original = Workout(description: "Quick walk")

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Workout.self, from: encoded)

        #expect(decoded.id == original.id)
        #expect(decoded.description == original.description)
        #expect(decoded.duration == Workout.Duration(minutes: 30))
        #expect(decoded.intensity == .medium)
    }

    @Test func codable_decodesLegacyWorkout_missingIntensity_defaultsToMedium() throws {
        // Legacy JSON predates `intensity`; decoding must not fail and must default to `.medium`
        let legacyJSON = """
        {
            "id": "\(UUID().uuidString)",
            "description": "Old run",
            "duration": {"minutes": 45}
        }
        """
        let data = try #require(legacyJSON.data(using: .utf8))

        let decoded = try JSONDecoder().decode(Workout.self, from: data)

        #expect(decoded.description == "Old run")
        #expect(decoded.duration == Workout.Duration(minutes: 45))
        #expect(decoded.intensity == .medium)
    }

    // MARK: - Equatable Tests

    @Test func equatable_sameValues_areEqual() {
        let id = UUID()
        let workout1 = Workout(id: id, description: "Run", duration: Workout.Duration(minutes: 30))
        let workout2 = Workout(id: id, description: "Run", duration: Workout.Duration(minutes: 30))

        #expect(workout1 == workout2)
    }

    @Test func equatable_differentIds_areNotEqual() {
        let workout1 = Workout(description: "Run", duration: Workout.Duration(minutes: 30))
        let workout2 = Workout(description: "Run", duration: Workout.Duration(minutes: 30))

        #expect(workout1 != workout2)
    }

    @Test func equatable_differentDurations_areNotEqual() {
        let id = UUID()
        let workout1 = Workout(id: id, description: "Run", duration: Workout.Duration(minutes: 30))
        let workout2 = Workout(id: id, description: "Run", duration: Workout.Duration(minutes: 60))

        #expect(workout1 != workout2)
    }

    // MARK: - Identifiable Tests

    @Test func identifiable_hasUniqueId() {
        let workout1 = Workout(description: "Morning run")
        let workout2 = Workout(description: "Morning run")

        #expect(workout1.id != workout2.id)
    }
}
