//
//  HealthDataRepositoryProtocol.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/18/25.
//

import Foundation

/// Protocol defining the contract for health data persistence operations.
/// The Domain layer depends on this abstraction, NOT on concrete implementations.
/// This follows the Dependency Inversion Principle.
/// Works with `RecordedDayData` to ensure only non-empty days are persisted.
protocol HealthDataRepositoryProtocol {
    /// Loads all stored day data entries.
    /// - Returns: Array of `RecordedDayData` sorted by date, or empty array if none exist.
    func loadAllDays() -> [RecordedDayData]

    /// Saves the provided day data entries, replacing any existing data.
    /// - Parameter days: Array of `RecordedDayData` to persist.
    func save(days: [RecordedDayData])

    /// Retrieves recorded day data for a specific date.
    /// - Parameter date: The date to look up.
    /// - Returns: The `RecordedDayData` for that date, or nil if not found.
    func dayData(for date: Date) -> RecordedDayData?

    /// Updates or creates recorded day data for a specific date.
    /// - Parameter dayData: The `RecordedDayData` to save or update.
    func saveDayData(_ dayData: RecordedDayData)

    /// Loads recorded day data within a specific date range.
    /// - Parameter range: The date range to filter by (inclusive).
    /// - Returns: Array of `RecordedDayData` within the range, sorted by date.
    func loadDaysInRange(_ range: ClosedRange<Date>) -> [RecordedDayData]
}
