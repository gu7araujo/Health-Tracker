//
//  TestDataBuilder.swift
//  HealthTrackerTests
//
//  Created for testing purposes.
//

import Foundation
@testable import HealthTracker

/// Factory functions for creating test fixtures with sensible defaults.
/// Provides builders for common test scenarios with deterministic data.
enum TestDataBuilder {
    // MARK: - Fixed Dates

    /// Fixed date for deterministic testing: Feb 19, 2024 12:00 PM UTC
    static let fixedDate = Date(timeIntervalSince1970: 1_708_387_200)

    /// Fixed date for testing date comparisons: Feb 20, 2024 12:00 PM UTC
    static let fixedDatePlusOne = Date(timeIntervalSince1970: 1_708_473_600)

    // MARK: - DayData Builders

    /// Creates a `DayData` with specified properties.
    @MainActor
    static func makeDayData(
        date: Date = fixedDate,
        meals: [Meal] = [],
        workouts: [Workout] = [],
        water: Double? = nil,
        mood: Mood? = nil
    ) -> DayData {
        DayData(
            date: date,
            meals: meals,
            workouts: workouts,
            water: water,
            mood: mood
        )
    }

    /// Creates an optimal day (should result in `.optimal` status).
    /// - Meals: 1 small, 1 medium (satiety doesn't matter - only size matters)
    /// - Water: 2.0L
    /// - Workout: 30 min
    /// - Mood: Good
    @MainActor
    static func makeOptimalDay(date: Date = fixedDate) -> DayData {
        makeDayData(
            date: date,
            meals: [
                Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty),
                Meal(description: "Lunch", quantity: .medium, satisfaction: .fifty),
            ],
            workouts: [Workout(description: "Morning run", duration: Workout.Duration(minutes: 30))],
            water: 2.0,
            mood: .good
        )
    }

    /// Creates a moderate day (should result in `.moderate` status).
    /// - Meals: 1 medium (triggers moderate when other optimal criteria not fully met)
    /// - Water: 1.5L (moderate range)
    /// - Workout: 15 min (< 30 min, triggers moderate)
    /// - Mood: Neutral
    @MainActor
    static func makeModerateDay(date: Date = fixedDate) -> DayData {
        makeDayData(
            date: date,
            meals: [
                Meal(description: "Lunch", quantity: .medium, satisfaction: .eighty),
            ],
            workouts: [Workout(description: "Light workout", duration: Workout.Duration(minutes: 15))],
            water: 1.5,
            mood: .neutral
        )
    }

    /// Creates a poor day (should result in `.poor` status).
    /// - Meals: 2 medium (2+ medium meals triggers poor)
    /// - Water: 0.5L (< 1.0L triggers poor)
    /// - Workout: 30 min (workouts don't affect poor status)
    /// - Mood: Sad
    @MainActor
    static func makePoorDay(date: Date = fixedDate) -> DayData {
        makeDayData(
            date: date,
            meals: [
                Meal(description: "Breakfast", quantity: .medium, satisfaction: .hundred),
                Meal(description: "Lunch", quantity: .medium, satisfaction: .hundred),
            ],
            workouts: [Workout(description: "Walk", duration: Workout.Duration(minutes: 30))],
            water: 0.5,
            mood: .sad
        )
    }

    /// Creates an incomplete day (should result in `.incomplete` status).
    /// Only has 1 category filled (meals only).
    @MainActor
    static func makeIncompleteDay(date: Date = fixedDate) -> DayData {
        makeDayData(
            date: date,
            meals: [Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty)]
        )
    }

    /// Creates an empty day (should result in `.noData` status).
    /// No meals, workouts, water, or mood recorded.
    @MainActor
    static func makeEmptyDay(date: Date = fixedDate) -> DayData {
        DayData(date: date)
    }

    // MARK: - RecordedDayData Builders

    /// Creates a `RecordedDayData` from a `DayData`, returning nil if empty.
    @MainActor
    static func makeRecordedDayData(from dayData: DayData) -> RecordedDayData? {
        RecordedDayData(dayData)
    }

    /// Creates a recorded optimal day.
    @MainActor
    static func makeRecordedOptimalDay(date: Date = fixedDate) -> RecordedDayData? {
        RecordedDayData(makeOptimalDay(date: date))
    }

    /// Creates a recorded moderate day.
    @MainActor
    static func makeRecordedModerateDay(date: Date = fixedDate) -> RecordedDayData? {
        RecordedDayData(makeModerateDay(date: date))
    }

    /// Creates a recorded poor day.
    @MainActor
    static func makeRecordedPoorDay(date: Date = fixedDate) -> RecordedDayData? {
        RecordedDayData(makePoorDay(date: date))
    }
}
