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
            case .verySmall, .small: .thirty
            case .medium: .fifty
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
    var description: String
    var quantity: Quantity
    var satisfaction: Satisfaction

    init(
        id: UUID = UUID(),
        description: String,
        quantity: Quantity = .small,
        satisfaction: Satisfaction = .fifty
    ) {
        self.id = id
        self.description = description
        self.quantity = quantity
        self.satisfaction = satisfaction
    }
}
