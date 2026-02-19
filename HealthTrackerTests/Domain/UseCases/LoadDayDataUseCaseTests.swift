//
//  LoadDayDataUseCaseTests.swift
//  HealthTrackerTests
//
//  Tests for LoadDayDataUseCase covering all loading scenarios with mocked repository.
//

import Foundation
@testable import HealthTracker
import Testing

struct LoadDayDataUseCaseTests {
    // MARK: - Load All Days Tests

    @Test @MainActor func execute_loadAllDays_returnsDataFromRepository() throws {
        let mockRepository = MockHealthDataRepository()
        let day1 = try #require(TestDataBuilder.makeRecordedOptimalDay(date: TestDataBuilder.fixedDate))
        let day2 = try #require(TestDataBuilder.makeRecordedModerateDay(date: TestDataBuilder.fixedDatePlusOne))
        mockRepository.loadAllDaysResult = [day1, day2]

        let useCase = LoadDayDataUseCase(repository: mockRepository)
        let result = useCase.execute()

        #expect(mockRepository.loadAllDaysCalled)
        #expect(result.count == 2)
        #expect(result[0] == day1)
        #expect(result[1] == day2)
    }

    @Test @MainActor func execute_loadAllDays_returnsEmptyArray_whenNoData() {
        let mockRepository = MockHealthDataRepository()
        mockRepository.loadAllDaysResult = []

        let useCase = LoadDayDataUseCase(repository: mockRepository)
        let result = useCase.execute()

        #expect(mockRepository.loadAllDaysCalled)
        #expect(result.isEmpty)
    }

    @Test @MainActor func execute_loadAllDays_returnsSingleDay() throws {
        let mockRepository = MockHealthDataRepository()
        let day = try #require(TestDataBuilder.makeRecordedOptimalDay())
        mockRepository.loadAllDaysResult = [day]

        let useCase = LoadDayDataUseCase(repository: mockRepository)
        let result = useCase.execute()

        #expect(mockRepository.loadAllDaysCalled)
        #expect(result.count == 1)
        #expect(result[0] == day)
    }

    // MARK: - Load Day For Date Tests

    @Test @MainActor func execute_forDate_returnsExistingDay() throws {
        let mockRepository = MockHealthDataRepository()
        let date = TestDataBuilder.fixedDate
        let recordedDay = try #require(TestDataBuilder.makeRecordedOptimalDay(date: date))
        mockRepository.dayDataForDateResult = [date: recordedDay]

        let useCase = LoadDayDataUseCase(repository: mockRepository)
        let result = useCase.execute(for: date)

        #expect(mockRepository.dayDataForDateCalledWith == date)
        #expect(result == recordedDay.dayData)
    }

    @Test @MainActor func execute_forDate_returnsEmptyDay_whenNoDataExists() {
        let mockRepository = MockHealthDataRepository()
        let date = TestDataBuilder.fixedDate
        mockRepository.dayDataForDateResult = [:] // No data

        let useCase = LoadDayDataUseCase(repository: mockRepository)
        let result = useCase.execute(for: date)

        #expect(mockRepository.dayDataForDateCalledWith == date)
        #expect(result.date == date)
        #expect(result.meals.isEmpty)
        #expect(result.workouts.isEmpty)
        #expect(result.water == nil)
        #expect(result.mood == nil)
    }

    @Test @MainActor func execute_forDate_returnsEmptyDay_forDifferentDate() throws {
        let mockRepository = MockHealthDataRepository()
        let storedDate = TestDataBuilder.fixedDate
        let requestedDate = TestDataBuilder.fixedDatePlusOne
        let recordedDay = try #require(TestDataBuilder.makeRecordedOptimalDay(date: storedDate))
        mockRepository.dayDataForDateResult = [storedDate: recordedDay]

        let useCase = LoadDayDataUseCase(repository: mockRepository)
        let result = useCase.execute(for: requestedDate)

        #expect(mockRepository.dayDataForDateCalledWith == requestedDate)
        #expect(result.date == requestedDate)
        #expect(result.meals.isEmpty)
    }

    @Test @MainActor func execute_forDate_preservesAllDayDataProperties() throws {
        let mockRepository = MockHealthDataRepository()
        let date = TestDataBuilder.fixedDate
        let recordedDay = try #require(TestDataBuilder.makeRecordedOptimalDay(date: date))
        mockRepository.dayDataForDateResult = [date: recordedDay]

        let useCase = LoadDayDataUseCase(repository: mockRepository)
        let result = useCase.execute(for: date)

        #expect(result.date == date)
        #expect(result.meals.count == recordedDay.dayData.meals.count)
        #expect(result.workouts.count == recordedDay.dayData.workouts.count)
        #expect(result.water == recordedDay.dayData.water)
        #expect(result.mood == recordedDay.dayData.mood)
    }
}
