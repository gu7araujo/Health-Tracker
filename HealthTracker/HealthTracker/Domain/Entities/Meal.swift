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
            case .verySmall: return "Muito pequena"
            case .small: return "Pequena"
            case .medium: return "Média"
            case .large: return "Grande"
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
            case .thirty: return "30%"
            case .fifty: return "50%"
            case .eighty: return "80%"
            case .hundred: return "100%"
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
