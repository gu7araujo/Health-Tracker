//
//  AnalyticsData.swift
//  HealthTracker
//
//  Created by Claude on 02/23/26.
//

import Foundation

/// Container for all analytics data across health metrics for a given time period
struct AnalyticsData: Equatable {
    /// Analytics for meal tracking
    let mealAnalytics: MealAnalytics

    /// Analytics for water intake
    let waterAnalytics: WaterAnalytics

    /// Analytics for workouts
    let workoutAnalytics: WorkoutAnalytics

    /// Analytics for mood tracking
    let moodAnalytics: MoodAnalytics

    /// Overall health analytics across all metrics
    let overallAnalytics: OverallAnalytics

    /// The time period for which this analytics data was calculated
    let period: AnalyticsPeriod
}
