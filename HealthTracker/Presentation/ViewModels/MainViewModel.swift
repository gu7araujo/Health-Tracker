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
    private let cancelNotificationsUseCase: CancelNotificationsUseCase
    private let logger: LoggerProtocol

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

    /// Returns the status explanation for the currently selected day.
    var currentDayExplanation: String? {
        currentDayData?.statusExplanation
    }

    /// Returns the day status for the currently selected day.
    var currentDayStatus: DayStatus {
        currentDayData?.status ?? .noData
    }

    // MARK: - Initialization

    init(
        loadUseCase: LoadDayDataUseCase,
        saveUseCase: SaveDayDataUseCase,
        cancelNotificationsUseCase: CancelNotificationsUseCase,
        logger: LoggerProtocol = LoggerFactory.presentationLogger(category: "MainViewModel")
    ) {
        self.loadUseCase = loadUseCase
        self.saveUseCase = saveUseCase
        self.cancelNotificationsUseCase = cancelNotificationsUseCase
        self.logger = logger
    }

    /// Convenience initializer with default dependencies.
    convenience init(
        // The production composition root: the one place Presentation builds Data types.
        // swiftlint:disable:next presentation_no_data_layer
        repository: HealthDataRepositoryProtocol = HealthDataRepository(),
        // swiftlint:disable:next presentation_no_data_layer
        notificationService: NotificationServiceProtocol = NotificationService()
    ) {
        self.init(
            loadUseCase: LoadDayDataUseCase(
                repository: repository,
                logger: LoggerFactory.domainLogger(category: "Data.Load")
            ),
            saveUseCase: SaveDayDataUseCase(
                repository: repository,
                logger: LoggerFactory.domainLogger(category: "Data.Save")
            ),
            cancelNotificationsUseCase: CancelNotificationsUseCase(
                notificationService: notificationService,
                logger: LoggerFactory.domainLogger(category: "Notifications.Cancel")
            )
        )
    }

    // MARK: - Public Methods

    /// Loads initial data from storage.
    /// Converts `RecordedDayData` from the persistence layer back to `DayData` for in-memory use.
    func loadData() {
        logger.debug("Loading day data from storage")
        days = loadUseCase.execute().map(\.dayData)
        ensureDayDataExists(for: selectedDate)
        logger.info("Loaded \(days.count) day(s) from storage")
    }

    // MARK: - Water Management

    /// Updates water intake for the current day.
    /// - Parameter value: The new water intake value in liters.
    func updateWater(_ value: Double) {
        guard let index = currentDayIndex else {
            logger.error("Failed to update water: no current day data")
            return
        }
        logger.debug("Updating water intake to \(value)L")
        // If value is 0, treat it as removing the water information
        days[index].water = value > 0 ? value : nil
        persistChanges()
        logger.info("Water intake updated successfully")
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
        guard let index = currentDayIndex else {
            logger.error("Failed to update mood: no current day data")
            return
        }
        logger.debug("Updating mood to \(mood)")
        days[index].mood = mood
        persistChanges()
        logger.info("Mood updated successfully")
    }

    // MARK: - Meal Management

    /// Adds a new meal to the current day.
    /// - Parameter meal: The meal to add.
    func addMeal(_ meal: Meal) {
        guard let index = currentDayIndex else {
            logger.error("Failed to add meal: no current day data")
            return
        }
        logger.debug("Adding meal: \(meal.description)")
        days[index].addMeal(meal)
        persistChanges()
        logger.info("Meal added successfully")
    }

    /// Updates an existing meal.
    /// - Parameter meal: The updated meal data.
    func updateMeal(_ meal: Meal) {
        guard let index = currentDayIndex else {
            logger.error("Failed to update meal: no current day data")
            return
        }
        logger.debug("Updating meal: \(meal.description)")
        days[index].updateMeal(meal)
        persistChanges()
        logger.info("Meal updated successfully")
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
        guard let index = currentDayIndex else {
            logger.error("Failed to delete meal: no current day data")
            return
        }
        logger.debug("Deleting meal with ID: \(id)")
        days[index].removeMeal(id: id)
        persistChanges()
        logger.info("Meal deleted successfully")
    }

    /// Reorders meals within the current day.
    /// - Parameters:
    ///   - source: The offsets of the meals being moved.
    ///   - destination: The offset to move the meals to.
    func moveMeal(fromOffsets source: IndexSet, toOffset destination: Int) {
        guard let index = currentDayIndex else {
            logger.error("Failed to move meal: no current day data")
            return
        }
        days[index].moveMeal(fromOffsets: source, toOffset: destination)
        persistChanges()
        logger.info("Meal moved successfully")
    }

    // MARK: - Workout Management

    /// Adds a new workout to the current day.
    /// - Parameter workout: The workout to add.
    func addWorkout(_ workout: Workout) {
        guard let index = currentDayIndex else {
            logger.error("Failed to add workout: no current day data")
            return
        }
        logger.debug("Adding workout: \(workout.description)")
        days[index].addWorkout(workout)
        persistChanges()
        logger.info("Workout added successfully")
    }

    /// Updates an existing workout.
    /// - Parameter workout: The updated workout data.
    func updateWorkout(_ workout: Workout) {
        guard let index = currentDayIndex else {
            logger.error("Failed to update workout: no current day data")
            return
        }
        logger.debug("Updating workout: \(workout.description)")
        days[index].updateWorkout(workout)
        persistChanges()
        logger.info("Workout updated successfully")
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
        guard let index = currentDayIndex else {
            logger.error("Failed to delete workout: no current day data")
            return
        }
        logger.debug("Deleting workout with ID: \(id)")
        days[index].removeWorkout(id: id)
        persistChanges()
        logger.info("Workout deleted successfully")
    }

    /// Reorders workouts within the current day.
    /// - Parameters:
    ///   - source: The offsets of the workouts being moved.
    ///   - destination: The offset to move the workouts to.
    func moveWorkout(fromOffsets source: IndexSet, toOffset destination: Int) {
        guard let index = currentDayIndex else {
            logger.error("Failed to move workout: no current day data")
            return
        }
        days[index].moveWorkout(fromOffsets: source, toOffset: destination)
        persistChanges()
        logger.info("Workout moved successfully")
    }

    // MARK: - Private Methods

    /// Ensures day data exists in memory for the given date, creating it if necessary.
    /// Does NOT persist the empty entry — only non-empty days are written to storage.
    private func ensureDayDataExists(for date: Date) {
        let dateExists = days.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }

        if !dateExists {
            days.append(DayData(date: date))
        }
    }

    /// Persists the current state to storage.
    /// Parses `DayData` to `RecordedDayData`, filtering out empty entries by construction.
    private func persistChanges() {
        logger.debug("Persisting changes to storage")
        let recordedDays = days.compactMap(RecordedDayData.init)
        saveUseCase.execute(days: recordedDays)

        // Cancel notifications after successful save (NOTIF-11, NOTIF-12)
        // Fire-and-forget: don't await, don't block save flow
        Task {
            do {
                try await cancelNotificationsUseCase.execute()
                logger.debug("Notification cancellation triggered after save")
            } catch {
                logger.error("Failed to cancel notifications: \(error.localizedDescription)")
            }
        }
    }
}
