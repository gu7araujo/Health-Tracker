//
//  Workout.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/18/25.
//

import Foundation

/// Represents a workout/exercise entry with duration.
/// Replaces the generic `Item` struct with workout-specific properties.
struct Workout: Identifiable, Codable, Equatable {
    /// Duration of the workout session
    enum Duration: Int, Codable, CaseIterable {
        case tenMin = 4
        case fifteenMin = 0
        case thirtyMin = 1
        case fortyMin = 5
        case oneHour = 2
        case oneHourThirty = 3
        case twoHours = 6

        var localizedName: String {
            switch self {
            case .tenMin: "10m"
            case .fifteenMin: "15m"
            case .thirtyMin: "30m"
            case .fortyMin: "40m"
            case .oneHour: "1h"
            case .oneHourThirty: "1h30m"
            case .twoHours: "2h"
            }
        }

        /// Returns the duration in minutes
        var minutes: Int {
            switch self {
            case .tenMin: 10
            case .fifteenMin: 15
            case .thirtyMin: 30
            case .fortyMin: 40
            case .oneHour: 60
            case .oneHourThirty: 90
            case .twoHours: 120
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
