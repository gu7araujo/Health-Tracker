//
//  SaveDayDataUseCase.swift
//  HealthTracker
//
//  Domain Use Case - Business logic for saving health data
//

import Foundation

/// Use case for saving health tracking data.
/// Encapsulates the business logic for persisting day data.
final class SaveDayDataUseCase {

    private let repository: HealthDataRepositoryProtocol

    init(repository: HealthDataRepositoryProtocol) {
        self.repository = repository
    }

    /// Saves all day data entries, replacing existing data.
    /// - Parameter days: Array of `DayData` to persist.
    func execute(days: [DayData]) {
        repository.save(days: days)
    }

    /// Saves or updates a single day's data.
    /// - Parameter dayData: The `DayData` to save or update.
    func execute(dayData: DayData) {
        repository.saveDayData(dayData)
    }
}
