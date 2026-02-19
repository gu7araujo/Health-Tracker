//
//  MockHealthDataRepository.swift
//  HealthTrackerTests
//
//  Created for testing purposes.
//

import Foundation
@testable import HealthTracker

/// Mock implementation of `HealthDataRepositoryProtocol` for testing.
/// Allows tests to control return values and verify method calls.
final class MockHealthDataRepository: HealthDataRepositoryProtocol {
    // MARK: - Stored Results

    var loadAllDaysResult: [RecordedDayData] = []
    var dayDataForDateResult: [Date: RecordedDayData] = [:]

    // MARK: - Call Tracking

    var saveCalledWithDays: [RecordedDayData]?
    var saveDayDataCalledWith: RecordedDayData?
    var dayDataForDateCalledWith: Date?
    var loadAllDaysCalled = false

    // MARK: - Protocol Implementation

    func loadAllDays() -> [RecordedDayData] {
        loadAllDaysCalled = true
        return loadAllDaysResult
    }

    func save(days: [RecordedDayData]) {
        saveCalledWithDays = days
    }

    func dayData(for date: Date) -> RecordedDayData? {
        dayDataForDateCalledWith = date

        // Check if we have an exact match in our result dictionary
        if let result = dayDataForDateResult[date] {
            return result
        }

        // Check if we have a match on the same calendar day (ignoring time)
        let calendar = Calendar.current
        return dayDataForDateResult.first { key, _ in
            calendar.isDate(key, inSameDayAs: date)
        }?.value
    }

    func saveDayData(_ dayData: RecordedDayData) {
        saveDayDataCalledWith = dayData
    }
}
