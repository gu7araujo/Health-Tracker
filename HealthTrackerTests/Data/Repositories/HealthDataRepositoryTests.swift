//
//  HealthDataRepositoryTests.swift
//  HealthTrackerTests
//
//  Tests for HealthDataRepository covering all repository operations with mocked data source.
//

import Foundation
@testable import HealthTracker
import Testing

struct HealthDataRepositoryTests {
    // MARK: - Load All Days Tests

    @Test @MainActor func loadAllDays_returnsDataFromDataSource() throws {
        let mockDataSource = MockLocalDataSource()
        let day1 = try #require(TestDataBuilder.makeRecordedOptimalDay(date: TestDataBuilder.fixedDate))
        let day2 = try #require(TestDataBuilder.makeRecordedModerateDay(date: TestDataBuilder.fixedDatePlusOne))
        mockDataSource.loadResult = [day1, day2]

        let repository = HealthDataRepository(dataSource: mockDataSource)
        let result = repository.loadAllDays()

        #expect(mockDataSource.loadCalled)
        #expect(result.count == 2)
        #expect(result[0] == day1)
        #expect(result[1] == day2)
    }

    @Test @MainActor func loadAllDays_returnsEmptyArray_whenNoData() {
        let mockDataSource = MockLocalDataSource()
        mockDataSource.loadResult = []

        let repository = HealthDataRepository(dataSource: mockDataSource)
        let result = repository.loadAllDays()

        #expect(mockDataSource.loadCalled)
        #expect(result.isEmpty)
    }

    // MARK: - Save Days Tests

    @Test @MainActor func save_callsDataSourceWithCorrectData() throws {
        let mockDataSource = MockLocalDataSource()
        let day1 = try #require(TestDataBuilder.makeRecordedOptimalDay())
        let day2 = try #require(TestDataBuilder.makeRecordedModerateDay())
        let days = [day1, day2]

        let repository = HealthDataRepository(dataSource: mockDataSource)
        repository.save(days: days)

        #expect(mockDataSource.saveCalledWith != nil)
        #expect(mockDataSource.saveCalledWith?.count == 2)
        #expect(mockDataSource.saveCalledWith?[0] == day1)
        #expect(mockDataSource.saveCalledWith?[1] == day2)
    }

    // MARK: - Day Data For Date Tests

    @Test @MainActor func dayData_forDate_findsExistingDay() throws {
        let mockDataSource = MockLocalDataSource()
        let date = TestDataBuilder.fixedDate
        let day = try #require(TestDataBuilder.makeRecordedOptimalDay(date: date))
        mockDataSource.loadResult = [day]

        let repository = HealthDataRepository(dataSource: mockDataSource)
        let result = repository.dayData(for: date)

        #expect(result == day)
    }

    @Test @MainActor func dayData_forDate_returnsNil_whenNoMatch() {
        let mockDataSource = MockLocalDataSource()
        mockDataSource.loadResult = []

        let repository = HealthDataRepository(dataSource: mockDataSource)
        let result = repository.dayData(for: TestDataBuilder.fixedDate)

        #expect(result == nil)
    }

    @Test @MainActor func dayData_forDate_matchesSameCalendarDay() throws {
        let mockDataSource = MockLocalDataSource()
        // Create a date at noon in the current calendar
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: TestDataBuilder.fixedDate)
        components.hour = 12
        components.minute = 0
        let storedDate = try #require(calendar.date(from: components))

        // Create another date at 3 PM on the same day
        var queryComponents = components
        queryComponents.hour = 15
        let queryDate = try #require(calendar.date(from: queryComponents))

        let storedDay = TestDataBuilder.makeOptimalDay(date: storedDate)
        let recorded = try #require(RecordedDayData(storedDay))
        mockDataSource.loadResult = [recorded]

        let repository = HealthDataRepository(dataSource: mockDataSource)
        let result = repository.dayData(for: queryDate)

        // Should find the day because they're on the same calendar day
        #expect(result != nil)
    }

    @Test @MainActor func dayData_forDate_doesNotMatchDifferentDay() throws {
        let mockDataSource = MockLocalDataSource()
        let storedDate = TestDataBuilder.fixedDate
        let queryDate = TestDataBuilder.fixedDatePlusOne

        let day = try #require(TestDataBuilder.makeRecordedOptimalDay(date: storedDate))
        mockDataSource.loadResult = [day]

        let repository = HealthDataRepository(dataSource: mockDataSource)
        let result = repository.dayData(for: queryDate)

        #expect(result == nil)
    }

    // MARK: - Save Day Data Tests

    @Test @MainActor func saveDayData_addsNewDay_whenNotExists() throws {
        let mockDataSource = MockLocalDataSource()
        mockDataSource.loadResult = []

        let newDay = try #require(TestDataBuilder.makeRecordedOptimalDay())

        let repository = HealthDataRepository(dataSource: mockDataSource)
        repository.saveDayData(newDay)

        #expect(mockDataSource.saveCalledWith != nil)
        #expect(mockDataSource.saveCalledWith?.count == 1)
        #expect(mockDataSource.saveCalledWith?[0] == newDay)
    }

    @Test @MainActor func saveDayData_updatesExistingDay_whenDateMatches() throws {
        let mockDataSource = MockLocalDataSource()
        let date = TestDataBuilder.fixedDate
        let originalDay = try #require(TestDataBuilder.makeRecordedOptimalDay(date: date))
        mockDataSource.loadResult = [originalDay]

        let updatedDay = try #require(TestDataBuilder.makeRecordedModerateDay(date: date))

        let repository = HealthDataRepository(dataSource: mockDataSource)
        repository.saveDayData(updatedDay)

        #expect(mockDataSource.saveCalledWith != nil)
        #expect(mockDataSource.saveCalledWith?.count == 1)
        #expect(mockDataSource.saveCalledWith?[0] == updatedDay)
    }

    @Test @MainActor func saveDayData_preservesOtherDays() throws {
        let mockDataSource = MockLocalDataSource()
        let day1 = try #require(TestDataBuilder.makeRecordedOptimalDay(date: TestDataBuilder.fixedDate))
        let day2 = try #require(TestDataBuilder.makeRecordedPoorDay(date: TestDataBuilder.fixedDatePlusOne))
        mockDataSource.loadResult = [day1, day2]

        let updatedDay1 = try #require(TestDataBuilder.makeRecordedModerateDay(date: TestDataBuilder.fixedDate))

        let repository = HealthDataRepository(dataSource: mockDataSource)
        repository.saveDayData(updatedDay1)

        let saved = mockDataSource.saveCalledWith
        #expect(saved?.count == 2)
        #expect(saved?[0] == updatedDay1)
        #expect(saved?[1] == day2)
    }

    @Test @MainActor func saveDayData_matchesSameCalendarDay_forUpdate() throws {
        let mockDataSource = MockLocalDataSource()
        // Create days for testing - using same fixed date
        let originalDay = TestDataBuilder.makeOptimalDay(date: TestDataBuilder.fixedDate)
        let recordedOriginal = try #require(RecordedDayData(originalDay))
        mockDataSource.loadResult = [recordedOriginal]

        // Create an update for the same calendar day (same date in this case)
        let updatedDay = TestDataBuilder.makeModerateDay(date: TestDataBuilder.fixedDate)
        let recordedUpdated = try #require(RecordedDayData(updatedDay))

        let repository = HealthDataRepository(dataSource: mockDataSource)
        repository.saveDayData(recordedUpdated)

        // Should have replaced the original day (same calendar day), so still 1 day total
        #expect(mockDataSource.saveCalledWith != nil)
        #expect(mockDataSource.saveCalledWith?.count == 1)
    }
}
