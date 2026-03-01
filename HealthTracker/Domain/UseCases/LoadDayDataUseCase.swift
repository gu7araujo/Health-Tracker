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
    private let logger: LoggerProtocol

    init(repository: HealthDataRepositoryProtocol, logger: LoggerProtocol) {
        self.repository = repository
        self.logger = logger
    }

    /// Loads all stored day data entries.
    /// - Returns: Array of `RecordedDayData` entries (only days with actual data).
    func execute() -> [RecordedDayData] {
        logger.debug("Loading day data from repository")
        let days = repository.loadAllDays()
        logger.info("Loaded \(days.count) days of data")
        return days
    }

    /// Loads day data for a specific date.
    /// If no data exists for the date, returns a new empty `DayData`.
    /// - Parameter date: The date to load data for.
    /// - Returns: The existing or newly created `DayData`.
    func execute(for date: Date) -> DayData {
        repository.dayData(for: date)?.dayData ?? DayData(date: date)
    }
}
