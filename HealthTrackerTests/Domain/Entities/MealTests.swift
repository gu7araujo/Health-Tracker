//
//  MealTests.swift
//  HealthTrackerTests
//
//  Tests for Meal entity covering enum cases, localized names, and Codable conformance.
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct MealTests {
    // MARK: - Quantity Enum Tests

    @Test func quantity_allCases_areAccessible() {
        let cases = Meal.Quantity.allCases

        #expect(cases.count == 4)
        #expect(cases.contains(.verySmall))
        #expect(cases.contains(.small))
        #expect(cases.contains(.medium))
        #expect(cases.contains(.large))
    }

    @Test(arguments: [
        (Meal.Quantity.verySmall, "meal_quantity_very_small"),
        (.small, "meal_quantity_small"),
        (.medium, "meal_quantity_medium"),
        (.large, "meal_quantity_large")
    ])
    func quantity_localizedNames(quantity: Meal.Quantity, localizationKey: String) {
        let expected = NSLocalizedString(localizationKey, comment: "")
        #expect(quantity.localizedName == expected)
    }

    @Test(arguments: [
        (Meal.Quantity.verySmall, 0),
        (.small, 1),
        (.medium, 2),
        (.large, 3)
    ])
    func quantity_rawValues(quantity: Meal.Quantity, expectedValue: Int) {
        #expect(quantity.rawValue == expectedValue)
    }

    // MARK: - Satisfaction Enum Tests

    @Test func satisfaction_allCases_areAccessible() {
        let cases = Meal.Satisfaction.allCases

        #expect(cases.count == 4)
        #expect(cases.contains(.thirty))
        #expect(cases.contains(.fifty))
        #expect(cases.contains(.eighty))
        #expect(cases.contains(.hundred))
    }

    @Test(arguments: [
        (Meal.Satisfaction.thirty, "30%"),
        (.fifty, "50%"),
        (.eighty, "80%"),
        (.hundred, "100%")
    ])
    func satisfaction_localizedNames(satisfaction: Meal.Satisfaction, expectedName: String) {
        #expect(satisfaction.localizedName == expectedName)
    }

    @Test(arguments: [
        (Meal.Satisfaction.thirty, 0),
        (.fifty, 1),
        (.eighty, 2),
        (.hundred, 3)
    ])
    func satisfaction_rawValues(satisfaction: Meal.Satisfaction, expectedValue: Int) {
        #expect(satisfaction.rawValue == expectedValue)
    }

    // MARK: - Meal Initialization Tests

    @Test func initialization_withDefaults() {
        let meal = Meal(description: "Breakfast")

        #expect(meal.description == "Breakfast")
        #expect(meal.quantity == .small)
        #expect(meal.satisfaction == .fifty)
    }

    @Test func initialization_withAllParameters() {
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

    @Test func initialization_withItems() {
        let meal = Meal(items: ["Rice", "Beans"])

        #expect(meal.items == ["Rice", "Beans"])
        #expect(meal.description == "Rice, Beans")
        #expect(meal.quantity == .small)
        #expect(meal.satisfaction == .fifty)
    }

    // MARK: - Codable Tests

    @Test func codable_roundTrip_preservesAllData() throws {
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

    @Test func codable_roundTrip_withDefaults() throws {
        let original = Meal(description: "Snack")

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Meal.self, from: encoded)

        #expect(decoded.id == original.id)
        #expect(decoded.description == original.description)
        #expect(decoded.quantity == .small)
        #expect(decoded.satisfaction == .fifty)
    }

    @Test func codable_roundTrip_withMultipleItems() throws {
        let original = Meal(
            items: ["Rice", "Beans", "Chicken"],
            quantity: .medium,
            satisfaction: .eighty
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Meal.self, from: encoded)

        #expect(decoded.id == original.id)
        #expect(decoded.items == ["Rice", "Beans", "Chicken"])
        #expect(decoded.description == "Rice, Beans, Chicken")
        #expect(decoded.quantity == original.quantity)
        #expect(decoded.satisfaction == original.satisfaction)
    }

    @Test func decode_legacyDescriptionOnly_fallsBackToSingleItemArray() throws {
        let legacyJSON = """
        {
            "id": "\(UUID().uuidString)",
            "description": "Breakfast",
            "quantity": 1,
            "satisfaction": 1
        }
        """
        let data = try #require(legacyJSON.data(using: .utf8))

        let decoded = try JSONDecoder().decode(Meal.self, from: data)

        #expect(decoded.items == ["Breakfast"])
        #expect(decoded.description == "Breakfast")
        #expect(decoded.quantity == .small)
        #expect(decoded.satisfaction == .fifty)
    }

    @Test func encode_writesItemsKey_notDescription() throws {
        let meal = Meal(items: ["Rice", "Beans"])

        let encoded = try JSONEncoder().encode(meal)
        let json = try #require(try JSONSerialization.jsonObject(with: encoded) as? [String: Any])

        #expect(json["items"] as? [String] == ["Rice", "Beans"])
        #expect(json["description"] == nil)
    }

    // MARK: - Equatable Tests

    @Test func equatable_sameValues_areEqual() {
        let id = UUID()
        let meal1 = Meal(id: id, description: "Test", quantity: .small, satisfaction: .fifty)
        let meal2 = Meal(id: id, description: "Test", quantity: .small, satisfaction: .fifty)

        #expect(meal1 == meal2)
    }

    @Test func equatable_differentIds_areNotEqual() {
        let meal1 = Meal(description: "Test", quantity: .small, satisfaction: .fifty)
        let meal2 = Meal(description: "Test", quantity: .small, satisfaction: .fifty)

        #expect(meal1 != meal2)
    }

    @Test func equatable_differentQuantities_areNotEqual() {
        let id = UUID()
        let meal1 = Meal(id: id, description: "Test", quantity: .small, satisfaction: .fifty)
        let meal2 = Meal(id: id, description: "Test", quantity: .large, satisfaction: .fifty)

        #expect(meal1 != meal2)
    }

    // MARK: - Identifiable Tests

    @Test func identifiable_hasUniqueId() {
        let meal1 = Meal(description: "Breakfast")
        let meal2 = Meal(description: "Breakfast")

        #expect(meal1.id != meal2.id)
    }

    // MARK: - Quantity Default Satisfaction Tests

    @Test(arguments: [
        (Meal.Quantity.verySmall, Meal.Satisfaction.thirty),
        (.small, Meal.Satisfaction.fifty),
        (.medium, Meal.Satisfaction.eighty),
        (.large, Meal.Satisfaction.hundred)
    ])
    func quantity_defaultSatisfaction(quantity: Meal.Quantity, expectedSatisfaction: Meal.Satisfaction) {
        #expect(quantity.defaultSatisfaction == expectedSatisfaction)
    }
}
