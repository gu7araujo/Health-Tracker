//
//  IntentEnumsTests.swift
//  HealthTrackerTests
//

import Foundation
@testable import HealthTracker
import Testing

/// Raw values are persisted by saved Shortcuts, so each one is pinned to a literal here.
/// A missing `caseDisplayRepresentations` entry is a runtime `fatalError` in App Intents, so coverage is checked too.
@MainActor
struct IntentEnumsTests {
    // MARK: - MoodAppEnum

    @Test(arguments: [
        (MoodAppEnum.good, "good", Mood.good),
        (.neutral, "neutral", .neutral),
        (.sad, "sad", .sad)
    ])
    func moodAppEnum_rawValueAndDomainMapping(appEnum: MoodAppEnum, rawValue: String, mood: Mood) {
        #expect(appEnum.rawValue == rawValue)
        #expect(appEnum.mood == mood)
    }

    @Test func moodAppEnum_coversEveryDomainCaseOnce() {
        #expect(MoodAppEnum.allCases.count == Mood.allCases.count)
        #expect(Set(MoodAppEnum.allCases.map(\.mood)) == Set(Mood.allCases))
    }

    @Test func moodAppEnum_everyCaseHasDisplayRepresentation() {
        #expect(Set(MoodAppEnum.caseDisplayRepresentations.keys) == Set(MoodAppEnum.allCases))
    }

    // MARK: - MealSizeAppEnum

    @Test(arguments: [
        (MealSizeAppEnum.verySmall, "verySmall", Meal.Quantity.verySmall),
        (.small, "small", .small),
        (.medium, "medium", .medium),
        (.large, "large", .large)
    ])
    func mealSizeAppEnum_rawValueAndDomainMapping(
        appEnum: MealSizeAppEnum,
        rawValue: String,
        quantity: Meal.Quantity
    ) {
        #expect(appEnum.rawValue == rawValue)
        #expect(appEnum.quantity == quantity)
    }

    @Test func mealSizeAppEnum_coversEveryDomainCaseOnce() {
        #expect(MealSizeAppEnum.allCases.count == Meal.Quantity.allCases.count)
        #expect(Set(MealSizeAppEnum.allCases.map(\.quantity)) == Set(Meal.Quantity.allCases))
    }

    @Test func mealSizeAppEnum_everyCaseHasDisplayRepresentation() {
        #expect(Set(MealSizeAppEnum.caseDisplayRepresentations.keys) == Set(MealSizeAppEnum.allCases))
    }

    // MARK: - MealSatisfactionAppEnum

    @Test(arguments: [
        (MealSatisfactionAppEnum.thirty, "thirty", Meal.Satisfaction.thirty),
        (.fifty, "fifty", .fifty),
        (.eighty, "eighty", .eighty),
        (.hundred, "hundred", .hundred)
    ])
    func mealSatisfactionAppEnum_rawValueAndDomainMapping(
        appEnum: MealSatisfactionAppEnum,
        rawValue: String,
        satisfaction: Meal.Satisfaction
    ) {
        #expect(appEnum.rawValue == rawValue)
        #expect(appEnum.satisfaction == satisfaction)
    }

    @Test func mealSatisfactionAppEnum_coversEveryDomainCaseOnce() {
        #expect(MealSatisfactionAppEnum.allCases.count == Meal.Satisfaction.allCases.count)
        #expect(Set(MealSatisfactionAppEnum.allCases.map(\.satisfaction)) == Set(Meal.Satisfaction.allCases))
    }

    @Test func mealSatisfactionAppEnum_everyCaseHasDisplayRepresentation() {
        #expect(
            Set(MealSatisfactionAppEnum.caseDisplayRepresentations.keys) == Set(MealSatisfactionAppEnum.allCases)
        )
    }

    // MARK: - WorkoutIntensityAppEnum

    @Test(arguments: [
        (WorkoutIntensityAppEnum.low, "low", Workout.Intensity.low),
        (.medium, "medium", .medium),
        (.high, "high", .high)
    ])
    func workoutIntensityAppEnum_rawValueAndDomainMapping(
        appEnum: WorkoutIntensityAppEnum,
        rawValue: String,
        intensity: Workout.Intensity
    ) {
        #expect(appEnum.rawValue == rawValue)
        #expect(appEnum.intensity == intensity)
    }

    @Test func workoutIntensityAppEnum_coversEveryDomainCaseOnce() {
        #expect(WorkoutIntensityAppEnum.allCases.count == Workout.Intensity.allCases.count)
        #expect(Set(WorkoutIntensityAppEnum.allCases.map(\.intensity)) == Set(Workout.Intensity.allCases))
    }

    @Test func workoutIntensityAppEnum_everyCaseHasDisplayRepresentation() {
        #expect(
            Set(WorkoutIntensityAppEnum.caseDisplayRepresentations.keys) == Set(WorkoutIntensityAppEnum.allCases)
        )
    }
}
