//
//  Meal.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/18/25.
//

import Foundation

/// Represents a meal entry with quantity and satisfaction level.
/// Replaces the generic `Item` struct with meal-specific properties.
struct Meal: Identifiable, Codable, Equatable {
    /// Portion size of the meal
    enum Quantity: Int, Codable, CaseIterable {
        case verySmall = 0
        case small = 1
        case medium = 2
        case large = 3

        var localizedName: String {
            switch self {
            case .verySmall: String(localized: "meal_quantity_very_small")
            case .small: String(localized: "meal_quantity_small")
            case .medium: String(localized: "meal_quantity_medium")
            case .large: String(localized: "meal_quantity_large")
            }
        }

        var defaultSatisfaction: Satisfaction {
            switch self {
            case .verySmall: .thirty
            case .small: .fifty
            case .medium: .eighty
            case .large: .hundred
            }
        }
    }

    /// How satisfied the user felt after eating
    enum Satisfaction: Int, Codable, CaseIterable {
        case thirty = 0
        case fifty = 1
        case eighty = 2
        case hundred = 3

        var localizedName: String {
            switch self {
            case .thirty: String(localized: "satisfaction_thirty")
            case .fifty: String(localized: "satisfaction_fifty")
            case .eighty: String(localized: "satisfaction_eighty")
            case .hundred: String(localized: "satisfaction_hundred")
            }
        }
    }

    let id: UUID
    var items: [String]
    var quantity: Quantity
    var satisfaction: Satisfaction

    /// Comma-separated rendering of `items`, preserved for display and existing call sites
    var description: String {
        items.joined(separator: ", ")
    }

    init(
        id: UUID = UUID(),
        items: [String],
        quantity: Quantity = .small,
        satisfaction: Satisfaction = .fifty
    ) {
        self.id = id
        self.items = items
        self.quantity = quantity
        self.satisfaction = satisfaction
    }

    init(
        id: UUID = UUID(),
        description: String,
        quantity: Quantity = .small,
        satisfaction: Satisfaction = .fifty
    ) {
        self.init(id: id, items: [description], quantity: quantity, satisfaction: satisfaction)
    }
}

// MARK: - Codable

extension Meal {
    private enum CodingKeys: String, CodingKey {
        case id
        case items
        case description
        case quantity
        case satisfaction
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let quantity = try container.decode(Quantity.self, forKey: .quantity)
        let satisfaction = try container.decode(Satisfaction.self, forKey: .satisfaction)

        // New format stores `items`; legacy format stored a single `description` string
        if let items = try container.decodeIfPresent([String].self, forKey: .items) {
            self.init(id: id, items: items, quantity: quantity, satisfaction: satisfaction)
        } else {
            let description = try container.decode(String.self, forKey: .description)
            self.init(id: id, items: [description], quantity: quantity, satisfaction: satisfaction)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(items, forKey: .items)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(satisfaction, forKey: .satisfaction)
    }
}
