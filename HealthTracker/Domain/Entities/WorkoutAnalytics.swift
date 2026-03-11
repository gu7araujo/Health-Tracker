//
//  WorkoutAnalytics.swift
//  HealthTracker
//
//  Created by Claude on 02/23/26.
//

import Foundation

/// Duration range categories for analytics grouping
enum DurationRange: String, Codable {
    case short = "0-20m"
    case medium = "20-45m"
    case long = "45-75m"
    case veryLong = "75m+"

    /// Creates a duration range from minutes
    init(minutes: Int) {
        switch minutes {
        case 0 ..< 20: self = .short
        case 20 ..< 45: self = .medium
        case 45 ..< 75: self = .long
        default: self = .veryLong
        }
    }

    /// Returns localized name for the duration range
    var localizedName: String {
        switch self {
        case .short: String(localized: "duration_range_short")
        case .medium: String(localized: "duration_range_medium")
        case .long: String(localized: "duration_range_long")
        case .veryLong: String(localized: "duration_range_very_long")
        }
    }
}

/// Analytics data for workout tracking over a time period
struct WorkoutAnalytics: Equatable {
    /// Total number of workouts recorded in the period
    let totalWorkouts: Int

    /// Total workout time in minutes
    let totalMinutes: Int

    /// Average workout duration in minutes
    let averageDuration: Int

    /// Current consecutive-day workout streak
    let currentStreak: Int

    /// Longest consecutive-day workout streak in the period
    let longestStreak: Int

    /// Distribution by weekday (1=Monday...7=Sunday → count and average duration)
    let weekdayDistribution: [Int: (count: Int, avgDuration: Int)]

    /// Weekly workout volume for bar chart (week start date → total minutes)
    let weeklyVolume: [Date: Int]

    /// Distribution by duration range
    let durationDistribution: [DurationRange: Int]

    /// Manual Equatable conformance because Swift can't synthesize for dictionary with tuple values
    static func == (lhs: WorkoutAnalytics, rhs: WorkoutAnalytics) -> Bool {
        lhs.totalWorkouts == rhs.totalWorkouts &&
            lhs.totalMinutes == rhs.totalMinutes &&
            lhs.averageDuration == rhs.averageDuration &&
            lhs.currentStreak == rhs.currentStreak &&
            lhs.longestStreak == rhs.longestStreak &&
            lhs.weeklyVolume == rhs.weeklyVolume &&
            lhs.durationDistribution == rhs.durationDistribution &&
            lhs.weekdayDistribution.count == rhs.weekdayDistribution.count &&
            lhs.weekdayDistribution.allSatisfy { key, value in
                rhs.weekdayDistribution[key]?.count == value.count &&
                    rhs.weekdayDistribution[key]?.avgDuration == value.avgDuration
            }
    }
}
