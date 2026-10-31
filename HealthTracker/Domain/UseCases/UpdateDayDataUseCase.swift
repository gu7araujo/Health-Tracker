//
//  UpdateDayDataUseCase.swift
//  HealthTracker
//

import Foundation

/// A day's data before and after a change, so callers can report or undo it.
typealias DayDataChange = (before: DayData, after: DayData)

/// Use case for changing one day's data against the latest stored copy (load → mutate → persist).
/// Used by App Intents and their undo actions, which run outside `MainViewModel`'s in-memory state.
final class UpdateDayDataUseCase {
    private let repository: HealthDataRepositoryProtocol
    private let logger: LoggerProtocol

    init(repository: HealthDataRepositoryProtocol, logger: LoggerProtocol) {
        self.repository = repository
        self.logger = logger
    }

    /// Applies a change to one day and persists it.
    /// If the change leaves the day empty, the day is removed instead, so only recorded days are stored.
    /// A change that leaves the day as it was writes nothing.
    /// - Parameters:
    ///   - date: The day to change.
    ///   - change: The mutation to apply.
    /// - Returns: The day before and after the change.
    @discardableResult
    func execute(for date: Date, _ change: (inout DayData) -> Void) -> DayDataChange {
        let before = repository.dayData(for: date)?.dayData ?? DayData(date: date)
        var after = before
        change(&after)
        guard after != before else { return (before, after) }

        if let recorded = RecordedDayData(after) {
            repository.saveDayData(recorded)
            logger.info("Updated day data for date: \(date)")
        } else {
            repository.save(days: repository.loadAllDays().filter {
                !Calendar.current.isDate($0.dayData.date, inSameDayAs: date)
            })
            logger.info("Removed now-empty day data for date: \(date)")
        }
        return (before, after)
    }
}
