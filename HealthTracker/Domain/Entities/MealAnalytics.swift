//
//  MealAnalytics.swift
//  HealthTracker
//
//  Created by Claude on 02/23/26.
//

import Foundation

/// Analytics data for meal tracking over a time period
struct MealAnalytics: Equatable {
    /// Total number of meals recorded in the period
    let totalMeals: Int

    /// Average satisfaction percentage across all meals (0-100)
    let averageSatisfaction: Double

    /// Distribution of meal quantities
    let quantityDistribution: [Meal.Quantity: Int]

    /// Distribution of satisfaction levels
    let satisfactionDistribution: [Meal.Satisfaction: Int]

    /// Number of days meeting optimal meal criteria
    let optimalDaysCount: Int

    /// Daily meal counts for charting (date → count)
    let dailyCounts: [Date: Int]

    /// Daily satisfaction breakdown for stacked area chart (date → satisfaction level → count)
    let satisfactionTrend: [Date: [Meal.Satisfaction: Int]]
}
