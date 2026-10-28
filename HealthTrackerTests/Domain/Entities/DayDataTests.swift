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

    @Test("Two medium meals trigger moderate status")
    func status_isModerate_withTwoMediumMeals() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Breakfast", quantity: .medium, satisfaction: .fifty))
        dayData.addMeal(Meal(description: "Lunch", quantity: .medium, satisfaction: .fifty))
        dayData.addWorkout(Workout(description: "Run", duration: Workout.Duration(minutes: 30)))
        dayData.water = 2.0
        dayData.mood = .good

        #expect(dayData.status == .moderate)
    }

    @Test("Three or more medium meals trigger poor status")
    func status_isPoor_withThreeOrMoreMediumMeals() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Breakfast", quantity: .medium, satisfaction: .fifty))
        dayData.addMeal(Meal(description: "Lunch", quantity: .medium, satisfaction: .fifty))
        dayData.addMeal(Meal(description: "Dinner", quantity: .medium, satisfaction: .fifty))
        dayData.addWorkout(Workout(description: "Run", duration: Workout.Duration(minutes: 30)))
        dayData.water = 2.0
        dayData.mood = .good

        #expect(dayData.status == .poor)
    }

    @Test("Poor status takes priority over moderate when both signals are present")
    func status_isPoor_prioritizedOverModerate() {
        // 2 medium meals (moderate meal signal) + low water (poor signal)
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "Breakfast", quantity: .medium, satisfaction: .fifty))
        dayData.addMeal(Meal(description: "Lunch", quantity: .medium, satisfaction: .fifty))
        dayData.addWorkout(Workout(description: "Run", duration: Workout.Duration(minutes: 30)))
        dayData.water = 0.5
        dayData.mood = .good

        #expect(dayData.status == .poor)
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
        dayData.addMeal(Meal(description: "Dinner", quantity: .medium, satisfaction: .hundred))
        // Even with long workout
        dayData.addWorkout(Workout(description: "Long run", duration: Workout.Duration(minutes: 120)))
        dayData.water = 2.0
        dayData.mood = .good

        #expect(dayData.status == .poor) // Poor due to 3+ medium meals
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

    @Test("Missing water counts as below 1.0L and wins over a moderate signal")
    func status_isPoor_whenWaterNilAndOtherwiseModerate() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(makeSmallMeal("A"))
        dayData.addWorkout(Workout(description: "Stretch", duration: Workout.Duration(minutes: 10)))
        dayData.mood = .good

        #expect(dayData.status == .poor)
    }

    @Test("Missing water is poor even when every other category meets optimal")
    func status_isPoor_whenWaterNilAndOtherwiseOptimal() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(makeSmallMeal("A"))
        dayData.addWorkout(Workout(description: "Run", duration: Workout.Duration(minutes: 30)))
        dayData.mood = .good

        #expect(dayData.status == .poor)
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

    @Test func moveMeal_reordersMeals() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let meal1 = Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty)
        let meal2 = Meal(description: "Lunch", quantity: .medium, satisfaction: .eighty)
        let meal3 = Meal(description: "Dinner", quantity: .small, satisfaction: .fifty)
        dayData.addMeal(meal1)
        dayData.addMeal(meal2)
        dayData.addMeal(meal3)

        dayData.moveMeal(fromOffsets: IndexSet(integer: 2), toOffset: 0)

        #expect(dayData.meals.map(\.id) == [meal3.id, meal1.id, meal2.id])
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

    @Test func moveWorkout_reordersWorkouts() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let workout1 = Workout(description: "Run", duration: Workout.Duration(minutes: 30))
        let workout2 = Workout(description: "Gym", duration: Workout.Duration(minutes: 60))
        let workout3 = Workout(description: "Swim", duration: Workout.Duration(minutes: 45))
        dayData.addWorkout(workout1)
        dayData.addWorkout(workout2)
        dayData.addWorkout(workout3)

        dayData.moveWorkout(fromOffsets: IndexSet(integer: 2), toOffset: 0)

        #expect(dayData.workouts.map(\.id) == [workout3.id, workout1.id, workout2.id])
    }

    // MARK: - Reorder Edge Cases

    private func makeSmallMeal(_ description: String) -> Meal {
        Meal(description: description, quantity: .small, satisfaction: .fifty)
    }

    @Test("Moving an element down to the end reinserts it last")
    func moveMeal_movesElementDown_toEnd() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let mealA = makeSmallMeal("A")
        let mealB = makeSmallMeal("B")
        let mealC = makeSmallMeal("C")
        dayData.addMeal(mealA)
        dayData.addMeal(mealB)
        dayData.addMeal(mealC)

        dayData.moveMeal(fromOffsets: IndexSet(integer: 0), toOffset: 3)

        #expect(dayData.meals.map(\.id) == [mealB.id, mealC.id, mealA.id])
    }

    @Test("Moving an element up shifts it toward the front")
    func moveMeal_movesElementUp() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let mealA = makeSmallMeal("A")
        let mealB = makeSmallMeal("B")
        let mealC = makeSmallMeal("C")
        dayData.addMeal(mealA)
        dayData.addMeal(mealB)
        dayData.addMeal(mealC)

        dayData.moveMeal(fromOffsets: IndexSet(integer: 1), toOffset: 0)

        #expect(dayData.meals.map(\.id) == [mealB.id, mealA.id, mealC.id])
    }

    @Test("Moving a multi-selection preserves the selected order")
    func moveMeal_movesMultipleSelection() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let mealA = makeSmallMeal("A")
        let mealB = makeSmallMeal("B")
        let mealC = makeSmallMeal("C")
        dayData.addMeal(mealA)
        dayData.addMeal(mealB)
        dayData.addMeal(mealC)

        dayData.moveMeal(fromOffsets: IndexSet([0, 1]), toOffset: 3)

        #expect(dayData.meals.map(\.id) == [mealC.id, mealA.id, mealB.id])
    }

    @Test("Moving a workout to the front reorders correctly")
    func moveWorkout_movesToFront() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        let workout1 = Workout(description: "Run", duration: Workout.Duration(minutes: 30))
        let workout2 = Workout(description: "Gym", duration: Workout.Duration(minutes: 60))
        let workout3 = Workout(description: "Swim", duration: Workout.Duration(minutes: 45))
        dayData.addWorkout(workout1)
        dayData.addWorkout(workout2)
        dayData.addWorkout(workout3)

        dayData.moveWorkout(fromOffsets: IndexSet(integer: 1), toOffset: 0)

        #expect(dayData.workouts.map(\.id) == [workout2.id, workout1.id, workout3.id])
    }

    // MARK: - Status Explanation Tests

    private func reason(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    @Test func statusExplanation_isNil_forNoData() {
        #expect(TestDataBuilder.makeEmptyDay().statusExplanation == nil)
    }

    @Test func statusExplanation_isNil_forIncomplete() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.water = 1.5
        #expect(dayData.statusExplanation == nil)
    }

    @Test func statusExplanation_optimal_returnsSuccessLine() {
        let dayData = TestDataBuilder.makeOptimalDay()
        #expect(dayData.statusExplanation == reason("day_status_explanation.optimal"))
    }

    @Test("Three medium meals surface the multiple-medium reason under the poor header")
    func statusExplanation_poor_threeMediumMeals_includesMultipleMedium() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "A", quantity: .medium, satisfaction: .fifty))
        dayData.addMeal(Meal(description: "B", quantity: .medium, satisfaction: .fifty))
        dayData.addMeal(Meal(description: "C", quantity: .medium, satisfaction: .fifty))
        dayData.water = 2.0
        dayData.mood = .good

        #expect(dayData.status == .poor)
        #expect(dayData.statusExplanation?.contains(reason("day_status_reason.meals_multiple_medium")) == true)
        #expect(dayData.statusExplanation?.contains(reason("day_status_explanation.poor")) == true)
    }

    @Test("Any large meal surfaces the multiple-medium reason")
    func statusExplanation_poor_largeMeal_includesMultipleMedium() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "A", quantity: .large, satisfaction: .fifty))
        dayData.water = 2.0
        dayData.mood = .good

        #expect(dayData.status == .poor)
        #expect(dayData.statusExplanation?.contains(reason("day_status_reason.meals_multiple_medium")) == true)
    }

    @Test("Exactly two medium meals surface the two-medium reason under the moderate header")
    func statusExplanation_moderate_twoMediumMeals_includesTwoMedium() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "A", quantity: .medium, satisfaction: .fifty))
        dayData.addMeal(Meal(description: "B", quantity: .medium, satisfaction: .fifty))
        dayData.addWorkout(Workout(description: "Run", duration: Workout.Duration(minutes: 30)))
        dayData.water = 2.0
        dayData.mood = .good

        #expect(dayData.status == .moderate)
        #expect(dayData.statusExplanation?.contains(reason("day_status_reason.meals_two_medium")) == true)
        #expect(dayData.statusExplanation?.contains(reason("day_status_explanation.moderate")) == true)
    }

    @Test("Zero water surfaces the water-none reason")
    func statusExplanation_poor_waterZero_includesWaterNone() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(makeSmallMeal("A"))
        dayData.addWorkout(Workout(description: "Run", duration: Workout.Duration(minutes: 30)))
        dayData.water = 0.0
        dayData.mood = .good

        #expect(dayData.status == .poor)
        #expect(dayData.statusExplanation?.contains(reason("day_status_reason.water_none")) == true)
    }

    @Test("Low but non-zero water surfaces the water-low reason")
    func statusExplanation_poor_waterLow_includesWaterLow() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(makeSmallMeal("A"))
        dayData.addWorkout(Workout(description: "Run", duration: Workout.Duration(minutes: 30)))
        dayData.water = 0.5
        dayData.mood = .good

        #expect(dayData.status == .poor)
        #expect(dayData.statusExplanation?.contains(reason("day_status_reason.water_low")) == true)
    }

    @Test("Water between 1.0 and 1.8 surfaces the water-moderate reason")
    func statusExplanation_moderate_waterModerate_includesWaterModerate() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(makeSmallMeal("A"))
        dayData.addWorkout(Workout(description: "Run", duration: Workout.Duration(minutes: 30)))
        dayData.water = 1.5
        dayData.mood = .good

        #expect(dayData.status == .moderate)
        #expect(dayData.statusExplanation?.contains(reason("day_status_reason.water_moderate")) == true)
    }

    @Test("No workouts surface the workout-none reason")
    func statusExplanation_moderate_noWorkout_includesWorkoutNone() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(makeSmallMeal("A"))
        dayData.water = 1.5
        dayData.mood = .good

        #expect(dayData.status == .moderate)
        #expect(dayData.statusExplanation?.contains(reason("day_status_reason.workout_none")) == true)
    }

    @Test("A short workout surfaces the workout-insufficient reason")
    func statusExplanation_moderate_shortWorkout_includesWorkoutInsufficient() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(makeSmallMeal("A"))
        dayData.addWorkout(Workout(description: "Stretch", duration: Workout.Duration(minutes: 10)))
        dayData.water = 2.0
        dayData.mood = .good

        #expect(dayData.status == .moderate)
        #expect(dayData.statusExplanation?.contains(reason("day_status_reason.workout_insufficient")) == true)
    }

    @Test("A neutral mood surfaces the mood-neutral reason")
    func statusExplanation_moderate_neutralMood_includesMoodNeutral() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(makeSmallMeal("A"))
        dayData.addWorkout(Workout(description: "Run", duration: Workout.Duration(minutes: 30)))
        dayData.water = 2.0
        dayData.mood = .neutral

        #expect(dayData.status == .moderate)
        #expect(dayData.statusExplanation?.contains(reason("day_status_reason.mood_neutral")) == true)
    }

    @Test("A sad mood surfaces the mood-sad reason")
    func statusExplanation_poor_sadMood_includesMoodSad() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(makeSmallMeal("A"))
        dayData.addWorkout(Workout(description: "Run", duration: Workout.Duration(minutes: 30)))
        dayData.water = 2.0
        dayData.mood = .sad

        #expect(dayData.status == .poor)
        #expect(dayData.statusExplanation?.contains(reason("day_status_reason.mood_sad")) == true)
    }

    @Test("Missing water counts as none and surfaces the water-none reason under the poor header")
    func statusExplanation_poor_waterNil_includesWaterNone() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(makeSmallMeal("A"))
        dayData.addWorkout(Workout(description: "Run", duration: Workout.Duration(minutes: 30)))
        dayData.mood = .good

        #expect(dayData.status == .poor)
        #expect(dayData.statusExplanation?.contains(reason("day_status_explanation.poor")) == true)
        #expect(dayData.statusExplanation?.contains(reason("day_status_reason.water_none")) == true)
    }

    @Test("A poor fallback day with no specific reasons ends with just the header and a period")
    func statusExplanation_poorFallback_withoutReasons_endsWithPeriodOnly() {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        // No meals → not optimal; water ≥ 1.8, workout ≥ 30, good mood → neither poor nor moderate → poor fallback.
        dayData.water = 2.0
        dayData.addWorkout(Workout(description: "Run", duration: Workout.Duration(minutes: 30)))
        dayData.mood = .good

        #expect(dayData.status == .poor)
        #expect(dayData.statusExplanation == reason("day_status_explanation.poor") + ".")
    }

    @Test("A poor day with reasons joins them after the header and ends with a period")
    func statusExplanation_poor_joinsReasonsWithHeaderAndPeriod() throws {
        var dayData = DayData(date: TestDataBuilder.fixedDate)
        dayData.addMeal(Meal(description: "A", quantity: .large, satisfaction: .fifty))
        dayData.water = 0.0
        dayData.mood = .sad

        #expect(dayData.status == .poor)
        let explanation = try #require(dayData.statusExplanation)
        #expect(explanation.hasPrefix(reason("day_status_explanation.poor") + ": "))
        #expect(explanation.hasSuffix("."))
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

    @Test(arguments: [HealthSection.meal, .workout])
    func healthSection_idIsTheSectionItself(section: HealthSection) {
        #expect(section.id == section)
    }
}

// swiftlint:enable type_body_length file_length
