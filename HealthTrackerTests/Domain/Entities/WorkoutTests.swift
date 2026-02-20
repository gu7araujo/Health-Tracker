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
    // MARK: - Duration Enum Tests

    @Test func duration_allCases_areAccessible() {
        let cases = Workout.Duration.allCases

        #expect(cases.count == 7)
        #expect(cases.contains(.tenMin))
        #expect(cases.contains(.fifteenMin))
        #expect(cases.contains(.thirtyMin))
        #expect(cases.contains(.fortyMin))
        #expect(cases.contains(.oneHour))
        #expect(cases.contains(.oneHourThirty))
        #expect(cases.contains(.twoHours))
    }

    @Test(arguments: [
        (Workout.Duration.tenMin, "10m"),
        (.fifteenMin, "15m"),
        (.thirtyMin, "30m"),
        (.fortyMin, "40m"),
        (.oneHour, "1h"),
        (.oneHourThirty, "1h30m"),
        (.twoHours, "2h")
    ])
    func duration_localizedNames(duration: Workout.Duration, expectedName: String) {
        #expect(duration.localizedName == expectedName)
    }

    @Test(arguments: [
        (Workout.Duration.tenMin, 4),
        (.fifteenMin, 0),
        (.thirtyMin, 1),
        (.fortyMin, 5),
        (.oneHour, 2),
        (.oneHourThirty, 3),
        (.twoHours, 6)
    ])
    func duration_rawValues(duration: Workout.Duration, expectedValue: Int) {
        #expect(duration.rawValue == expectedValue)
    }

    // MARK: - Workout Initialization Tests

    @Test func initialization_withDefaults() {
        let workout = Workout(description: "Morning run")

        #expect(workout.description == "Morning run")
        #expect(workout.duration == .thirtyMin)
    }

    @Test func initialization_withAllParameters() {
        let id = UUID()
        let workout = Workout(
            id: id,
            description: "Gym session",
            duration: .oneHour
        )

        #expect(workout.id == id)
        #expect(workout.description == "Gym session")
        #expect(workout.duration == .oneHour)
    }

    // MARK: - Codable Tests

    @Test func codable_roundTrip_preservesAllData() throws {
        let original = Workout(
            description: "Cycling",
            duration: .oneHourThirty
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Workout.self, from: encoded)

        #expect(decoded.id == original.id)
        #expect(decoded.description == original.description)
        #expect(decoded.duration == original.duration)
    }

    @Test func codable_roundTrip_withDefaults() throws {
        let original = Workout(description: "Quick walk")

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Workout.self, from: encoded)

        #expect(decoded.id == original.id)
        #expect(decoded.description == original.description)
        #expect(decoded.duration == .thirtyMin)
    }

    // MARK: - Equatable Tests

    @Test func equatable_sameValues_areEqual() {
        let id = UUID()
        let workout1 = Workout(id: id, description: "Run", duration: .thirtyMin)
        let workout2 = Workout(id: id, description: "Run", duration: .thirtyMin)

        #expect(workout1 == workout2)
    }

    @Test func equatable_differentIds_areNotEqual() {
        let workout1 = Workout(description: "Run", duration: .thirtyMin)
        let workout2 = Workout(description: "Run", duration: .thirtyMin)

        #expect(workout1 != workout2)
    }

    @Test func equatable_differentDurations_areNotEqual() {
        let id = UUID()
        let workout1 = Workout(id: id, description: "Run", duration: .thirtyMin)
        let workout2 = Workout(id: id, description: "Run", duration: .oneHour)

        #expect(workout1 != workout2)
    }

    // MARK: - Identifiable Tests

    @Test func identifiable_hasUniqueId() {
        let workout1 = Workout(description: "Morning run")
        let workout2 = Workout(description: "Morning run")

        #expect(workout1.id != workout2.id)
    }
}
