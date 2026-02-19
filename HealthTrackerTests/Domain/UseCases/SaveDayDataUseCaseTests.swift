//
//  SaveDayDataUseCaseTests.swift
//  HealthTrackerTests
//
//  Tests for SaveDayDataUseCase covering batch and single save operations with mocked repository.
//

import Foundation
@testable import HealthTracker
import Testing

struct SaveDayDataUseCaseTests {
    // MARK: - Batch Save Tests

    @Test @MainActor func execute_saveDays_callsRepositoryWithCorrectData() throws {
        let mockRepository = MockHealthDataRepository()
        let day1 = try #require(TestDataBuilder.makeRecordedOptimalDay(date: TestDataBuilder.fixedDate))
        let day2 = try #require(TestDataBuilder.makeRecordedModerateDay(date: TestDataBuilder.fixedDatePlusOne))
        let days = [day1, day2]

        let useCase = SaveDayDataUseCase(repository: mockRepository)
        useCase.execute(days: days)

        #expect(mockRepository.saveCalledWithDays != nil)
        #expect(mockRepository.saveCalledWithDays?.count == 2)
        #expect(mockRepository.saveCalledWithDays?[0] == day1)
        #expect(mockRepository.saveCalledWithDays?[1] == day2)
    }

    @Test @MainActor func execute_saveDays_withEmptyArray() {
        let mockRepository = MockHealthDataRepository()

        let useCase = SaveDayDataUseCase(repository: mockRepository)
        useCase.execute(days: [])

        #expect(mockRepository.saveCalledWithDays != nil)
        #expect(mockRepository.saveCalledWithDays?.isEmpty == true)
    }

    @Test @MainActor func execute_saveDays_withSingleDay() throws {
        let mockRepository = MockHealthDataRepository()
        let day = try #require(TestDataBuilder.makeRecordedOptimalDay())

        let useCase = SaveDayDataUseCase(repository: mockRepository)
        useCase.execute(days: [day])

        #expect(mockRepository.saveCalledWithDays != nil)
        #expect(mockRepository.saveCalledWithDays?.count == 1)
        #expect(mockRepository.saveCalledWithDays?[0] == day)
    }

    // MARK: - Single Day Save Tests

    @Test @MainActor func execute_saveDayData_callsRepositoryWithCorrectData() throws {
        let mockRepository = MockHealthDataRepository()
        let day = try #require(TestDataBuilder.makeRecordedOptimalDay())

        let useCase = SaveDayDataUseCase(repository: mockRepository)
        useCase.execute(dayData: day)

        #expect(mockRepository.saveDayDataCalledWith != nil)
        #expect(mockRepository.saveDayDataCalledWith == day)
    }

    @Test @MainActor func execute_saveDayData_withModerateDay() throws {
        let mockRepository = MockHealthDataRepository()
        let day = try #require(TestDataBuilder.makeRecordedModerateDay())

        let useCase = SaveDayDataUseCase(repository: mockRepository)
        useCase.execute(dayData: day)

        #expect(mockRepository.saveDayDataCalledWith != nil)
        #expect(mockRepository.saveDayDataCalledWith == day)
    }

    @Test @MainActor func execute_saveDayData_withPoorDay() throws {
        let mockRepository = MockHealthDataRepository()
        let day = try #require(TestDataBuilder.makeRecordedPoorDay())

        let useCase = SaveDayDataUseCase(repository: mockRepository)
        useCase.execute(dayData: day)

        #expect(mockRepository.saveDayDataCalledWith != nil)
        #expect(mockRepository.saveDayDataCalledWith == day)
    }

    @Test @MainActor func execute_saveDayData_preservesAllProperties() throws {
        let mockRepository = MockHealthDataRepository()
        let day = try #require(TestDataBuilder.makeRecordedOptimalDay())

        let useCase = SaveDayDataUseCase(repository: mockRepository)
        useCase.execute(dayData: day)

        let saved = mockRepository.saveDayDataCalledWith
        #expect(saved?.dayData.date == day.dayData.date)
        #expect(saved?.dayData.meals == day.dayData.meals)
        #expect(saved?.dayData.workouts == day.dayData.workouts)
        #expect(saved?.dayData.water == day.dayData.water)
        #expect(saved?.dayData.mood == day.dayData.mood)
    }
}
