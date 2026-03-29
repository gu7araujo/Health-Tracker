//
//  MainViewModelTests.swift
//  HealthTrackerTests
//
//  Comprehensive tests for MainViewModel covering all operations with mocked use cases.
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct MainViewModelTests {
    // MARK: - Test Helpers

    private func createViewModel() -> (viewModel: MainViewModel,
                                       mockRepository: MockHealthDataRepository)
    {
        let mockRepository = MockHealthDataRepository()
        let mockLogger = MockLogger()
        let loadUseCase = LoadDayDataUseCase(repository: mockRepository, logger: mockLogger)
        let saveUseCase = SaveDayDataUseCase(repository: mockRepository, logger: mockLogger)
        let mockNotificationService = MockNotificationService()
        let cancelNotificationsUseCase = CancelNotificationsUseCase(notificationService: mockNotificationService, logger: mockLogger)
        let viewModel = MainViewModel(
            loadUseCase: loadUseCase,
            saveUseCase: saveUseCase,
            cancelNotificationsUseCase: cancelNotificationsUseCase,
            logger: mockLogger
        )
        return (viewModel, mockRepository)
    }

    // MARK: - Initialization Tests

    @Test func initialization_setsDefaultState() {
        let (viewModel, _) = createViewModel()

        #expect(viewModel.days.isEmpty)
    }

    // MARK: - Load Data Tests

    @Test func loadData_loadsFromRepository() throws {
        let (viewModel, mockRepository) = createViewModel()
        let day1 = try #require(TestDataBuilder.makeRecordedOptimalDay(date: TestDataBuilder.fixedDate))
        let day2 = try #require(TestDataBuilder.makeRecordedModerateDay(date: TestDataBuilder.fixedDatePlusOne))
        mockRepository.loadAllDaysResult = [day1, day2]

        // Set selected date to one of the existing days to avoid creating an extra day
        viewModel.selectedDate = day1.dayData.date
        viewModel.loadData()

        // Should have loaded 2 days from repository (no extra day created since selectedDate matches day1)
        #expect(viewModel.days.count == 2)
        #expect(Calendar.current.isDate(viewModel.days[0].date, inSameDayAs: day1.dayData.date))
        #expect(Calendar.current.isDate(viewModel.days[1].date, inSameDayAs: day2.dayData.date))
    }

    @Test func loadData_createsEmptyDayForSelectedDate() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.selectedDate = TestDataBuilder.fixedDate

        viewModel.loadData()

        #expect(viewModel.days.count == 1)
        #expect(viewModel.days[0].meals.isEmpty)
    }

    // MARK: - Date Selection Tests

    @Test func selectedDate_change_ensuresDayDataExists() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []

        // Set the selected date before loading to ensure the day is created
        viewModel.selectedDate = TestDataBuilder.fixedDate
        viewModel.loadData()

        #expect(viewModel.days.count == 1)
        #expect(Calendar.current.isDate(viewModel.days[0].date, inSameDayAs: TestDataBuilder.fixedDate))
    }

    @Test func selectedDate_change_doesNotDuplicateExistingDay() throws {
        let (viewModel, mockRepository) = createViewModel()
        let existingDay = try #require(TestDataBuilder.makeRecordedOptimalDay(date: TestDataBuilder.fixedDate))
        mockRepository.loadAllDaysResult = [existingDay]

        // Set the selected date to match the existing day's date
        viewModel.selectedDate = TestDataBuilder.fixedDate
        viewModel.loadData()

        // Changing to the same date should not duplicate
        viewModel.selectedDate = TestDataBuilder.fixedDate

        #expect(viewModel.days.count == 1)
    }

    // MARK: - Current Day Data Tests

    @Test func currentDayData_returnsCorrectDay() throws {
        let (viewModel, mockRepository) = createViewModel()
        let day1 = try #require(TestDataBuilder.makeRecordedOptimalDay(date: TestDataBuilder.fixedDate))
        let day2 = try #require(TestDataBuilder.makeRecordedModerateDay(date: TestDataBuilder.fixedDatePlusOne))
        mockRepository.loadAllDaysResult = [day1, day2]
        viewModel.loadData()

        viewModel.selectedDate = TestDataBuilder.fixedDate

        #expect(viewModel.currentDayData?.date == day1.dayData.date)
    }

    // MARK: - Water Management Tests

    @Test func updateWater_updatesCurrentDay() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate

        viewModel.updateWater(1.5)

        #expect(viewModel.currentDayData?.water == 1.5)
        #expect(mockRepository.saveCalledWithDays != nil)
    }

    @Test func updateWater_zeroRemovesWater() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate

        viewModel.updateWater(2.0)
        viewModel.updateWater(0)

        #expect(viewModel.currentDayData?.water == nil)
    }

    @Test func waterIntake_getter_returnsCurrentWater() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate

        viewModel.updateWater(2.5)

        #expect(viewModel.waterIntake == 2.5)
    }

    @Test func waterIntake_getter_returnsZero_whenNil() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate

        #expect(viewModel.waterIntake == 0)
    }

    // MARK: - Mood Management Tests

    @Test func updateMood_updatesCurrentDay() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate

        viewModel.updateMood(.good)

        #expect(viewModel.currentDayData?.mood == .good)
        #expect(mockRepository.saveCalledWithDays != nil)
    }

    @Test func updateMood_changesMood() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate

        viewModel.updateMood(.good)
        viewModel.updateMood(.sad)

        #expect(viewModel.currentDayData?.mood == .sad)
    }

    // MARK: - Meal Management Tests

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

        let result = viewModel.meal(withId: UUID())

        #expect(result == nil)
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

    // MARK: - Workout Management Tests

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

        let originalWorkout = Workout(description: "Run", duration: Workout.Duration(minutes: 30))
        viewModel.addWorkout(originalWorkout)

        var updatedWorkout = originalWorkout
        updatedWorkout.duration = Workout.Duration(minutes: 60)
        viewModel.updateWorkout(updatedWorkout)

        #expect(viewModel.currentDayData?.workouts.count == 1)
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

        let result = viewModel.workout(withId: UUID())

        #expect(result == nil)
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

    // MARK: - State Consistency Tests

    @Test func multipleOperations_maintainConsistentState() {
        let (viewModel, _) = createViewModel()
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate

        // Perform multiple operations
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

    @Test func dateSwitch_preservesData() throws {
        let (viewModel, mockRepository) = createViewModel()
        let day1 = try #require(TestDataBuilder.makeRecordedOptimalDay(date: TestDataBuilder.fixedDate))
        let day2 = try #require(TestDataBuilder.makeRecordedModerateDay(date: TestDataBuilder.fixedDatePlusOne))
        mockRepository.loadAllDaysResult = [day1, day2]
        viewModel.loadData()

        viewModel.selectedDate = TestDataBuilder.fixedDate
        let firstDate = viewModel.currentDayData?.date

        viewModel.selectedDate = TestDataBuilder.fixedDatePlusOne
        let secondDate = viewModel.currentDayData?.date

        viewModel.selectedDate = TestDataBuilder.fixedDate
        let backToFirst = viewModel.currentDayData?.date

        #expect(firstDate == day1.dayData.date)
        #expect(secondDate == day2.dayData.date)
        #expect(backToFirst == day1.dayData.date)
    }
}
