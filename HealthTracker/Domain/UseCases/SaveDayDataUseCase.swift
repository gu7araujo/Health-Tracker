//
//  SaveDayDataUseCase.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/18/25.
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
    /// - Parameter days: Array of `RecordedDayData` to persist (only non-empty days).
    func execute(days: [RecordedDayData]) {
        repository.save(days: days)
    }

    /// Saves or updates a single day's data.
    /// - Parameter dayData: The `RecordedDayData` to save or update.
    func execute(dayData: RecordedDayData) {
        repository.saveDayData(dayData)
    }
}
