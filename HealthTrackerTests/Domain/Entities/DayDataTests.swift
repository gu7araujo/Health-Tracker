//
//  DayDataTests.swift
//  HealthTrackerTests
//
//  Comprehensive tests for DayData entity covering status computation,
//  CRUD operations for meals and workouts, and helper methods.
//

// swiftlint:disable type_body_length file_length

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct DayDataTests {
    // MARK: - Initialization Tests

    @Test func initialization_createsEmptyDayData() {
        let date = TestDataBuilder.fixedDate
        let dayData = DayData(date: date)

        #expect(dayData.date == date)
        #expect(dayData.meals.isEmpty)
        #expect(dayData.workouts.isEmpty)
        #expect(dayData.water == nil)
        #expect(dayData.mood == nil)
    }

    @Test func initialization_withAllParameters() {
        let date = TestDataBuilder.fixedDate
        let meals = [Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty)]
        let workouts = [Workout(description: "Run", duration: Workout.Duration(minutes: 30))]

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

    @Test func status_isNoData_whenEmpty() {
        let dayData = TestDataBuilder.makeEmptyDay()
        #expect(dayData.status == .noData)
    }

    @Test func status_isIncomplete_whenOnlyOneCategoryFilled() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.water = 1.5
        #expect(dayData.status == .incomplete)
    }

    @Test func status_isIncomplete_whenOnlyTwoCategoriesFilled() {
        let dayData = TestDataBuilder.makeIncompleteDay()
        #expect(dayData.status == .incomplete)
    }

    @Test func status_isOptimal_whenMeetsAllOptimalCriteria() {
        let dayData = TestDataBuilder.makeOptimalDay()
        #expect(dayData.status == .optimal)
    }

    @Test("Optimal status allows only small meals")
    func status_isOptimal_withOnlySmallMeals() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty))
        dayData.addMeal(Meal(description: "Snack", quantity: .verySmall, satisfaction: .fifty))
        dayData.addWorkout(Workout(description: "Run", duration: Workout.Duration(minutes: 30)))
        dayData.water = 2.0
        dayData.mood = .good

        #expect(dayData.status == .optimal)
    }

    @Test("Optimal status allows at most one medium meal")
    func status_isOptimal_withOneMediumMealAndSmallMeals() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty))
        dayData.addMeal(Meal(description: "Lunch", quantity: .medium, satisfaction: .eighty))
        dayData.addWorkout(Workout(description: "Run", duration: Workout.Duration(minutes: 30)))
        dayData.water = 1.8
        dayData.mood = .good

        #expect(dayData.status == .optimal)
    }

    @Test("Two medium meals prevent optimal status")
    func status_isNotOptimal_withTwoMediumMeals() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Breakfast", quantity: .medium, satisfaction: .eighty))
        dayData.addMeal(Meal(description: "Lunch", quantity: .medium, satisfaction: .eighty))
        dayData.addWorkout(Workout(description: "Run", duration: Workout.Duration(minutes: 30)))
        dayData.water = 2.0
        dayData.mood = .good

        #expect(dayData.status != .optimal)
    }

    @Test("Water below 1.8L prevents optimal status")
    func status_isNotOptimal_whenWaterBelowThreshold() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty))
        dayData.addWorkout(Workout(description: "Run", duration: Workout.Duration(minutes: 30)))
        dayData.water = 1.7
        dayData.mood = .good

        #expect(dayData.status != .optimal)
    }

    @Test("Optimal status requires good mood")
    func status_isNotOptimal_whenMoodNotGood() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty))
        dayData.addWorkout(Workout(description: "Run", duration: Workout.Duration(minutes: 30)))
        dayData.water = 2.0
        dayData.mood = .neutral

        #expect(dayData.status != .optimal)
    }

    @Test func status_isModerate_withModerateMeals() {
        let dayData = TestDataBuilder.makeModerateDay()
        #expect(dayData.status == .moderate)
    }

    @Test func status_isModerate_withModerateWater() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty))
        dayData.addWorkout(Workout(description: "Run", duration: Workout.Duration(minutes: 30)))
        dayData.water = 1.5
        dayData.mood = .good

        #expect(dayData.status == .moderate)
    }

    @Test func status_isModerate_withNeutralMood() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty))
        dayData.addWorkout(Workout(description: "Run", duration: Workout.Duration(minutes: 30)))
        dayData.water = 2.0
        dayData.mood = .neutral

        #expect(dayData.status == .moderate)
    }

    @Test func status_isPoor_whenNoModerateCriteriaMet() {
        let dayData = TestDataBuilder.makePoorDay()
        #expect(dayData.status == .poor)
    }

    @Test func status_isPoor_withLargeMealsAndLowWater() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Breakfast", quantity: .large, satisfaction: .hundred))
        dayData.addWorkout(Workout(description: "Walk", duration: Workout.Duration(minutes: 30)))
        dayData.water = 0.5
        dayData.mood = .sad

        #expect(dayData.status == .poor)
    }

    // MARK: - Workout Duration Status Tests

    @Test("Optimal status requires at least 30 minutes of workout")
    func status_isNotOptimal_whenWorkoutsBelowThirtyMinutes() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty))
        dayData.addWorkout(Workout(description: "Quick walk", duration: Workout.Duration(minutes: 15)))
        dayData.water = 2.0
        dayData.mood = .good

        #expect(dayData.status != .optimal)
        #expect(dayData.status == .moderate) // Should be moderate due to low workout duration
    }

    @Test("Optimal status with exactly 30 minutes of workout")
    func status_isOptimal_withExactlyThirtyMinutesWorkout() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty))
        dayData.addWorkout(Workout(description: "Run", duration: Workout.Duration(minutes: 30)))
        dayData.water = 2.0
        dayData.mood = .good

        #expect(dayData.status == .optimal)
    }

    @Test("Optimal status with multiple workouts totaling 30+ minutes")
    func status_isOptimal_withMultipleWorkoutsTotalingThirtyPlus() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty))
        dayData.addWorkout(Workout(description: "Morning walk", duration: Workout.Duration(minutes: 15)))
        dayData.addWorkout(Workout(description: "Evening walk", duration: Workout.Duration(minutes: 15)))
        dayData.water = 2.0
        dayData.mood = .good

        #expect(dayData.status == .optimal)
    }

    @Test("Moderate status with no workouts")
    func status_isModerate_withNoWorkouts() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty))
        dayData.water = 2.0
        dayData.mood = .good

        #expect(dayData.status == .moderate) // Moderate due to no workouts (< 30 min)
    }

    @Test("Moderate status with workouts below 30 minutes")
    func status_isModerate_withWorkoutsBelowThirty() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty))
        dayData.addWorkout(Workout(description: "Quick stretch", duration: Workout.Duration(minutes: 10)))
        dayData.water = 2.0
        dayData.mood = .good

        #expect(dayData.status == .moderate)
    }

    @Test("Poor status ignores workout duration")
    func status_isPoor_regardlessOfWorkouts() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Breakfast", quantity: .medium, satisfaction: .hundred))
        dayData.addMeal(Meal(description: "Lunch", quantity: .medium, satisfaction: .hundred))
        dayData.addWorkout(Workout(description: "Long run", duration: Workout.Duration(minutes: 120))) // Even with long workout
        dayData.water = 2.0
        dayData.mood = .good

        #expect(dayData.status == .poor) // Poor due to 2+ medium meals
    }

    @Test("One medium meal with optimal workout is optimal")
    func status_isOptimal_withOneMediumMealAndGoodWorkout() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Lunch", quantity: .medium, satisfaction: .fifty))
        dayData.addWorkout(Workout(description: "Run", duration: Workout.Duration(minutes: 60)))
        dayData.water = 2.0
        dayData.mood = .good

        #expect(dayData.status == .optimal) // 1 medium meal is allowed for optimal
    }

    @Test("Any large meal triggers poor status")
    func status_isPoor_withAnyLargeMeal() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Lunch", quantity: .large, satisfaction: .fifty))
        dayData.addWorkout(Workout(description: "Run", duration: Workout.Duration(minutes: 60)))
        dayData.water = 2.0
        dayData.mood = .good

        #expect(dayData.status == .poor) // Any large meal triggers poor
    }

    // MARK: - Meal CRUD Operations

    @Test func addMeal_increasesMealCount() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let meal = Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty)

        dayData.addMeal(meal)

        #expect(dayData.meals.count == 1)
        #expect(dayData.meals.first?.description == "Breakfast")
    }

    @Test func addMeal_preservesExistingMeals() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let meal1 = Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty)
        let meal2 = Meal(description: "Lunch", quantity: .medium, satisfaction: .eighty)

        dayData.addMeal(meal1)
        dayData.addMeal(meal2)

        #expect(dayData.meals.count == 2)
        #expect(dayData.meals[0].description == "Breakfast")
        #expect(dayData.meals[1].description == "Lunch")
    }

    @Test func updateMeal_modifiesMealProperties() {
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

    @Test func updateMeal_doesNothing_whenMealNotFound() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let meal = Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty)
        dayData.addMeal(meal)

        let nonExistentMeal = Meal(description: "Lunch", quantity: .medium, satisfaction: .eighty)
        dayData.updateMeal(nonExistentMeal)

        #expect(dayData.meals.count == 1)
        #expect(dayData.meals.first?.description == "Breakfast")
    }

    @Test func removeMeal_removesMealById() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let meal = Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty)
        dayData.addMeal(meal)

        dayData.removeMeal(id: meal.id)

        #expect(dayData.meals.isEmpty)
    }

    @Test func removeMeal_preservesOtherMeals() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let meal1 = Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty)
        let meal2 = Meal(description: "Lunch", quantity: .medium, satisfaction: .eighty)
        dayData.addMeal(meal1)
        dayData.addMeal(meal2)

        dayData.removeMeal(id: meal1.id)

        #expect(dayData.meals.count == 1)
        #expect(dayData.meals.first?.description == "Lunch")
    }

    @Test func removeMeal_doesNothing_whenMealNotFound() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let meal = Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty)
        dayData.addMeal(meal)

        let nonExistentId = UUID()
        dayData.removeMeal(id: nonExistentId)

        #expect(dayData.meals.count == 1)
    }

    // MARK: - Workout CRUD Operations

    @Test func addWorkout_increasesWorkoutCount() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let workout = Workout(description: "Morning run", duration: Workout.Duration(minutes: 30))

        dayData.addWorkout(workout)

        #expect(dayData.workouts.count == 1)
        #expect(dayData.workouts.first?.description == "Morning run")
    }

    @Test func addWorkout_preservesExistingWorkouts() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let workout1 = Workout(description: "Morning run", duration: Workout.Duration(minutes: 30))
        let workout2 = Workout(description: "Evening gym", duration: Workout.Duration(minutes: 60))

        dayData.addWorkout(workout1)
        dayData.addWorkout(workout2)

        #expect(dayData.workouts.count == 2)
        #expect(dayData.workouts[0].description == "Morning run")
        #expect(dayData.workouts[1].description == "Evening gym")
    }

    @Test func updateWorkout_modifiesWorkoutProperties() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let originalWorkout = Workout(description: "Run", duration: Workout.Duration(minutes: 30))
        dayData.addWorkout(originalWorkout)

        var updatedWorkout = originalWorkout
        updatedWorkout.duration = Workout.Duration(minutes: 60)
        updatedWorkout.description = "Long run"
        dayData.updateWorkout(updatedWorkout)

        #expect(dayData.workouts.count == 1)
        #expect(dayData.workouts.first?.id == originalWorkout.id)
        #expect(dayData.workouts.first?.duration == Workout.Duration(minutes: 60))
        #expect(dayData.workouts.first?.description == "Long run")
    }

    @Test func updateWorkout_doesNothing_whenWorkoutNotFound() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let workout = Workout(description: "Run", duration: Workout.Duration(minutes: 30))
        dayData.addWorkout(workout)

        let nonExistentWorkout = Workout(description: "Gym", duration: Workout.Duration(minutes: 60))
        dayData.updateWorkout(nonExistentWorkout)

        #expect(dayData.workouts.count == 1)
        #expect(dayData.workouts.first?.description == "Run")
    }

    @Test func removeWorkout_removesWorkoutById() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let workout = Workout(description: "Run", duration: Workout.Duration(minutes: 30))
        dayData.addWorkout(workout)

        dayData.removeWorkout(id: workout.id)

        #expect(dayData.workouts.isEmpty)
    }

    @Test func removeWorkout_preservesOtherWorkouts() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let workout1 = Workout(description: "Morning run", duration: Workout.Duration(minutes: 30))
        let workout2 = Workout(description: "Evening gym", duration: Workout.Duration(minutes: 60))
        dayData.addWorkout(workout1)
        dayData.addWorkout(workout2)

        dayData.removeWorkout(id: workout1.id)

        #expect(dayData.workouts.count == 1)
        #expect(dayData.workouts.first?.description == "Evening gym")
    }

    @Test func removeWorkout_doesNothing_whenWorkoutNotFound() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let workout = Workout(description: "Run", duration: Workout.Duration(minutes: 30))
        dayData.addWorkout(workout)

        let nonExistentId = UUID()
        dayData.removeWorkout(id: nonExistentId)

        #expect(dayData.workouts.count == 1)
    }

    // MARK: - Helper Methods Tests

    @Test func filledCategoriesCount_isZero_whenEmpty() {
        let dayData = TestDataBuilder.makeEmptyDay()
        #expect(dayData.status == .noData) // Verifies filledCategoriesCount is 0
    }

    @Test func filledCategoriesCount_isOne_withOnlyMeals() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty))
        #expect(dayData.status == .incomplete)
    }

    @Test func filledCategoriesCount_isTwo_withMealsAndWater() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty))
        dayData.water = 1.0
        // With 2 categories, should be evaluated for status (not incomplete)
        #expect(dayData.status != .incomplete)
    }

    @Test func filledCategoriesCount_isThree_withMealsWaterAndWorkouts() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty))
        dayData.addWorkout(Workout(description: "Run", duration: Workout.Duration(minutes: 30)))
        dayData.water = 1.5
        #expect(dayData.status != .incomplete)
    }

    @Test func filledCategoriesCount_isFour_withAllCategories() {
        let dayData = TestDataBuilder.makeOptimalDay()
        #expect(dayData.status != .incomplete)
    }

    // MARK: - Codable Tests

    @Test func codable_roundTrip_preservesAllData() throws {
        let original = TestDataBuilder.makeOptimalDay()

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DayData.self, from: encoded)

        #expect(decoded == original)
        #expect(decoded.meals.count == original.meals.count)
        #expect(decoded.workouts.count == original.workouts.count)
        #expect(decoded.water == original.water)
        #expect(decoded.mood == original.mood)
    }

    @Test func codable_roundTrip_withEmptyDay() throws {
        let original = TestDataBuilder.makeEmptyDay()

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DayData.self, from: encoded)

        #expect(decoded == original)
    }

    // MARK: - Equatable Tests

    @Test func equatable_sameValues_areEqual() {
        let dayData1 = TestDataBuilder.makeOptimalDay()
        let dayData2 = dayData1 // Same instance should be equal to itself

        #expect(dayData1 == dayData2)
    }

    @Test func equatable_differentDates_areNotEqual() {
        let dayData1 = TestDataBuilder.makeOptimalDay(date: TestDataBuilder.fixedDate)
        let dayData2 = TestDataBuilder.makeOptimalDay(date: TestDataBuilder.fixedDatePlusOne)

        #expect(dayData1 != dayData2)
    }

    @Test func equatable_differentMeals_areNotEqual() {
        var dayData1 = DayData(date: TestDataBuilder.fixedDate)
        dayData1.addMeal(Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty))

        var dayData2 = DayData(date: TestDataBuilder.fixedDate)
        dayData2.addMeal(Meal(description: "Lunch", quantity: .medium, satisfaction: .eighty))

        #expect(dayData1 != dayData2)
    }

    // MARK: - Identifiable Tests

    @Test func identifiable_idEqualsDate() {
        let date = TestDataBuilder.fixedDate
        let dayData = DayData(date: date)

        #expect(dayData.id == date)
    }
}

// swiftlint:enable type_body_length file_length
