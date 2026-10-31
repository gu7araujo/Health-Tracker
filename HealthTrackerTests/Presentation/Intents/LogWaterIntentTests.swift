//
//  LogWaterIntentTests.swift
//  HealthTrackerTests
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct LogWaterIntentTests {
    // Swift Testing builds a fresh suite instance per test, so each test gets its own mock
    private let mockRepository = MockHealthDataRepository()
    private let useCase: UpdateDayDataUseCase

    init() {
        useCase = UpdateDayDataUseCase(repository: mockRepository, logger: MockLogger())
    }

    private func makeIntent(amount: Measurement<UnitVolume>) -> LogWaterIntent {
        let intent = LogWaterIntent()
        intent.amount = amount
        return intent
    }

    @Test func run_addsAmountInLitersToStoredTotal() throws {
        let intent = makeIntent(amount: Measurement(value: 250, unit: .milliliters))
        mockRepository.dayDataForDateResult[TestDataBuilder.fixedDate] = RecordedDayData(
            DayData(date: TestDataBuilder.fixedDate, water: 1.0)
        )

        try intent.run(with: useCase, on: TestDataBuilder.fixedDate)

        let saved = try #require(mockRepository.saveDayDataCalledWith)
        #expect(saved.dayData.water == 1.25)
        #expect(mockRepository.dayDataForDateCalledWith == TestDataBuilder.fixedDate)
    }

    @Test func run_convertsOtherVolumeUnitsToLiters() throws {
        // 8 US fl oz ≈ 236.6 mL → 0.24 L after rounding
        let intent = makeIntent(amount: Measurement(value: 8, unit: .fluidOunces))

        try intent.run(with: useCase, on: TestDataBuilder.fixedDate)

        let saved = try #require(mockRepository.saveDayDataCalledWith)
        #expect(saved.dayData.water == 0.24)
    }

    @Test func run_atTheCap_throwsWithoutSaving() throws {
        let intent = makeIntent(amount: Measurement(value: 250, unit: .milliliters))
        mockRepository.dayDataForDateResult[TestDataBuilder.fixedDate] = RecordedDayData(
            DayData(date: TestDataBuilder.fixedDate, water: 5.0)
        )

        let error = try #require(throws: LogWaterIntent.NothingAddedError.self) {
            try intent.run(with: useCase, on: TestDataBuilder.fixedDate)
        }

        #expect(error.total == 5.0)
        let message = String(format: NSLocalizedString("intent_log_water_nothing_added %@", comment: ""), "5")
        #expect(String(localized: error.localizedStringResource) == message)
        #expect(mockRepository.saveDayDataCalledWith == nil)
        #expect(mockRepository.saveCalledWithDays == nil)
    }

    @Test func run_zeroAmount_throwsWithoutSaving() throws {
        let intent = makeIntent(amount: Measurement(value: 0, unit: .milliliters))
        mockRepository.dayDataForDateResult[TestDataBuilder.fixedDate] = RecordedDayData(
            DayData(date: TestDataBuilder.fixedDate, water: 1.0)
        )

        let error = try #require(throws: LogWaterIntent.NothingAddedError.self) {
            try intent.run(with: useCase, on: TestDataBuilder.fixedDate)
        }

        #expect(error.total == 1.0)
        #expect(mockRepository.saveDayDataCalledWith == nil)
    }

    @Test func registerUndo_restoresPreviousTotal() throws {
        let intent = makeIntent(amount: Measurement(value: 500, unit: .milliliters))
        mockRepository.dayDataForDateResult[TestDataBuilder.fixedDate] = RecordedDayData(
            DayData(date: TestDataBuilder.fixedDate, water: 1.0)
        )
        let change = try intent.run(with: useCase, on: TestDataBuilder.fixedDate)
        mockRepository.dayDataForDateResult[TestDataBuilder.fixedDate] = mockRepository.saveDayDataCalledWith

        try UndoManager.registerAndUndo(against: mockRepository) {
            intent.registerUndo(on: $0, useCase: $1, change: change)
        }

        let saved = try #require(mockRepository.saveDayDataCalledWith)
        #expect(saved.dayData.water == 1.0)
    }

    @Test func registerUndo_keepsWaterLoggedSince() throws {
        let intent = makeIntent(amount: Measurement(value: 500, unit: .milliliters))
        mockRepository.dayDataForDateResult[TestDataBuilder.fixedDate] = RecordedDayData(
            DayData(date: TestDataBuilder.fixedDate, water: 1.0)
        )
        let change = try intent.run(with: useCase, on: TestDataBuilder.fixedDate)
        // 0.25 L logged in the app after the intent's 1.5 L
        mockRepository.dayDataForDateResult[TestDataBuilder.fixedDate] = RecordedDayData(
            DayData(date: TestDataBuilder.fixedDate, water: 1.75)
        )

        try UndoManager.registerAndUndo(against: mockRepository) {
            intent.registerUndo(on: $0, useCase: $1, change: change)
        }

        let saved = try #require(mockRepository.saveDayDataCalledWith)
        #expect(saved.dayData.water == 1.25)
    }

    @Test func registerUndo_atTheCap_removesOnlyWhatWasAdded() throws {
        // 4.8 L + 0.5 L clamps to 5 L, so the intent only added 0.2 L
        let intent = makeIntent(amount: Measurement(value: 500, unit: .milliliters))
        mockRepository.dayDataForDateResult[TestDataBuilder.fixedDate] = RecordedDayData(
            DayData(date: TestDataBuilder.fixedDate, water: 4.8)
        )
        let change = try intent.run(with: useCase, on: TestDataBuilder.fixedDate)
        mockRepository.dayDataForDateResult[TestDataBuilder.fixedDate] = mockRepository.saveDayDataCalledWith

        try UndoManager.registerAndUndo(against: mockRepository) {
            intent.registerUndo(on: $0, useCase: $1, change: change)
        }

        let saved = try #require(mockRepository.saveDayDataCalledWith)
        #expect(saved.dayData.water == 4.8)
    }

    @Test func registerUndo_withNoPriorWater_dropsTheNowEmptyDay() throws {
        let intent = makeIntent(amount: Measurement(value: 250, unit: .milliliters))
        let change = try intent.run(with: useCase, on: TestDataBuilder.fixedDate)
        mockRepository.dayDataForDateResult[TestDataBuilder.fixedDate] = mockRepository.saveDayDataCalledWith

        try UndoManager.registerAndUndo(against: mockRepository) {
            intent.registerUndo(on: $0, useCase: $1, change: change)
        }

        #expect(mockRepository.saveCalledWithDays == [])
    }

    @Test func parameterSummary_bindsAmount() {
        let summary = LogWaterIntent.parameterSummary

        #expect(summary.sentenceFormat == "intent_log_water_summary ${parameter0}")
        #expect(summary.sentenceParameters(of: LogWaterIntent.self) == [\LogWaterIntent.$amount])
    }
}
