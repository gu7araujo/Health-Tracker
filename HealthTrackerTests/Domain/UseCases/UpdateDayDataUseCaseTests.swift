//
//  UpdateDayDataUseCaseTests.swift
//  HealthTrackerTests
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct UpdateDayDataUseCaseTests {
    private func createUseCase() -> (useCase: UpdateDayDataUseCase, mockRepository: MockHealthDataRepository) {
        let mockRepository = MockHealthDataRepository()
        let useCase = UpdateDayDataUseCase(repository: mockRepository, logger: MockLogger())
        return (useCase, mockRepository)
    }

    @Test func execute_noStoredDay_createsAndSavesDay() throws {
        let (useCase, mockRepository) = createUseCase()

        useCase.execute(for: TestDataBuilder.fixedDate) { $0.mood = .good }

        let saved = try #require(mockRepository.saveDayDataCalledWith)
        #expect(saved.dayData == DayData(date: TestDataBuilder.fixedDate, mood: .good))
        #expect(mockRepository.dayDataForDateCalledWith == TestDataBuilder.fixedDate)
    }

    @Test func execute_existingDay_appliesChangeAndKeepsOtherFields() throws {
        let (useCase, mockRepository) = createUseCase()
        let meal = Meal(description: "Lunch")
        let stored = try #require(RecordedDayData(DayData(date: TestDataBuilder.fixedDate, meals: [meal], water: 1.0)))
        mockRepository.dayDataForDateResult[TestDataBuilder.fixedDate] = stored

        useCase.execute(for: TestDataBuilder.fixedDate) { $0.mood = .sad }

        let saved = try #require(mockRepository.saveDayDataCalledWith)
        #expect(saved.dayData == DayData(date: TestDataBuilder.fixedDate, meals: [meal], water: 1.0, mood: .sad))
    }

    @Test func execute_returnsDayBeforeAndAfterChange() throws {
        let (useCase, mockRepository) = createUseCase()
        let stored = try #require(RecordedDayData(DayData(date: TestDataBuilder.fixedDate, water: 1.0)))
        mockRepository.dayDataForDateResult[TestDataBuilder.fixedDate] = stored

        let change = useCase.execute(for: TestDataBuilder.fixedDate) { $0.water = 1.25 }

        #expect(change.before == DayData(date: TestDataBuilder.fixedDate, water: 1.0))
        #expect(change.after == DayData(date: TestDataBuilder.fixedDate, water: 1.25))
    }

    @Test func execute_changeLeavesDayEmpty_dropsItAndKeepsOtherDays() throws {
        let (useCase, mockRepository) = createUseCase()
        let emptied = try #require(RecordedDayData(DayData(date: TestDataBuilder.fixedDate, mood: .good)))
        let other = try #require(TestDataBuilder.makeRecordedOptimalDay(date: TestDataBuilder.fixedDatePlusOne))
        mockRepository.dayDataForDateResult[TestDataBuilder.fixedDate] = emptied
        mockRepository.loadAllDaysResult = [emptied, other]

        useCase.execute(for: TestDataBuilder.fixedDate) { $0.mood = nil }

        #expect(mockRepository.saveCalledWithDays == [other])
        #expect(mockRepository.saveDayDataCalledWith == nil)
    }

    @Test func execute_changeLeavesDayUnchanged_savesNothing() throws {
        let (useCase, mockRepository) = createUseCase()
        let stored = try #require(RecordedDayData(DayData(date: TestDataBuilder.fixedDate, water: 5.0)))
        mockRepository.dayDataForDateResult[TestDataBuilder.fixedDate] = stored

        let change = useCase.execute(for: TestDataBuilder.fixedDate) { $0.addWater(liters: 0.25) }

        #expect(change.after == stored.dayData)
        #expect(mockRepository.saveDayDataCalledWith == nil)
        #expect(mockRepository.saveCalledWithDays == nil)
    }

    @Test func execute_noStoredDayAndChangeLeavesItEmpty_savesNothing() {
        let (useCase, mockRepository) = createUseCase()

        useCase.execute(for: TestDataBuilder.fixedDate) { $0.mood = nil }

        #expect(mockRepository.loadAllDaysCalled == false)
        #expect(mockRepository.saveCalledWithDays == nil)
        #expect(mockRepository.saveDayDataCalledWith == nil)
    }
}
