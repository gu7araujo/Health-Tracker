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
protocol HealthDataRepositoryProtocol {

    /// Loads all stored day data entries.
    /// - Returns: Array of `DayData` sorted by date, or empty array if none exist.
    func loadAllDays() -> [DayData]

    /// Saves the provided day data entries, replacing any existing data.
    /// - Parameter days: Array of `DayData` to persist.
    func save(days: [DayData])

    /// Retrieves day data for a specific date.
    /// - Parameter date: The date to look up.
    /// - Returns: The `DayData` for that date, or nil if not found.
    func dayData(for date: Date) -> DayData?

    /// Updates or creates day data for a specific date.
    /// - Parameter dayData: The `DayData` to save or update.
    func saveDayData(_ dayData: DayData)
}
