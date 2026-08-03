//
//  HealthDataRepositoryTests.swift
//  HealthTrackerTests
//
//  Tests for HealthDataRepository covering all repository operations with mocked data source.
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct HealthDataRepositoryTests {
    // MARK: - Load All Days Tests

    @Test func loadAllDays_returnsDataFromDataSource() throws {
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

    @Test func loadAllDays_returnsEmptyArray_whenNoData() {
        let mockDataSource = MockLocalDataSource()
        mockDataSource.loadResult = []

        let repository = HealthDataRepository(dataSource: mockDataSource)
        let result = repository.loadAllDays()

        #expect(mockDataSource.loadCalled)
        #expect(result.isEmpty)
    }

    // MARK: - Save Days Tests

    @Test func save_callsDataSourceWithCorrectData() throws {
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

    @Test func dayData_forDate_findsExistingDay() throws {
        let mockDataSource = MockLocalDataSource()
        let date = TestDataBuilder.fixedDate
        let day = try #require(TestDataBuilder.makeRecordedOptimalDay(date: date))
        mockDataSource.loadResult = [day]

        let repository = HealthDataRepository(dataSource: mockDataSource)
        let result = repository.dayData(for: date)

        #expect(result == day)
    }

    @Test func dayData_forDate_returnsNil_whenNoMatch() {
        let mockDataSource = MockLocalDataSource()
        mockDataSource.loadResult = []

        let repository = HealthDataRepository(dataSource: mockDataSource)
        let result = repository.dayData(for: TestDataBuilder.fixedDate)

        #expect(result == nil)
    }

    @Test("Finds day data even with different times on same calendar day")
    func dayData_forDate_matchesSameCalendarDay() throws {
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

    @Test("Returns nil when querying different calendar day")
    func dayData_forDate_doesNotMatchDifferentDay() throws {
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

    @Test func saveDayData_addsNewDay_whenNotExists() throws {
        let mockDataSource = MockLocalDataSource()
        mockDataSource.loadResult = []

        let newDay = try #require(TestDataBuilder.makeRecordedOptimalDay())

        let repository = HealthDataRepository(dataSource: mockDataSource)
        repository.saveDayData(newDay)

        #expect(mockDataSource.saveCalledWith != nil)
        #expect(mockDataSource.saveCalledWith?.count == 1)
        #expect(mockDataSource.saveCalledWith?[0] == newDay)
    }

    @Test func saveDayData_updatesExistingDay_whenDateMatches() throws {
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

    @Test func saveDayData_preservesOtherDays() throws {
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

    @Test("Updates existing day when saving to same calendar day")
    func saveDayData_matchesSameCalendarDay_forUpdate() throws {
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

    // MARK: - Load Days In Range Tests

    /// Returns `TestDataBuilder.fixedDate` offset by whole days in the current calendar.
    private func dayOffset(_ days: Int) throws -> Date {
        try #require(Calendar.current.date(byAdding: .day, value: days, to: TestDataBuilder.fixedDate))
    }

    @Test("Returns only days whose calendar day falls within the closed range")
    func loadDaysInRange_returnsDaysWithinRange() throws {
        let mockDataSource = MockLocalDataSource()
        let day0 = try #require(TestDataBuilder.makeRecordedOptimalDay(date: dayOffset(0)))
        let day1 = try #require(TestDataBuilder.makeRecordedModerateDay(date: dayOffset(1)))
        let day2 = try #require(TestDataBuilder.makeRecordedPoorDay(date: dayOffset(2)))
        mockDataSource.loadResult = [day0, day1, day2]

        let repository = HealthDataRepository(dataSource: mockDataSource)
        let result = try repository.loadDaysInRange(dayOffset(0) ... dayOffset(1))

        #expect(result.count == 2)
        #expect(result.contains(day0))
        #expect(result.contains(day1))
        #expect(!result.contains(day2))
    }

    @Test("Includes days that land exactly on the range boundaries")
    func loadDaysInRange_includesBoundaryDays() throws {
        let mockDataSource = MockLocalDataSource()
        let day0 = try #require(TestDataBuilder.makeRecordedOptimalDay(date: dayOffset(0)))
        let day1 = try #require(TestDataBuilder.makeRecordedModerateDay(date: dayOffset(1)))
        let day2 = try #require(TestDataBuilder.makeRecordedPoorDay(date: dayOffset(2)))
        mockDataSource.loadResult = [day0, day1, day2]

        let repository = HealthDataRepository(dataSource: mockDataSource)
        // A single-day range should still match that day (bounds are inclusive).
        let result = try repository.loadDaysInRange(dayOffset(1) ... dayOffset(1))

        #expect(result == [day1])
    }

    @Test("Ignores intra-day time when comparing against the range")
    func loadDaysInRange_matchesByCalendarDay_ignoringTime() throws {
        let mockDataSource = MockLocalDataSource()
        // Stored at 3 PM; range bounds anchored at noon on the same calendar day.
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: TestDataBuilder.fixedDate)
        components.hour = 15
        let storedDate = try #require(calendar.date(from: components))
        let stored = try #require(TestDataBuilder.makeRecordedOptimalDay(date: storedDate))
        mockDataSource.loadResult = [stored]

        let repository = HealthDataRepository(dataSource: mockDataSource)
        let result = repository.loadDaysInRange(TestDataBuilder.fixedDate ... TestDataBuilder.fixedDate)

        #expect(result == [stored])
    }

    @Test("Returns an empty array when the store is empty")
    func loadDaysInRange_returnsEmpty_whenStoreEmpty() throws {
        let mockDataSource = MockLocalDataSource()
        mockDataSource.loadResult = []

        let repository = HealthDataRepository(dataSource: mockDataSource)
        let result = try repository.loadDaysInRange(dayOffset(0) ... dayOffset(7))

        #expect(mockDataSource.loadCalled)
        #expect(result.isEmpty)
    }

    @Test("Returns an empty array when no stored day falls in the range")
    func loadDaysInRange_returnsEmpty_whenNoDayMatches() throws {
        let mockDataSource = MockLocalDataSource()
        let day0 = try #require(TestDataBuilder.makeRecordedOptimalDay(date: dayOffset(0)))
        mockDataSource.loadResult = [day0]

        let repository = HealthDataRepository(dataSource: mockDataSource)
        let result = try repository.loadDaysInRange(dayOffset(5) ... dayOffset(10))

        #expect(result.isEmpty)
    }
}
