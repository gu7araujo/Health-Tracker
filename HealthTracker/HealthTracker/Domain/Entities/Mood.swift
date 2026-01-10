//
//  Mood.swift
//  HealthTracker
//
//  Domain Entity - Pure Swift, no framework dependencies except SwiftUI for Color
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
        case .good: return "😁"
        case .neutral: return "😐"
        case .sad: return "😔"
        }
    }

    var localizedName: String {
        switch self {
        case .good: return "Bom"
        case .neutral: return "Neutro"
        case .sad: return "Ruim"
        }
    }

    var color: Color {
        switch self {
        case .good: return .green
        case .neutral: return .orange
        case .sad: return .red
        }
    }
}
