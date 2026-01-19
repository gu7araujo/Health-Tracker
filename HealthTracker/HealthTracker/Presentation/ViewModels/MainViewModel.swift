//
//  MainViewModel.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/18/25.
//

import Foundation

/// ViewModel for the main health tracking view.
/// Extracts business logic from the view and coordinates with use cases.
@Observable
final class MainViewModel {
    // MARK: - Dependencies

    private let loadUseCase: LoadDayDataUseCase
    private let saveUseCase: SaveDayDataUseCase

    // MARK: - State

    private(set) var days: [DayData] = []
    var selectedDate: Date = .init() {
        didSet {
            ensureDayDataExists(for: selectedDate)
        }
    }

    // MARK: - Computed Properties

    /// Returns the day data for the currently selected date.
    var currentDayData: DayData? {
        days.first { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    /// Returns the index of the current day data in the days array.
    private var currentDayIndex: Int? {
        days.firstIndex { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    // MARK: - Initialization

    init(
        loadUseCase: LoadDayDataUseCase,
        saveUseCase: SaveDayDataUseCase
    ) {
        self.loadUseCase = loadUseCase
        self.saveUseCase = saveUseCase
    }

    /// Convenience initializer with default dependencies.
    convenience init(repository: HealthDataRepositoryProtocol = HealthDataRepository()) {
        self.init(
            loadUseCase: LoadDayDataUseCase(repository: repository),
            saveUseCase: SaveDayDataUseCase(repository: repository)
        )
    }

    // MARK: - Public Methods

    /// Loads initial data from storage.
    func loadData() {
        days = loadUseCase.execute()
        ensureDayDataExists(for: selectedDate)
    }

    // MARK: - Water Management

    /// Updates water intake for the current day.
    /// - Parameter value: The new water intake value in liters.
    func updateWater(_ value: Double) {
        guard let index = currentDayIndex else { return }
        days[index].water = value
        persistChanges()
    }

    /// Creates a binding-compatible getter/setter for water intake.
    var waterIntake: Double {
        get { currentDayData?.water ?? 0 }
        set { updateWater(newValue) }
    }

    // MARK: - Mood Management

    /// Updates mood for the current day.
    /// - Parameter mood: The new mood value.
    func updateMood(_ mood: Mood) {
        guard let index = currentDayIndex else { return }
        days[index].mood = mood
        persistChanges()
    }

    // MARK: - Meal Management

    /// Adds a new meal to the current day.
    /// - Parameter meal: The meal to add.
    func addMeal(_ meal: Meal) {
        guard let index = currentDayIndex else { return }
        days[index].addMeal(meal)
        persistChanges()
    }

    /// Updates an existing meal.
    /// - Parameter meal: The updated meal data.
    func updateMeal(_ meal: Meal) {
        guard let index = currentDayIndex else { return }
        days[index].updateMeal(meal)
        persistChanges()
    }

    /// Retrieves a meal by ID for editing.
    /// - Parameter id: The meal's unique identifier.
    /// - Returns: The meal if found, nil otherwise.
    func meal(withId id: UUID) -> Meal? {
        currentDayData?.meals.first { $0.id == id }
    }

    /// Deletes a meal by ID from the current day.
    /// - Parameter id: The meal's unique identifier.
    func deleteMeal(withId id: UUID) {
        guard let index = currentDayIndex else { return }
        days[index].removeMeal(id: id)
        persistChanges()
    }

    // MARK: - Workout Management

    /// Adds a new workout to the current day.
    /// - Parameter workout: The workout to add.
    func addWorkout(_ workout: Workout) {
        guard let index = currentDayIndex else { return }
        days[index].addWorkout(workout)
        persistChanges()
    }

    /// Updates an existing workout.
    /// - Parameter workout: The updated workout data.
    func updateWorkout(_ workout: Workout) {
        guard let index = currentDayIndex else { return }
        days[index].updateWorkout(workout)
        persistChanges()
    }

    /// Retrieves a workout by ID for editing.
    /// - Parameter id: The workout's unique identifier.
    /// - Returns: The workout if found, nil otherwise.
    func workout(withId id: UUID) -> Workout? {
        currentDayData?.workouts.first { $0.id == id }
    }

    /// Deletes a workout by ID from the current day.
    /// - Parameter id: The workout's unique identifier.
    func deleteWorkout(withId id: UUID) {
        guard let index = currentDayIndex else { return }
        days[index].removeWorkout(id: id)
        persistChanges()
    }

    // MARK: - Private Methods

    /// Ensures day data exists for the given date, creating it if necessary.
    private func ensureDayDataExists(for date: Date) {
        let dateExists = days.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }

        if !dateExists {
            let newDayData = DayData(date: date)
            days.append(newDayData)
            persistChanges()
        }
    }

    /// Persists the current state to storage.
    private func persistChanges() {
        saveUseCase.execute(days: days)
    }
}
