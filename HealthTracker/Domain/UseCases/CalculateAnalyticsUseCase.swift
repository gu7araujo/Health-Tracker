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
    /// - Parameter period: The time period to analyze
    /// - Returns: Complete analytics data for all health metrics
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

        logger.info("Analytics calculated: \(analytics.mealAnalytics.totalMeals) meals, \(analytics.workoutAnalytics.totalWorkouts) workouts")

        return analytics
    }

    // MARK: - Meal Analytics

    private func calculateMealAnalytics(from days: [DayData], period _: AnalyticsPeriod) -> MealAnalytics {
        let allMeals = days.flatMap(\.meals)

        // Total meals
        let totalMeals = allMeals.count

        // Average satisfaction (convert satisfaction 0-3 to percentages: 30, 50, 80, 100)
        let averageSatisfaction: Double
        if !allMeals.isEmpty {
            let totalSatisfaction = allMeals.reduce(0.0) { sum, meal in
                let percentage = switch meal.satisfaction {
                case .thirty: 30.0
                case .fifty: 50.0
                case .eighty: 80.0
                case .hundred: 100.0
                }
                return sum + percentage
            }
            averageSatisfaction = totalSatisfaction / Double(allMeals.count)
        } else {
            averageSatisfaction = 0.0
        }

        // Quantity distribution
        var quantityDist: [Meal.Quantity: Int] = [:]
        for quantity in Meal.Quantity.allCases {
            quantityDist[quantity] = allMeals.filter { $0.quantity == quantity }.count
        }

        // Satisfaction distribution
        var satisfactionDist: [Meal.Satisfaction: Int] = [:]
        for satisfaction in Meal.Satisfaction.allCases {
            satisfactionDist[satisfaction] = allMeals.filter { $0.satisfaction == satisfaction }.count
        }

        // Optimal days count (small meals + 50% satiety)
        let optimalDaysCount = days.filter { day in
            !day.meals.isEmpty && day.meals.allSatisfy { meal in
                (meal.quantity == .small || meal.quantity == .verySmall) && meal.satisfaction == .fifty
            }
        }.count

        // Daily counts
        var dailyCounts: [Date: Int] = [:]
        for day in days {
            let normalizedDate = Calendar.current.startOfDay(for: day.date)
            dailyCounts[normalizedDate] = day.meals.count
        }

        // Satisfaction trend for stacked chart
        var satisfactionTrend: [Date: [Meal.Satisfaction: Int]] = [:]
        for day in days where !day.meals.isEmpty {
            let normalizedDate = Calendar.current.startOfDay(for: day.date)
            var dist: [Meal.Satisfaction: Int] = [:]
            for satisfaction in Meal.Satisfaction.allCases {
                dist[satisfaction] = day.meals.filter { $0.satisfaction == satisfaction }.count
            }
            satisfactionTrend[normalizedDate] = dist
        }

        return MealAnalytics(
            totalMeals: totalMeals,
            averageSatisfaction: averageSatisfaction,
            quantityDistribution: quantityDist,
            satisfactionDistribution: satisfactionDist,
            optimalDaysCount: optimalDaysCount,
            dailyCounts: dailyCounts,
            satisfactionTrend: satisfactionTrend
        )
    }

    // MARK: - Water Analytics

    private func calculateWaterAnalytics(from days: [DayData]) -> WaterAnalytics {
        let waterDays = days.compactMap { day -> (Date, Double)? in
            guard let water = day.water, water > 0 else { return nil }
            return (Calendar.current.startOfDay(for: day.date), water)
        }

        let waterIntakes = waterDays.map(\.1)

        let averageIntake = waterIntakes.isEmpty ? 0.0 : waterIntakes.reduce(0.0, +) / Double(waterIntakes.count)
        let maxIntake = waterIntakes.max() ?? 0.0
        let minIntake = waterIntakes.min() ?? 0.0

        let daysAboveOptimal = waterIntakes.filter { $0 >= 1.8 }.count
        let daysAboveModerate = waterIntakes.filter { $0 >= 1.0 }.count

        // Consistency score based on standard deviation
        let consistencyScore: Double
        if waterIntakes.count > 1 {
            let variance = waterIntakes.reduce(0.0) { $0 + pow($1 - averageIntake, 2) } / Double(waterIntakes.count)
            let standardDeviation = sqrt(variance)
            // Map std dev to 0-100 score (lower std dev = higher consistency)
            consistencyScore = max(0, 100 - (standardDeviation * 50))
        } else {
            consistencyScore = 100.0
        }

        var dailyIntake: [Date: Double] = [:]
        for (date, intake) in waterDays {
            dailyIntake[date] = intake
        }

        return WaterAnalytics(
            averageIntake: averageIntake,
            maxIntake: maxIntake,
            minIntake: minIntake,
            daysAboveOptimal: daysAboveOptimal,
            daysAboveModerate: daysAboveModerate,
            consistencyScore: consistencyScore,
            dailyIntake: dailyIntake
        )
    }

    // MARK: - Workout Analytics

    private func calculateWorkoutAnalytics(from days: [DayData]) -> WorkoutAnalytics {
        let allWorkouts = days.flatMap(\.workouts)

        let totalWorkouts = allWorkouts.count
        let totalMinutes = allWorkouts.reduce(0) { $0 + $1.duration.minutes }
        let averageDuration = allWorkouts.isEmpty ? 0 : totalMinutes / totalWorkouts

        // Streaks
        let (currentStreak, longestStreak) = calculateStreaks(
            in: days,
            condition: { !$0.workouts.isEmpty }
        )

        // Weekday distribution
        var weekdayDist: [Int: (count: Int, avgDuration: Int)] = [:]
        let calendar = Calendar.current
        for day in days where !day.workouts.isEmpty {
            let weekday = calendar.component(.weekday, from: day.date)
            let adjustedWeekday = weekday == 1 ? 7 : weekday - 1 // Convert Sunday=1 to Sunday=7, Monday=2 to Monday=1
            let dayMinutes = day.workouts.reduce(0) { $0 + $1.duration.minutes }
            let existing = weekdayDist[adjustedWeekday] ?? (count: 0, avgDuration: 0)
            let newCount = existing.count + 1
            let newAvg = (existing.avgDuration * existing.count + dayMinutes) / newCount
            weekdayDist[adjustedWeekday] = (count: newCount, avgDuration: newAvg)
        }

        // Weekly volume
        var weeklyVolume: [Date: Int] = [:]
        for day in days where !day.workouts.isEmpty {
            if let weekStart = calendar.dateInterval(of: .weekOfYear, for: day.date)?.start {
                let normalizedWeekStart = calendar.startOfDay(for: weekStart)
                let dayMinutes = day.workouts.reduce(0) { $0 + $1.duration.minutes }
                weeklyVolume[normalizedWeekStart, default: 0] += dayMinutes
            }
        }

        // Duration distribution by range
        var durationDist: [DurationRange: Int] = [:]
        for workout in allWorkouts {
            let range = DurationRange(minutes: workout.duration.minutes)
            durationDist[range, default: 0] += 1
        }

        return WorkoutAnalytics(
            totalWorkouts: totalWorkouts,
            totalMinutes: totalMinutes,
            averageDuration: averageDuration,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            weekdayDistribution: weekdayDist,
            weeklyVolume: weeklyVolume,
            durationDistribution: durationDist
        )
    }

    // MARK: - Mood Analytics

    private func calculateMoodAnalytics(from days: [DayData], period _: AnalyticsPeriod) -> MoodAnalytics {
        let moodDays = days.compactMap { day -> (Date, Mood)? in
            guard let mood = day.mood else { return nil }
            return (Calendar.current.startOfDay(for: day.date), mood)
        }

        // Distribution
        var distribution: [Mood: Int] = [:]
        for mood in Mood.allCases {
            distribution[mood] = moodDays.filter { $0.1 == mood }.count
        }

        let goodDaysCount = distribution[.good] ?? 0
        let goodDaysPercentage = moodDays.isEmpty ? 0.0 : (Double(goodDaysCount) / Double(moodDays.count)) * 100.0

        // Daily mood
        var dailyMood: [Date: Mood] = [:]
        for (date, mood) in moodDays {
            dailyMood[date] = mood
        }

        // Best/worst weeks
        let (bestWeek, worstWeek) = calculateBestWorstWeeks(from: days)

        return MoodAnalytics(
            distribution: distribution,
            goodDaysPercentage: goodDaysPercentage,
            dailyMood: dailyMood,
            bestWeek: bestWeek,
            worstWeek: worstWeek
        )
    }

    // MARK: - Overall Analytics

    private func calculateOverallAnalytics(from days: [DayData]) -> OverallAnalytics {
        let recordedDays = days.compactMap(RecordedDayData.init)

        let daysTracked = recordedDays.count

        // Status distribution
        var statusDist: [DayStatus: Int] = [
            .optimal: 0,
            .moderate: 0,
            .poor: 0,
            .incomplete: 0,
            .noData: 0
        ]

        for day in recordedDays {
            let status = day.dayData.status
            statusDist[status, default: 0] += 1
        }

        let optimalDays = statusDist[.optimal] ?? 0
        let moderateDays = statusDist[.moderate] ?? 0
        let poorDays = statusDist[.poor] ?? 0
        let incompleteDays = statusDist[.incomplete] ?? 0

        // Optimal streaks
        let (currentOptimalStreak, longestOptimalStreak) = calculateStreaks(
            in: days,
            condition: { $0.status == .optimal }
        )

        // Health score calculation
        let healthScore: Double = if daysTracked > 0 {
            (Double(optimalDays) * 100.0 +
                Double(moderateDays) * 60.0 +
                Double(poorDays) * 30.0 +
                Double(incompleteDays) * 10.0) / Double(daysTracked)
        } else {
            0.0
        }

        return OverallAnalytics(
            daysTracked: daysTracked,
            optimalDays: optimalDays,
            moderateDays: moderateDays,
            poorDays: poorDays,
            incompleteDays: incompleteDays,
            currentOptimalStreak: currentOptimalStreak,
            longestOptimalStreak: longestOptimalStreak,
            healthScore: healthScore,
            statusDistribution: statusDist
        )
    }

    // MARK: - Helper Methods

    /// Calculates current and longest streaks based on a condition
    private func calculateStreaks(
        in days: [DayData],
        condition: (DayData) -> Bool
    ) -> (current: Int, longest: Int) {
        guard !days.isEmpty else { return (0, 0) }

        let sorted = days.sorted { $0.date > $1.date } // Most recent first
        let calendar = Calendar.current

        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0
        var previousDate: Date?

        for day in sorted {
            let meetsCondition = condition(day)

            if meetsCondition {
                if let prev = previousDate {
                    let daysBetween = calendar.dateComponents([.day], from: day.date, to: prev).day ?? 0
                    if daysBetween == 1 {
                        // Consecutive day
                        tempStreak += 1
                    } else {
                        // Break in streak
                        longestStreak = max(longestStreak, tempStreak)
                        tempStreak = 1
                    }
                } else {
                    // First day
                    tempStreak = 1
                }

                // Update current streak if this is the most recent day
                if previousDate == nil || calendar.isDateInToday(day.date) {
                    currentStreak = tempStreak
                }

                previousDate = day.date
            } else {
                // Condition not met
                longestStreak = max(longestStreak, tempStreak)
                if previousDate == nil {
                    // If we start with a non-matching day, current streak is 0
                    currentStreak = 0
                }
                tempStreak = 0
                previousDate = day.date
            }
        }

        longestStreak = max(longestStreak, tempStreak)

        return (currentStreak, longestStreak)
    }

    /// Calculates best and worst weeks based on good mood percentage
    private func calculateBestWorstWeeks(from days: [DayData]) -> (best: Date?, worst: Date?) {
        let calendar = Calendar.current
        var weeklyMoods: [Date: [Mood]] = [:]

        for day in days {
            guard let mood = day.mood else { continue }
            if let weekStart = calendar.dateInterval(of: .weekOfYear, for: day.date)?.start {
                let normalizedWeekStart = calendar.startOfDay(for: weekStart)
                weeklyMoods[normalizedWeekStart, default: []].append(mood)
            }
        }

        guard !weeklyMoods.isEmpty else { return (nil, nil) }

        let weekScores = weeklyMoods.map { week, moods in
            let goodCount = moods.filter { $0 == .good }.count
            let percentage = Double(goodCount) / Double(moods.count)
            return (week: week, score: percentage)
        }

        let bestWeek = weekScores.max(by: { $0.score < $1.score })?.week
        let worstWeek = weekScores.min(by: { $0.score < $1.score })?.week

        return (bestWeek, worstWeek)
    }
}
