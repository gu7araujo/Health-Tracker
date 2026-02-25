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
    /// Duration of the workout session in minutes
    struct Duration: Equatable, Hashable {
        let minutes: Int

        /// Creates a duration with the specified number of minutes
        /// - Parameter minutes: Duration in minutes (clamped to 1-300 range)
        init(minutes: Int) {
            self.minutes = max(1, min(minutes, 300))
        }

        /// Returns a localized string representation of the duration
        /// Examples: "10m", "1h", "1h30m", "2h"
        var localizedName: String {
            if minutes < 60 {
                return "\(minutes)m"
            } else if minutes % 60 == 0 {
                return "\(minutes / 60)h"
            } else {
                let hours = minutes / 60
                let mins = minutes % 60
                return "\(hours)h\(mins)m"
            }
        }
    }

    let id: UUID
    var description: String
    var duration: Duration

    init(
        id: UUID = UUID(),
        description: String,
        duration: Duration = Duration(minutes: 30)
    ) {
        self.id = id
        self.description = description
        self.duration = duration
    }
}

// MARK: - Duration Codable Extension

extension Workout.Duration: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try to decode as Int (old enum format: raw value 0-6)
        if let legacyValue = try? container.decode(Int.self) {
            // Map legacy enum raw values to actual minutes
            let actualMinutes: Int = switch legacyValue {
            case 0: 15 // fifteenMin
            case 1: 30 // thirtyMin
            case 2: 60 // oneHour
            case 3: 90 // oneHourThirty
            case 4: 10 // tenMin
            case 5: 40 // fortyMin
            case 6: 120 // twoHours
            default: legacyValue // Already actual minutes (>=7)
            }
            self.init(minutes: actualMinutes)
            return
        }

        // Try to decode as struct (new format: {"minutes": X})
        let structContainer = try decoder.container(keyedBy: CodingKeys.self)
        let minutes = try structContainer.decode(Int.self, forKey: .minutes)
        self.init(minutes: minutes)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(minutes, forKey: .minutes)
    }

    private enum CodingKeys: String, CodingKey {
        case minutes
    }
}
