//
//  LogMoodIntentTests.swift
//  HealthTrackerTests
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct LogMoodIntentTests {
    // Swift Testing builds a fresh suite instance per test, so each test gets its own mock
    private let mockRepository = MockHealthDataRepository()
    private let useCase: UpdateDayDataUseCase

    init() {
        useCase = UpdateDayDataUseCase(repository: mockRepository, logger: MockLogger())
    }

    private func makeIntent(mood: MoodAppEnum) -> LogMoodIntent {
        let intent = LogMoodIntent()
        intent.mood = mood
        return intent
    }

    @Test func run_setsMoodAndKeepsOtherFields() throws {
        let intent = makeIntent(mood: .sad)
        mockRepository.dayDataForDateResult[TestDataBuilder.fixedDate] = RecordedDayData(
            DayData(date: TestDataBuilder.fixedDate, water: 1.0, mood: .good)
        )

        intent.run(with: useCase, on: TestDataBuilder.fixedDate)

        let saved = try #require(mockRepository.saveDayDataCalledWith)
        #expect(saved.dayData == DayData(date: TestDataBuilder.fixedDate, water: 1.0, mood: .sad))
        #expect(mockRepository.dayDataForDateCalledWith == TestDataBuilder.fixedDate)
    }

    @Test func registerUndo_restoresPreviousMood() throws {
        let intent = makeIntent(mood: .sad)
        mockRepository.dayDataForDateResult[TestDataBuilder.fixedDate] = RecordedDayData(
            DayData(date: TestDataBuilder.fixedDate, water: 1.0, mood: .good)
        )
        let change = intent.run(with: useCase, on: TestDataBuilder.fixedDate)
        mockRepository.dayDataForDateResult[TestDataBuilder.fixedDate] = mockRepository.saveDayDataCalledWith

        try UndoManager.registerAndUndo(against: mockRepository) {
            intent.registerUndo(on: $0, useCase: $1, change: change)
        }

        let saved = try #require(mockRepository.saveDayDataCalledWith)
        #expect(saved.dayData.mood == .good)
    }

    @Test func registerUndo_keepsMoodChangedSince() throws {
        let intent = makeIntent(mood: .sad)
        mockRepository.dayDataForDateResult[TestDataBuilder.fixedDate] = RecordedDayData(
            DayData(date: TestDataBuilder.fixedDate, mood: .good)
        )
        let change = intent.run(with: useCase, on: TestDataBuilder.fixedDate)
        // Mood changed in the app after the intent set it
        mockRepository.dayDataForDateResult[TestDataBuilder.fixedDate] = RecordedDayData(
            DayData(date: TestDataBuilder.fixedDate, mood: .neutral)
        )
        mockRepository.saveDayDataCalledWith = nil

        try UndoManager.registerAndUndo(against: mockRepository) {
            intent.registerUndo(on: $0, useCase: $1, change: change)
        }

        // The later mood stays, so the undo has nothing to write
        #expect(mockRepository.saveDayDataCalledWith == nil)
    }

    @Test func registerUndo_withNoPriorMood_dropsTheNowEmptyDay() throws {
        let intent = makeIntent(mood: .neutral)
        let change = intent.run(with: useCase, on: TestDataBuilder.fixedDate)
        mockRepository.dayDataForDateResult[TestDataBuilder.fixedDate] = mockRepository.saveDayDataCalledWith

        try UndoManager.registerAndUndo(against: mockRepository) {
            intent.registerUndo(on: $0, useCase: $1, change: change)
        }

        #expect(mockRepository.saveCalledWithDays == [])
    }

    @Test func parameterSummary_bindsMood() {
        let summary = LogMoodIntent.parameterSummary

        #expect(summary.sentenceFormat == "intent_log_mood_summary ${parameter0}")
        #expect(summary.sentenceParameters(of: LogMoodIntent.self) == [\LogMoodIntent.$mood])
    }
}
