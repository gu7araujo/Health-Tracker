//
//  RecordedDayDataTests.swift
//  HealthTrackerTests
//
//  Tests for RecordedDayData entity covering failable initializer validation.
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct RecordedDayDataTests {
    // MARK: - Failable Initializer Tests

    @Test func initialization_returnsNil_whenCompletelyEmpty() {
        let dayData = TestDataBuilder.makeEmptyDay()
        let recordedDayData = RecordedDayData(dayData)

        #expect(recordedDayData == nil)
    }

    @Test func initialization_succeeds_withOnlyMeals() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty))

        let recordedDayData = RecordedDayData(dayData)

        #expect(recordedDayData != nil)
        #expect(recordedDayData?.dayData.meals.count == 1)
    }

    @Test func initialization_succeeds_withOnlyWorkouts() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addWorkout(Workout(description: "Run", duration: .thirtyMin))

        let recordedDayData = RecordedDayData(dayData)

        #expect(recordedDayData != nil)
        #expect(recordedDayData?.dayData.workouts.count == 1)
    }

    @Test func initialization_succeeds_withOnlyWater() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.water = 1.5

        let recordedDayData = RecordedDayData(dayData)

        #expect(recordedDayData != nil)
        #expect(recordedDayData?.dayData.water == 1.5)
    }

    @Test func initialization_succeeds_withOnlyMood() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.mood = .good

        let recordedDayData = RecordedDayData(dayData)

        #expect(recordedDayData != nil)
        #expect(recordedDayData?.dayData.mood == .good)
    }

    @Test func initialization_succeeds_withMealsAndWater() {
        let dayData = TestDataBuilder.makeIncompleteDay()
        let recordedDayData = RecordedDayData(dayData)

        #expect(recordedDayData != nil)
        #expect(recordedDayData?.dayData.meals.count == 1)
        #expect(recordedDayData?.dayData.water == 1.0)
    }

    @Test func initialization_succeeds_withAllCategories() {
        let dayData = TestDataBuilder.makeOptimalDay()
        let recordedDayData = RecordedDayData(dayData)

        #expect(recordedDayData != nil)
        #expect(recordedDayData?.dayData.meals.count == 2)
        #expect(recordedDayData?.dayData.workouts.count == 1)
        #expect(recordedDayData?.dayData.water == 2.0)
        #expect(recordedDayData?.dayData.mood == .good)
    }

    @Test func initialization_preservesAllDayDataProperties() {
        let original = TestDataBuilder.makeOptimalDay()
        let recorded = RecordedDayData(original)

        #expect(recorded?.dayData == original)
        #expect(recorded?.dayData.date == original.date)
        #expect(recorded?.dayData.meals == original.meals)
        #expect(recorded?.dayData.workouts == original.workouts)
        #expect(recorded?.dayData.water == original.water)
        #expect(recorded?.dayData.mood == original.mood)
    }

    // MARK: - Identifiable Tests

    @Test func identifiable_idEqualsDate() {
        let date = TestDataBuilder.fixedDate
        var dayData = DayData(date: date)
        dayData.water = 1.5

        let recordedDayData = RecordedDayData(dayData)

        #expect(recordedDayData?.id == date)
    }

    // MARK: - Equatable Tests

    @Test func equatable_sameValues_areEqual() {
        let dayData = TestDataBuilder.makeOptimalDay()
        let recorded1 = RecordedDayData(dayData)
        let recorded2 = RecordedDayData(dayData)

        #expect(recorded1 == recorded2)
    }

    @Test func equatable_differentDates_areNotEqual() {
        let dayData1 = TestDataBuilder.makeOptimalDay(date: TestDataBuilder.fixedDate)
        let dayData2 = TestDataBuilder.makeOptimalDay(date: TestDataBuilder.fixedDatePlusOne)

        let recorded1 = RecordedDayData(dayData1)
        let recorded2 = RecordedDayData(dayData2)

        #expect(recorded1 != recorded2)
    }

    @Test func equatable_differentMeals_areNotEqual() {
        var dayData1 = DayData(date: TestDataBuilder.fixedDate)
        dayData1.addMeal(Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty))

        var dayData2 = DayData(date: TestDataBuilder.fixedDate)
        dayData2.addMeal(Meal(description: "Lunch", quantity: .medium, satisfaction: .eighty))

        let recorded1 = RecordedDayData(dayData1)
        let recorded2 = RecordedDayData(dayData2)

        #expect(recorded1 != recorded2)
    }
}
