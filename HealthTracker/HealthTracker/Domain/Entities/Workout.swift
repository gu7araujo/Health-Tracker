//
//  Workout.swift
//  HealthTracker
//
//  Domain Entity - Pure Swift
//

import Foundation

/// Represents a workout/exercise entry with duration.
/// Replaces the generic `Item` struct with workout-specific properties.
struct Workout: Identifiable, Codable, Equatable {

    /// Duration of the workout session
    enum Duration: Int, Codable, CaseIterable {
        case fifteenMin = 0
        case thirtyMin = 1
        case oneHour = 2
        case oneHourThirty = 3

        var localizedName: String {
            switch self {
            case .fifteenMin: return "15m"
            case .thirtyMin: return "30m"
            case .oneHour: return "1h"
            case .oneHourThirty: return "1h30m"
            }
        }
    }

    let id: UUID
    var description: String
    var duration: Duration

    init(
        id: UUID = UUID(),
        description: String,
        duration: Duration = .thirtyMin
    ) {
        self.id = id
        self.description = description
        self.duration = duration
    }
}
