//
//  OverallAnalytics.swift
//  HealthTracker
//
//  Created by Claude on 02/23/26.
//

import Foundation

/// Overall health analytics across all metrics for a time period
struct OverallAnalytics: Equatable {
    /// Total days with at least one tracked metric
    let daysTracked: Int

    /// Number of days with optimal status
    let optimalDays: Int

    /// Number of days with moderate status
    let moderateDays: Int

    /// Number of days with poor status
    let poorDays: Int

    /// Number of days with incomplete status
    let incompleteDays: Int

    /// Current consecutive-day optimal streak
    let currentOptimalStreak: Int

    /// Longest consecutive-day optimal streak in the period
    let longestOptimalStreak: Int

    /// Overall health score (0-100) weighted by day status
    let healthScore: Double

    /// Distribution of day statuses
    let statusDistribution: [DayStatus: Int]
}
