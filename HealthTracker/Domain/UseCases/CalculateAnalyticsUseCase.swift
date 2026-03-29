//
//  CalculateAnalyticsUseCase.swift
//  HealthTracker
//
//  Created by Claude on 02/23/26.
//

import Foundation

/// Use case for calculating comprehensive analytics across all health metrics
final class CalculateAnalyticsUseCase {
    private let repository: HealthDataRepositoryProtocol
    private let logger: LoggerProtocol

    init(repository: HealthDataRepositoryProtocol, logger: LoggerProtocol) {
        self.repository = repository
        self.logger = logger
    }

    /// Calculates analytics for the specified period
    func execute(for period: AnalyticsPeriod) -> AnalyticsData {
        let days = repository.loadDaysInRange(period.dateRange)
        logger.debug("Calculating analytics for \(days.count) days")

        let dayDataArray = days.map(\.dayData)

        let analytics = AnalyticsData(
            mealAnalytics: calculateMealAnalytics(from: dayDataArray, period: period),
            waterAnalytics: calculateWaterAnalytics(from: dayDataArray),
            workoutAnalytics: calculateWorkoutAnalytics(from: dayDataArray),
            moodAnalytics: calculateMoodAnalytics(from: dayDataArray, period: period),
            overallAnalytics: calculateOverallAnalytics(from: dayDataArray),
            period: period
        )

        let meals = analytics.mealAnalytics.totalMeals
        let workouts = analytics.workoutAnalytics.totalWorkouts
        logger.info("Analytics calculated: \(meals) meals, \(workouts) workouts")

        return analytics
    }
}
