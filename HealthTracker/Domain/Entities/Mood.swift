//
//  Mood.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/18/25.
//

import SwiftUI

/// Represents the user's mood state for a given day.
/// Replaces stringly-typed mood values with type-safe enum.
enum Mood: String, Codable, CaseIterable, Equatable {
    case good = "Good"
    case neutral = "Neutral"
    case sad = "Sad"

    var emoji: String {
        switch self {
        case .good: "😁"
        case .neutral: "😐"
        case .sad: "😔"
        }
    }

    var localizedName: String {
        switch self {
        case .good: "Bom"
        case .neutral: "Neutro"
        case .sad: "Ruim"
        }
    }

    var color: Color {
        switch self {
        case .good: .green
        case .neutral: .orange
        case .sad: .red
        }
    }
}
