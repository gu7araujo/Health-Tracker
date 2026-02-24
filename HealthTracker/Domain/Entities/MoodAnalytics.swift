//
//  MoodAnalytics.swift
//  HealthTracker
//
//  Created by Claude on 02/23/26.
//

import Foundation

/// Analytics data for mood tracking over a time period
struct MoodAnalytics: Equatable {
    /// Distribution of moods (mood → count)
    let distribution: [Mood: Int]

    /// Percentage of days with good mood (0-100)
    let goodDaysPercentage: Double

    /// Daily mood for heat map (date → mood)
    let dailyMood: [Date: Mood]

    /// Week with highest good mood percentage (week start date)
    let bestWeek: Date?

    /// Week with lowest good mood percentage (week start date)
    let worstWeek: Date?
}
