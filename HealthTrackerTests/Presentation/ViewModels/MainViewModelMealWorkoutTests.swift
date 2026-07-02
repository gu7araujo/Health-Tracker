//
//  MainViewModelMealWorkoutTests.swift
//  HealthTrackerTests
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct MainViewModelMealWorkoutTests {
    private func createViewModel() -> (viewModel: MainViewModel,
                                       mockRepository: MockHealthDataRepository)
    {
        let mockRepository = MockHealthDataRepository()
        let mockLogger = MockLogger()
        let mockNotificationService = MockNotificationService()
        let viewModel = MainViewModel(
            loadUseCase: LoadDayDataUseCase(repository: mockRepository, logger: mockLogger),
            saveUseCase: SaveDayDataUseCase(repository: mockRepository, logger: mockLogger),
            cancelNotificationsUseCase: CancelNotificationsUseCase(
                notificationService: mockNotificationService, logger: mockLogger
            ),
            logger: mockLogger
        )
        return (viewModel, mockRepository)
    }

    @Test func addMeal_addsToCurrentDay() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate
        let meal = Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty)
        viewModel.addMeal(meal)
        #expect(viewModel.currentDayData?.meals.count == 1)
        #expect(viewModel.currentDayData?.meals.first?.description == "Breakfast")
        #expect(mockRepository.saveCalledWithDays != nil)
    }

    @Test func addMeal_withMultipleItems_preservesItems() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate
        let meal = Meal(items: ["Rice", "Beans", "Chicken"], quantity: .medium, satisfaction: .eighty)
        viewModel.addMeal(meal)
        let result = viewModel.meal(withId: meal.id)
        #expect(result?.items == ["Rice", "Beans", "Chicken"])
        #expect(result?.description == "Rice, Beans, Chicken")
    }

    @Test func updateMeal_modifiesExistingMeal() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate
        let originalMeal = Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty)
        viewModel.addMeal(originalMeal)
        var updatedMeal = originalMeal
        updatedMeal.quantity = .large
        viewModel.updateMeal(updatedMeal)
        #expect(viewModel.currentDayData?.meals.count == 1)
        #expect(viewModel.currentDayData?.meals.first?.quantity == .large)
    }

    @Test func meal_withId_returnsCorrectMeal() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate
        let meal = Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty)
        viewModel.addMeal(meal)
        let result = viewModel.meal(withId: meal.id)
        #expect(result?.id == meal.id)
        #expect(result?.description == "Breakfast")
    }

    @Test func meal_withId_returnsNil_whenNotFound() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate
        #expect(viewModel.meal(withId: UUID()) == nil)
    }

    @Test func deleteMeal_withId_removesMeal() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate
        let meal = Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty)
        viewModel.addMeal(meal)
        viewModel.deleteMeal(withId: meal.id)
        #expect(viewModel.currentDayData?.meals.isEmpty == true)
    }

    @Test func moveMeal_reordersItems() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate
        let meal1 = Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty)
        let meal2 = Meal(description: "Lunch", quantity: .medium, satisfaction: .eighty)
        let meal3 = Meal(description: "Dinner", quantity: .small, satisfaction: .fifty)
        viewModel.addMeal(meal1)
        viewModel.addMeal(meal2)
        viewModel.addMeal(meal3)
        mockRepository.saveCalledWithDays = nil

        viewModel.moveMeal(fromOffsets: IndexSet(integer: 2), toOffset: 0)

        #expect(viewModel.currentDayData?.meals.map(\.id) == [meal3.id, meal1.id, meal2.id])
        #expect(mockRepository.saveCalledWithDays != nil)
    }

    @Test func addWorkout_addsToCurrentDay() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate
        let workout = Workout(description: "Run", duration: Workout.Duration(minutes: 30))
        viewModel.addWorkout(workout)
        #expect(viewModel.currentDayData?.workouts.count == 1)
        #expect(viewModel.currentDayData?.workouts.first?.description == "Run")
        #expect(mockRepository.saveCalledWithDays != nil)
    }

    @Test func updateWorkout_modifiesExistingWorkout() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate
        let original = Workout(description: "Run", duration: Workout.Duration(minutes: 30))
        viewModel.addWorkout(original)
        var updated = original
        updated.duration = Workout.Duration(minutes: 60)
        viewModel.updateWorkout(updated)
        #expect(viewModel.currentDayData?.workouts.first?.duration == Workout.Duration(minutes: 60))
    }

    @Test func workout_withId_returnsCorrectWorkout() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate
        let workout = Workout(description: "Run", duration: Workout.Duration(minutes: 30))
        viewModel.addWorkout(workout)
        let result = viewModel.workout(withId: workout.id)
        #expect(result?.id == workout.id)
        #expect(result?.description == "Run")
    }

    @Test func workout_withId_returnsNil_whenNotFound() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate
        #expect(viewModel.workout(withId: UUID()) == nil)
    }

    @Test func deleteWorkout_withId_removesWorkout() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate
        let workout = Workout(description: "Run", duration: Workout.Duration(minutes: 30))
        viewModel.addWorkout(workout)
        viewModel.deleteWorkout(withId: workout.id)
        #expect(viewModel.currentDayData?.workouts.isEmpty == true)
    }

    @Test func moveWorkout_reordersItems() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate
        let workout1 = Workout(description: "Run", duration: Workout.Duration(minutes: 30))
        let workout2 = Workout(description: "Gym", duration: Workout.Duration(minutes: 60))
        let workout3 = Workout(description: "Swim", duration: Workout.Duration(minutes: 45))
        viewModel.addWorkout(workout1)
        viewModel.addWorkout(workout2)
        viewModel.addWorkout(workout3)
        mockRepository.saveCalledWithDays = nil

        viewModel.moveWorkout(fromOffsets: IndexSet(integer: 2), toOffset: 0)

        #expect(viewModel.currentDayData?.workouts.map(\.id) == [workout3.id, workout1.id, workout2.id])
        #expect(mockRepository.saveCalledWithDays != nil)
    }

    @Test func multipleOperations_maintainConsistentState() {
        let (viewModel, _) = createViewModel()
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate
        viewModel.updateWater(2.0)
        viewModel.updateMood(.good)
        viewModel.addMeal(Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty))
        viewModel.addWorkout(Workout(description: "Run", duration: Workout.Duration(minutes: 30)))
        let current = viewModel.currentDayData
        #expect(current?.water == 2.0)
        #expect(current?.mood == .good)
        #expect(current?.meals.count == 1)
        #expect(current?.workouts.count == 1)
    }
}
