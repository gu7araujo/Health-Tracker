//
//  MoodTests.swift
//  HealthTrackerTests
//
//  Tests for Mood enum covering all cases, emoji mappings, color mappings,
//  localized names, and Codable conformance.
//

import Foundation
@testable import HealthTracker
import SwiftUI
import Testing

struct MoodTests {
    // MARK: - Enum Cases Tests

    @Test @MainActor func allCases_containsAllMoods() {
        let cases = Mood.allCases

        #expect(cases.count == 3)
        #expect(cases.contains(.good))
        #expect(cases.contains(.neutral))
        #expect(cases.contains(.sad))
    }

    // MARK: - Emoji Mapping Tests

    @Test @MainActor func emoji_mappings_areCorrect() {
        #expect(Mood.good.emoji == "😁")
        #expect(Mood.neutral.emoji == "😐")
        #expect(Mood.sad.emoji == "😔")
    }

    // MARK: - Localized Name Tests

    @Test @MainActor func localizedName_mappings_areCorrect() {
        #expect(Mood.good.localizedName == "Bom")
        #expect(Mood.neutral.localizedName == "Neutro")
        #expect(Mood.sad.localizedName == "Ruim")
    }

    // MARK: - Color Mapping Tests

    @Test @MainActor func color_mappings_areCorrect() {
        #expect(Mood.good.color == .green)
        #expect(Mood.neutral.color == .orange)
        #expect(Mood.sad.color == .red)
    }

    // MARK: - Raw Value Tests

    @Test @MainActor func rawValue_mappings_areCorrect() {
        #expect(Mood.good.rawValue == "Good")
        #expect(Mood.neutral.rawValue == "Neutral")
        #expect(Mood.sad.rawValue == "Sad")
    }

    @Test @MainActor func initialization_fromRawValue() {
        #expect(Mood(rawValue: "Good") == .good)
        #expect(Mood(rawValue: "Neutral") == .neutral)
        #expect(Mood(rawValue: "Sad") == .sad)
        #expect(Mood(rawValue: "Invalid") == nil)
    }

    // MARK: - Codable Tests

    @Test @MainActor func codable_roundTrip_good() throws {
        let original = Mood.good

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Mood.self, from: encoded)

        #expect(decoded == original)
    }

    @Test @MainActor func codable_roundTrip_neutral() throws {
        let original = Mood.neutral

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Mood.self, from: encoded)

        #expect(decoded == original)
    }

    @Test @MainActor func codable_roundTrip_sad() throws {
        let original = Mood.sad

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Mood.self, from: encoded)

        #expect(decoded == original)
    }

    // MARK: - Equatable Tests

    @Test @MainActor func equatable_sameValues_areEqual() {
        #expect(Mood.good == Mood.good)
        #expect(Mood.neutral == Mood.neutral)
        #expect(Mood.sad == Mood.sad)
    }

    @Test @MainActor func equatable_differentValues_areNotEqual() {
        #expect(Mood.good != Mood.neutral)
        #expect(Mood.good != Mood.sad)
        #expect(Mood.neutral != Mood.sad)
    }
}
