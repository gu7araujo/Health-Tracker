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
