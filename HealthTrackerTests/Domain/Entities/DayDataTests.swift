//
//  DayDataTests.swift
//  HealthTrackerTests
//
//  Comprehensive tests for DayData entity covering status computation,
//  CRUD operations for meals and workouts, and helper methods.
//

import Foundation
@testable import HealthTracker
import Testing

struct DayDataTests {
    // MARK: - Initialization Tests

    @Test @MainActor func initialization_createsEmptyDayData() {
        let date = TestDataBuilder.fixedDate
        let dayData = DayData(date: date)

        #expect(dayData.date == date)
        #expect(dayData.meals.isEmpty)
        #expect(dayData.workouts.isEmpty)
        #expect(dayData.water == nil)
        #expect(dayData.mood == nil)
    }

    @Test @MainActor func initialization_withAllParameters() {
        let date = TestDataBuilder.fixedDate
        let meals = [Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty)]
        let workouts = [Workout(description: "Run", duration: .thirtyMin)]

        let dayData = DayData(
            date: date,
            meals: meals,
            workouts: workouts,
            water: 1.5,
            mood: .good
        )

        #expect(dayData.date == date)
        #expect(dayData.meals.count == 1)
        #expect(dayData.workouts.count == 1)
        #expect(dayData.water == 1.5)
        #expect(dayData.mood == .good)
    }

    // MARK: - Status Computation Tests

    @Test @MainActor func status_isNoData_whenEmpty() {
        let dayData = TestDataBuilder.makeEmptyDay()
        #expect(dayData.status == .noData)
    }

    @Test @MainActor func status_isIncomplete_whenOnlyOneCategoryFilled() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.water = 1.5
        #expect(dayData.status == .incomplete)
    }

    @Test @MainActor func status_isIncomplete_whenOnlyTwoCategoriesFilled() {
        let dayData = TestDataBuilder.makeIncompleteDay()
        #expect(dayData.status == .incomplete)
    }

    @Test @MainActor func status_isOptimal_whenMeetsAllOptimalCriteria() {
        let dayData = TestDataBuilder.makeOptimalDay()
        #expect(dayData.status == .optimal)
    }

    @Test @MainActor func status_isOptimal_withOnlySmallMeals() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty))
        dayData.addMeal(Meal(description: "Snack", quantity: .verySmall, satisfaction: .fifty))
        dayData.addWorkout(Workout(description: "Run", duration: .thirtyMin))
        dayData.water = 2.0
        dayData.mood = .good

        #expect(dayData.status == .optimal)
    }

    @Test @MainActor func status_isOptimal_withOneMediumMealAndSmallMeals() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty))
        dayData.addMeal(Meal(description: "Lunch", quantity: .medium, satisfaction: .eighty))
        dayData.addWorkout(Workout(description: "Run", duration: .thirtyMin))
        dayData.water = 1.8
        dayData.mood = .good

        #expect(dayData.status == .optimal)
    }

    @Test @MainActor func status_isNotOptimal_withTwoMediumMeals() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Breakfast", quantity: .medium, satisfaction: .eighty))
        dayData.addMeal(Meal(description: "Lunch", quantity: .medium, satisfaction: .eighty))
        dayData.addWorkout(Workout(description: "Run", duration: .thirtyMin))
        dayData.water = 2.0
        dayData.mood = .good

        #expect(dayData.status != .optimal)
    }

    @Test @MainActor func status_isNotOptimal_whenWaterBelowThreshold() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty))
        dayData.addWorkout(Workout(description: "Run", duration: .thirtyMin))
        dayData.water = 1.7
        dayData.mood = .good

        #expect(dayData.status != .optimal)
    }

    @Test @MainActor func status_isNotOptimal_whenMoodNotGood() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty))
        dayData.addWorkout(Workout(description: "Run", duration: .thirtyMin))
        dayData.water = 2.0
        dayData.mood = .neutral

        #expect(dayData.status != .optimal)
    }

    @Test @MainActor func status_isModerate_withModerateMeals() {
        let dayData = TestDataBuilder.makeModerateDay()
        #expect(dayData.status == .moderate)
    }

    @Test @MainActor func status_isModerate_withModerateWater() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty))
        dayData.addWorkout(Workout(description: "Run", duration: .thirtyMin))
        dayData.water = 1.5
        dayData.mood = .good

        #expect(dayData.status == .moderate)
    }

    @Test @MainActor func status_isModerate_withNeutralMood() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty))
        dayData.addWorkout(Workout(description: "Run", duration: .thirtyMin))
        dayData.water = 2.0
        dayData.mood = .neutral

        #expect(dayData.status == .moderate)
    }

    @Test @MainActor func status_isPoor_whenNoModerateCriteriaMet() {
        let dayData = TestDataBuilder.makePoorDay()
        #expect(dayData.status == .poor)
    }

    @Test @MainActor func status_isPoor_withLargeMealsAndLowWater() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Breakfast", quantity: .large, satisfaction: .hundred))
        dayData.addWorkout(Workout(description: "Walk", duration: .thirtyMin))
        dayData.water = 0.5
        dayData.mood = .sad

        #expect(dayData.status == .poor)
    }

    // MARK: - Meal CRUD Operations

    @Test @MainActor func addMeal_increasesMealCount() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let meal = Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty)

        dayData.addMeal(meal)

        #expect(dayData.meals.count == 1)
        #expect(dayData.meals.first?.description == "Breakfast")
    }

    @Test @MainActor func addMeal_preservesExistingMeals() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let meal1 = Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty)
        let meal2 = Meal(description: "Lunch", quantity: .medium, satisfaction: .eighty)

        dayData.addMeal(meal1)
        dayData.addMeal(meal2)

        #expect(dayData.meals.count == 2)
        #expect(dayData.meals[0].description == "Breakfast")
        #expect(dayData.meals[1].description == "Lunch")
    }

    @Test @MainActor func updateMeal_modifiesMealProperties() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let originalMeal = Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty)
        dayData.addMeal(originalMeal)

        var updatedMeal = originalMeal
        updatedMeal.quantity = .large
        updatedMeal.satisfaction = .hundred
        dayData.updateMeal(updatedMeal)

        #expect(dayData.meals.count == 1)
        #expect(dayData.meals.first?.id == originalMeal.id)
        #expect(dayData.meals.first?.quantity == .large)
        #expect(dayData.meals.first?.satisfaction == .hundred)
    }

    @Test @MainActor func updateMeal_doesNothing_whenMealNotFound() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let meal = Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty)
        dayData.addMeal(meal)

        let nonExistentMeal = Meal(description: "Lunch", quantity: .medium, satisfaction: .eighty)
        dayData.updateMeal(nonExistentMeal)

        #expect(dayData.meals.count == 1)
        #expect(dayData.meals.first?.description == "Breakfast")
    }

    @Test @MainActor func removeMeal_removesMealById() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let meal = Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty)
        dayData.addMeal(meal)

        dayData.removeMeal(id: meal.id)

        #expect(dayData.meals.isEmpty)
    }

    @Test @MainActor func removeMeal_preservesOtherMeals() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let meal1 = Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty)
        let meal2 = Meal(description: "Lunch", quantity: .medium, satisfaction: .eighty)
        dayData.addMeal(meal1)
        dayData.addMeal(meal2)

        dayData.removeMeal(id: meal1.id)

        #expect(dayData.meals.count == 1)
        #expect(dayData.meals.first?.description == "Lunch")
    }

    @Test @MainActor func removeMeal_doesNothing_whenMealNotFound() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let meal = Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty)
        dayData.addMeal(meal)

        let nonExistentId = UUID()
        dayData.removeMeal(id: nonExistentId)

        #expect(dayData.meals.count == 1)
    }

    // MARK: - Workout CRUD Operations

    @Test @MainActor func addWorkout_increasesWorkoutCount() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let workout = Workout(description: "Morning run", duration: .thirtyMin)

        dayData.addWorkout(workout)

        #expect(dayData.workouts.count == 1)
        #expect(dayData.workouts.first?.description == "Morning run")
    }

    @Test @MainActor func addWorkout_preservesExistingWorkouts() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let workout1 = Workout(description: "Morning run", duration: .thirtyMin)
        let workout2 = Workout(description: "Evening gym", duration: .oneHour)

        dayData.addWorkout(workout1)
        dayData.addWorkout(workout2)

        #expect(dayData.workouts.count == 2)
        #expect(dayData.workouts[0].description == "Morning run")
        #expect(dayData.workouts[1].description == "Evening gym")
    }

    @Test @MainActor func updateWorkout_modifiesWorkoutProperties() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let originalWorkout = Workout(description: "Run", duration: .thirtyMin)
        dayData.addWorkout(originalWorkout)

        var updatedWorkout = originalWorkout
        updatedWorkout.duration = .oneHour
        updatedWorkout.description = "Long run"
        dayData.updateWorkout(updatedWorkout)

        #expect(dayData.workouts.count == 1)
        #expect(dayData.workouts.first?.id == originalWorkout.id)
        #expect(dayData.workouts.first?.duration == .oneHour)
        #expect(dayData.workouts.first?.description == "Long run")
    }

    @Test @MainActor func updateWorkout_doesNothing_whenWorkoutNotFound() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let workout = Workout(description: "Run", duration: .thirtyMin)
        dayData.addWorkout(workout)

        let nonExistentWorkout = Workout(description: "Gym", duration: .oneHour)
        dayData.updateWorkout(nonExistentWorkout)

        #expect(dayData.workouts.count == 1)
        #expect(dayData.workouts.first?.description == "Run")
    }

    @Test @MainActor func removeWorkout_removesWorkoutById() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let workout = Workout(description: "Run", duration: .thirtyMin)
        dayData.addWorkout(workout)

        dayData.removeWorkout(id: workout.id)

        #expect(dayData.workouts.isEmpty)
    }

    @Test @MainActor func removeWorkout_preservesOtherWorkouts() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let workout1 = Workout(description: "Morning run", duration: .thirtyMin)
        let workout2 = Workout(description: "Evening gym", duration: .oneHour)
        dayData.addWorkout(workout1)
        dayData.addWorkout(workout2)

        dayData.removeWorkout(id: workout1.id)

        #expect(dayData.workouts.count == 1)
        #expect(dayData.workouts.first?.description == "Evening gym")
    }

    @Test @MainActor func removeWorkout_doesNothing_whenWorkoutNotFound() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let workout = Workout(description: "Run", duration: .thirtyMin)
        dayData.addWorkout(workout)

        let nonExistentId = UUID()
        dayData.removeWorkout(id: nonExistentId)

        #expect(dayData.workouts.count == 1)
    }

    // MARK: - Helper Methods Tests

    @Test @MainActor func filledCategoriesCount_isZero_whenEmpty() {
        let dayData = TestDataBuilder.makeEmptyDay()
        #expect(dayData.status == .noData) // Verifies filledCategoriesCount is 0
    }

    @Test @MainActor func filledCategoriesCount_isOne_withOnlyMeals() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty))
        #expect(dayData.status == .incomplete)
    }

    @Test @MainActor func filledCategoriesCount_isTwo_withMealsAndWater() {
        let dayData = TestDataBuilder.makeIncompleteDay()
        #expect(dayData.status == .incomplete)
    }

    @Test @MainActor func filledCategoriesCount_isThree_withMealsWaterAndWorkouts() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty))
        dayData.addWorkout(Workout(description: "Run", duration: .thirtyMin))
        dayData.water = 1.5
        #expect(dayData.status != .incomplete)
    }

    @Test @MainActor func filledCategoriesCount_isFour_withAllCategories() {
        let dayData = TestDataBuilder.makeOptimalDay()
        #expect(dayData.status != .incomplete)
    }

    // MARK: - Codable Tests

    @Test @MainActor func codable_roundTrip_preservesAllData() throws {
        let original = TestDataBuilder.makeOptimalDay()

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DayData.self, from: encoded)

        #expect(decoded == original)
        #expect(decoded.meals.count == original.meals.count)
        #expect(decoded.workouts.count == original.workouts.count)
        #expect(decoded.water == original.water)
        #expect(decoded.mood == original.mood)
    }

    @Test @MainActor func codable_roundTrip_withEmptyDay() throws {
        let original = TestDataBuilder.makeEmptyDay()

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DayData.self, from: encoded)

        #expect(decoded == original)
    }

    // MARK: - Equatable Tests

    @Test @MainActor func equatable_sameValues_areEqual() {
        let dayData1 = TestDataBuilder.makeOptimalDay()
        let dayData2 = dayData1 // Same instance should be equal to itself

        #expect(dayData1 == dayData2)
    }

    @Test @MainActor func equatable_differentDates_areNotEqual() {
        let dayData1 = TestDataBuilder.makeOptimalDay(date: TestDataBuilder.fixedDate)
        let dayData2 = TestDataBuilder.makeOptimalDay(date: TestDataBuilder.fixedDatePlusOne)

        #expect(dayData1 != dayData2)
    }

    @Test @MainActor func equatable_differentMeals_areNotEqual() {
        var dayData1 = DayData(date: TestDataBuilder.fixedDate)
        dayData1.addMeal(Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty))

        var dayData2 = DayData(date: TestDataBuilder.fixedDate)
        dayData2.addMeal(Meal(description: "Lunch", quantity: .medium, satisfaction: .eighty))

        #expect(dayData1 != dayData2)
    }

    // MARK: - Identifiable Tests

    @Test @MainActor func identifiable_idEqualsDate() {
        let date = TestDataBuilder.fixedDate
        let dayData = DayData(date: date)

        #expect(dayData.id == date)
    }
}
