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
    /// All optimal conditions met: small meals + 50% satiety, water >= 1.8L, has workout, good mood
    case optimal

    /// Moderate conditions: medium meals + 80% satiety, OR water 1.0-1.7L, OR neutral mood
    case moderate

    /// Has data but doesn't meet optimal or moderate criteria
    case poor

    /// Only 1-2 categories have data (incomplete day)
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
