//
//  WorkoutTests.swift
//  HealthTrackerTests
//
//  Tests for Workout entity covering enum cases, localized names, and Codable conformance.
//

import Foundation
@testable import HealthTracker
import Testing

struct WorkoutTests {
    // MARK: - Duration Enum Tests

    @Test @MainActor func duration_allCases_areAccessible() {
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

    @Test @MainActor func duration_localizedNames_areCorrect() {
        #expect(Workout.Duration.tenMin.localizedName == "10m")
        #expect(Workout.Duration.fifteenMin.localizedName == "15m")
        #expect(Workout.Duration.thirtyMin.localizedName == "30m")
        #expect(Workout.Duration.fortyMin.localizedName == "40m")
        #expect(Workout.Duration.oneHour.localizedName == "1h")
        #expect(Workout.Duration.oneHourThirty.localizedName == "1h30m")
        #expect(Workout.Duration.twoHours.localizedName == "2h")
    }

    @Test @MainActor func duration_rawValues_areCorrect() {
        #expect(Workout.Duration.tenMin.rawValue == 4)
        #expect(Workout.Duration.fifteenMin.rawValue == 0)
        #expect(Workout.Duration.thirtyMin.rawValue == 1)
        #expect(Workout.Duration.fortyMin.rawValue == 5)
        #expect(Workout.Duration.oneHour.rawValue == 2)
        #expect(Workout.Duration.oneHourThirty.rawValue == 3)
        #expect(Workout.Duration.twoHours.rawValue == 6)
    }

    // MARK: - Workout Initialization Tests

    @Test @MainActor func initialization_withDefaults() {
        let workout = Workout(description: "Morning run")

        #expect(workout.description == "Morning run")
        #expect(workout.duration == .thirtyMin)
    }

    @Test @MainActor func initialization_withAllParameters() {
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

    @Test @MainActor func codable_roundTrip_preservesAllData() throws {
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

    @Test @MainActor func codable_roundTrip_withDefaults() throws {
        let original = Workout(description: "Quick walk")

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Workout.self, from: encoded)

        #expect(decoded.id == original.id)
        #expect(decoded.description == original.description)
        #expect(decoded.duration == .thirtyMin)
    }

    // MARK: - Equatable Tests

    @Test @MainActor func equatable_sameValues_areEqual() {
        let id = UUID()
        let workout1 = Workout(id: id, description: "Run", duration: .thirtyMin)
        let workout2 = Workout(id: id, description: "Run", duration: .thirtyMin)

        #expect(workout1 == workout2)
    }

    @Test @MainActor func equatable_differentIds_areNotEqual() {
        let workout1 = Workout(description: "Run", duration: .thirtyMin)
        let workout2 = Workout(description: "Run", duration: .thirtyMin)

        #expect(workout1 != workout2)
    }

    @Test @MainActor func equatable_differentDurations_areNotEqual() {
        let id = UUID()
        let workout1 = Workout(id: id, description: "Run", duration: .thirtyMin)
        let workout2 = Workout(id: id, description: "Run", duration: .oneHour)

        #expect(workout1 != workout2)
    }

    // MARK: - Identifiable Tests

    @Test @MainActor func identifiable_hasUniqueId() {
        let workout1 = Workout(description: "Morning run")
        let workout2 = Workout(description: "Morning run")

        #expect(workout1.id != workout2.id)
    }
}
