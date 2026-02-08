//
//  LoadDayDataUseCase.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/18/25.
//

import Foundation

/// Use case for loading health tracking data.
/// Encapsulates the business logic for retrieving stored day data.
final class LoadDayDataUseCase {
    private let repository: HealthDataRepositoryProtocol

    init(repository: HealthDataRepositoryProtocol) {
        self.repository = repository
    }

    /// Loads all stored day data entries.
    /// - Returns: Array of `RecordedDayData` entries (only days with actual data).
    func execute() -> [RecordedDayData] {
        repository.loadAllDays()
    }

    /// Loads day data for a specific date.
    /// If no data exists for the date, returns a new empty `DayData`.
    /// - Parameter date: The date to load data for.
    /// - Returns: The existing or newly created `DayData`.
    func execute(for date: Date) -> DayData {
        repository.dayData(for: date)?.dayData ?? DayData(date: date)
    }
}
