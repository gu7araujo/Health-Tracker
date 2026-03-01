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
    private let logger: LoggerProtocol

    init(repository: HealthDataRepositoryProtocol, logger: LoggerProtocol) {
        self.repository = repository
        self.logger = logger
    }

    /// Saves all day data entries, replacing existing data.
    /// - Parameter days: Array of `RecordedDayData` to persist (only non-empty days).
    func execute(days: [RecordedDayData]) {
        logger.debug("Saving \(days.count) days of data")
        repository.save(days: days)
        logger.info("Successfully saved \(days.count) days of data")
    }

    /// Saves or updates a single day's data.
    /// - Parameter dayData: The `RecordedDayData` to save or update.
    func execute(dayData: RecordedDayData) {
        logger.debug("Saving day data for date: \(dayData.dayData.date)")
        repository.saveDayData(dayData)
        logger.info("Day data saved successfully for date: \(dayData.dayData.date)")
    }
}
