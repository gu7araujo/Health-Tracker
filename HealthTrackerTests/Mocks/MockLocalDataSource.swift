//
//  MockLocalDataSource.swift
//  HealthTrackerTests
//
//  Created for testing purposes.
//

import Foundation
@testable import HealthTracker

/// Mock implementation of `LocalDataSourceProtocol` for testing.
/// Allows tests to control return values, simulate errors, and verify method calls.
final class MockLocalDataSource: LocalDataSourceProtocol {
    // MARK: - Stored Results

    var loadResult: [RecordedDayData] = []

    // MARK: - Error Simulation

    var shouldThrowOnLoad = false
    var shouldThrowOnSave = false

    // MARK: - Call Tracking

    var saveCalledWith: [RecordedDayData]?
    var loadCalled = false

    // MARK: - Protocol Implementation

    func load() -> [RecordedDayData] {
        loadCalled = true
        return loadResult
    }

    func save(_ days: [RecordedDayData]) {
        saveCalledWith = days
    }
}
