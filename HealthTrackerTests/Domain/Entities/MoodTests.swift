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

@MainActor
struct MoodTests {
    // MARK: - Enum Cases Tests

    @Test func allCases_containsAllMoods() {
        let cases = Mood.allCases

        #expect(cases.count == 3)
        #expect(cases.contains(.good))
        #expect(cases.contains(.neutral))
        #expect(cases.contains(.sad))
    }

    // MARK: - Emoji Mapping Tests

    @Test(arguments: [
        (Mood.good, "😁"),
        (.neutral, "😐"),
        (.sad, "😔")
    ])
    func emoji_mappings(mood: Mood, expectedEmoji: String) {
        #expect(mood.emoji == expectedEmoji)
    }

    // MARK: - Localized Name Tests

    @Test(arguments: [
        (Mood.good, "Bom"),
        (.neutral, "Neutro"),
        (.sad, "Ruim")
    ])
    func localizedName_mappings(mood: Mood, expectedName: String) {
        #expect(mood.localizedName == expectedName)
    }

    // MARK: - Color Mapping Tests

    @Test(arguments: [
        (Mood.good, Color.green),
        (.neutral, .orange),
        (.sad, .red)
    ])
    func color_mappings(mood: Mood, expectedColor: Color) {
        #expect(mood.color == expectedColor)
    }

    // MARK: - Raw Value Tests

    @Test func rawValue_mappings_areCorrect() {
        #expect(Mood.good.rawValue == "Good")
        #expect(Mood.neutral.rawValue == "Neutral")
        #expect(Mood.sad.rawValue == "Sad")
    }

    @Test func initialization_fromRawValue() {
        #expect(Mood(rawValue: "Good") == .good)
        #expect(Mood(rawValue: "Neutral") == .neutral)
        #expect(Mood(rawValue: "Sad") == .sad)
        #expect(Mood(rawValue: "Invalid") == nil)
    }

    // MARK: - Codable Tests

    @Test func codable_roundTrip_good() throws {
        let original = Mood.good

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Mood.self, from: encoded)

        #expect(decoded == original)
    }

    @Test func codable_roundTrip_neutral() throws {
        let original = Mood.neutral

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Mood.self, from: encoded)

        #expect(decoded == original)
    }

    @Test func codable_roundTrip_sad() throws {
        let original = Mood.sad

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Mood.self, from: encoded)

        #expect(decoded == original)
    }

    // MARK: - Equatable Tests

    @Test func equatable_sameValues_areEqual() {
        #expect(Mood.good == Mood.good)
        #expect(Mood.neutral == Mood.neutral)
        #expect(Mood.sad == Mood.sad)
    }

    @Test func equatable_differentValues_areNotEqual() {
        #expect(Mood.good != Mood.neutral)
        #expect(Mood.good != Mood.sad)
        #expect(Mood.neutral != Mood.sad)
    }
}
