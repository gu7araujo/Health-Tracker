//
//  WaterAnalytics.swift
//  HealthTracker
//
//  Created by Claude on 02/23/26.
//

import Foundation

/// Analytics data for water intake over a time period
struct WaterAnalytics: Equatable {
    /// Average daily water intake in liters
    let averageIntake: Double

    /// Maximum water intake recorded in the period
    let maxIntake: Double

    /// Minimum water intake recorded in the period
    let minIntake: Double

    /// Number of days reaching optimal threshold (≥ 1.8L)
    let daysAboveOptimal: Int

    /// Number of days reaching moderate threshold (≥ 1.0L)
    let daysAboveModerate: Int

    /// Consistency score (0-100) based on standard deviation
    let consistencyScore: Double

    /// Daily water intake for line chart (date → liters)
    let dailyIntake: [Date: Double]
}
