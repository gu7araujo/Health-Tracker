//
//  DayStatus.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 01/17/26.
//

import SwiftUI

/// Represents the health status of a day based on tracked metrics.
/// Used to determine the circle color in the calendar strip.
enum DayStatus: Equatable {
    /// All optimal conditions met (ALL must be true):
    /// - Meals: Only verySmall/small OR at most 1 medium meal
    /// - Water: >= 1.8L
    /// - Workouts: >= 30 minutes total
    /// - Mood: good
    case optimal

    /// Moderate conditions (ANY one of):
    /// - Meals: Exactly 2 medium meals
    /// - Water: 1.0-1.7L
    /// - Workouts: < 30 minutes total
    /// - Mood: neutral
    case moderate

    /// Poor conditions (ANY one of):
    /// - Meals: 3+ medium meals OR any large meal
    /// - Water: < 1.0L
    /// - Mood: sad
    case poor

    /// Only 1 category has data (incomplete day)
    case incomplete

    /// No data recorded for this day
    case noData

    /// The color associated with this status for UI display
    var color: Color? {
        switch self {
        case .optimal:
            .green
        case .moderate:
            .yellow
        case .poor:
            .red
        case .incomplete:
            .primary
        case .noData:
            nil
        }
    }
}
