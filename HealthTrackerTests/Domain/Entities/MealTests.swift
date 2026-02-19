//
//  MealTests.swift
//  HealthTrackerTests
//
//  Tests for Meal entity covering enum cases, localized names, and Codable conformance.
//

import Foundation
@testable import HealthTracker
import Testing

struct MealTests {
    // MARK: - Quantity Enum Tests

    @Test @MainActor func quantity_allCases_areAccessible() {
        let cases = Meal.Quantity.allCases

        #expect(cases.count == 4)
        #expect(cases.contains(.verySmall))
        #expect(cases.contains(.small))
        #expect(cases.contains(.medium))
        #expect(cases.contains(.large))
    }

    @Test @MainActor func quantity_localizedNames_areCorrect() {
        #expect(Meal.Quantity.verySmall.localizedName == "Muito pequena")
        #expect(Meal.Quantity.small.localizedName == "Pequena")
        #expect(Meal.Quantity.medium.localizedName == "Média")
        #expect(Meal.Quantity.large.localizedName == "Grande")
    }

    @Test @MainActor func quantity_rawValues_areCorrect() {
        #expect(Meal.Quantity.verySmall.rawValue == 0)
        #expect(Meal.Quantity.small.rawValue == 1)
        #expect(Meal.Quantity.medium.rawValue == 2)
        #expect(Meal.Quantity.large.rawValue == 3)
    }

    // MARK: - Satisfaction Enum Tests

    @Test @MainActor func satisfaction_allCases_areAccessible() {
        let cases = Meal.Satisfaction.allCases

        #expect(cases.count == 4)
        #expect(cases.contains(.thirty))
        #expect(cases.contains(.fifty))
        #expect(cases.contains(.eighty))
        #expect(cases.contains(.hundred))
    }

    @Test @MainActor func satisfaction_localizedNames_areCorrect() {
        #expect(Meal.Satisfaction.thirty.localizedName == "30%")
        #expect(Meal.Satisfaction.fifty.localizedName == "50%")
        #expect(Meal.Satisfaction.eighty.localizedName == "80%")
        #expect(Meal.Satisfaction.hundred.localizedName == "100%")
    }

    @Test @MainActor func satisfaction_rawValues_areCorrect() {
        #expect(Meal.Satisfaction.thirty.rawValue == 0)
        #expect(Meal.Satisfaction.fifty.rawValue == 1)
        #expect(Meal.Satisfaction.eighty.rawValue == 2)
        #expect(Meal.Satisfaction.hundred.rawValue == 3)
    }

    // MARK: - Meal Initialization Tests

    @Test @MainActor func initialization_withDefaults() {
        let meal = Meal(description: "Breakfast")

        #expect(meal.description == "Breakfast")
        #expect(meal.quantity == .small)
        #expect(meal.satisfaction == .fifty)
    }

    @Test @MainActor func initialization_withAllParameters() {
        let id = UUID()
        let meal = Meal(
            id: id,
            description: "Lunch",
            quantity: .large,
            satisfaction: .hundred
        )

        #expect(meal.id == id)
        #expect(meal.description == "Lunch")
        #expect(meal.quantity == .large)
        #expect(meal.satisfaction == .hundred)
    }

    // MARK: - Codable Tests

    @Test @MainActor func codable_roundTrip_preservesAllData() throws {
        let original = Meal(
            description: "Dinner",
            quantity: .medium,
            satisfaction: .eighty
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Meal.self, from: encoded)

        #expect(decoded.id == original.id)
        #expect(decoded.description == original.description)
        #expect(decoded.quantity == original.quantity)
        #expect(decoded.satisfaction == original.satisfaction)
    }

    @Test @MainActor func codable_roundTrip_withDefaults() throws {
        let original = Meal(description: "Snack")

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Meal.self, from: encoded)

        #expect(decoded.id == original.id)
        #expect(decoded.description == original.description)
        #expect(decoded.quantity == .small)
        #expect(decoded.satisfaction == .fifty)
    }

    // MARK: - Equatable Tests

    @Test @MainActor func equatable_sameValues_areEqual() {
        let id = UUID()
        let meal1 = Meal(id: id, description: "Test", quantity: .small, satisfaction: .fifty)
        let meal2 = Meal(id: id, description: "Test", quantity: .small, satisfaction: .fifty)

        #expect(meal1 == meal2)
    }

    @Test @MainActor func equatable_differentIds_areNotEqual() {
        let meal1 = Meal(description: "Test", quantity: .small, satisfaction: .fifty)
        let meal2 = Meal(description: "Test", quantity: .small, satisfaction: .fifty)

        #expect(meal1 != meal2)
    }

    @Test @MainActor func equatable_differentQuantities_areNotEqual() {
        let id = UUID()
        let meal1 = Meal(id: id, description: "Test", quantity: .small, satisfaction: .fifty)
        let meal2 = Meal(id: id, description: "Test", quantity: .large, satisfaction: .fifty)

        #expect(meal1 != meal2)
    }

    // MARK: - Identifiable Tests

    @Test @MainActor func identifiable_hasUniqueId() {
        let meal1 = Meal(description: "Breakfast")
        let meal2 = Meal(description: "Breakfast")

        #expect(meal1.id != meal2.id)
    }
}
