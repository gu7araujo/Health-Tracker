//
//  AddMealIntentTests.swift
//  HealthTrackerTests
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct AddMealIntentTests {
    // Swift Testing builds a fresh suite instance per test, so each test gets its own mock
    private let mockRepository = MockHealthDataRepository()
    private let useCase: UpdateDayDataUseCase

    init() {
        useCase = UpdateDayDataUseCase(repository: mockRepository, logger: MockLogger())
    }

    private func makeIntent(
        items: String,
        size: MealSizeAppEnum = .small,
        satisfaction: MealSatisfactionAppEnum? = nil
    ) -> AddMealIntent {
        let intent = AddMealIntent()
        intent.items = items
        intent.size = size
        intent.satisfaction = satisfaction
        return intent
    }

    @Test func run_splitsTrimsAndDropsBlankItems() throws {
        let intent = makeIntent(items: " Rice, beans ,, salad ")

        try intent.run(with: useCase, on: TestDataBuilder.fixedDate)

        let saved = try #require(mockRepository.saveDayDataCalledWith)
        #expect(saved.dayData.meals.map(\.items) == [["Rice", "beans", "salad"]])
        #expect(mockRepository.dayDataForDateCalledWith == TestDataBuilder.fixedDate)
    }

    @Test func run_withoutSatisfaction_usesSizeDefault() throws {
        let intent = makeIntent(items: "Pasta", size: .medium)

        try intent.run(with: useCase, on: TestDataBuilder.fixedDate)

        let meal = try #require(mockRepository.saveDayDataCalledWith?.dayData.meals.first)
        #expect(meal.quantity == .medium)
        #expect(meal.satisfaction == .eighty)
    }

    @Test func run_withSatisfaction_usesIt() throws {
        let intent = makeIntent(items: "Pizza", size: .large, satisfaction: .thirty)

        try intent.run(with: useCase, on: TestDataBuilder.fixedDate)

        let meal = try #require(mockRepository.saveDayDataCalledWith?.dayData.meals.first)
        #expect(meal.quantity == .large)
        #expect(meal.satisfaction == .thirty)
    }

    @Test func run_appendsToExistingMeals() throws {
        let intent = makeIntent(items: "Dinner")
        let breakfast = Meal(description: "Breakfast")
        mockRepository.dayDataForDateResult[TestDataBuilder.fixedDate] = RecordedDayData(
            DayData(date: TestDataBuilder.fixedDate, meals: [breakfast])
        )

        try intent.run(with: useCase, on: TestDataBuilder.fixedDate)

        let meals = try #require(mockRepository.saveDayDataCalledWith?.dayData.meals)
        #expect(meals.map(\.items) == [["Breakfast"], ["Dinner"]])
        #expect(meals.first == breakfast)
    }

    @Test func run_blankItems_throwsWithoutSaving() {
        let intent = makeIntent(items: " , ")

        #expect(throws: (any Error).self) {
            try intent.run(with: useCase, on: TestDataBuilder.fixedDate)
        }
        #expect(mockRepository.saveDayDataCalledWith == nil)
        #expect(mockRepository.saveCalledWithDays == nil)
    }

    @Test func registerUndo_removesOnlyTheAddedMeal() throws {
        let intent = makeIntent(items: "Snack")
        let breakfast = Meal(description: "Breakfast")
        mockRepository.dayDataForDateResult[TestDataBuilder.fixedDate] = RecordedDayData(
            DayData(date: TestDataBuilder.fixedDate, meals: [breakfast])
        )
        let change = try intent.run(with: useCase, on: TestDataBuilder.fixedDate)
        // A meal logged in the app after the intent ran must survive the undo
        let lunch = Meal(description: "Lunch")
        var current = try #require(mockRepository.saveDayDataCalledWith?.dayData)
        current.addMeal(lunch)
        mockRepository.dayDataForDateResult[TestDataBuilder.fixedDate] = RecordedDayData(current)

        try UndoManager.registerAndUndo(against: mockRepository) {
            intent.registerUndo(on: $0, useCase: $1, change: change)
        }

        let meals = try #require(mockRepository.saveDayDataCalledWith?.dayData.meals)
        #expect(meals == [breakfast, lunch])
    }

    @Test func parameterSummary_bindsItemsAndListsSizeAndSatisfaction() {
        let summary = AddMealIntent.parameterSummary

        #expect(summary.sentenceFormat == "intent_add_meal_summary ${parameter0}")
        #expect(summary.sentenceParameters(of: AddMealIntent.self) == [\AddMealIntent.$items])
        #expect(
            summary.listedParameters(of: AddMealIntent.self) == [\AddMealIntent.$size, \AddMealIntent.$satisfaction]
        )
    }
}
