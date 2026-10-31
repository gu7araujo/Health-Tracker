//
//  GetDayStatusIntentTests.swift
//  HealthTrackerTests
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct GetDayStatusIntentTests {
    private func run(storing day: DayData?) -> (text: String, mockRepository: MockHealthDataRepository) {
        let mockRepository = MockHealthDataRepository()
        if let day {
            mockRepository.dayDataForDateResult[TestDataBuilder.fixedDate] = RecordedDayData(day)
        }
        let useCase = LoadDayDataUseCase(repository: mockRepository, logger: MockLogger())
        return (GetDayStatusIntent().run(with: useCase, on: TestDataBuilder.fixedDate), mockRepository)
    }

    @Test func run_optimalDay_returnsStatusExplanation() {
        let day = TestDataBuilder.makeOptimalDay()
        #expect(run(storing: day).text == NSLocalizedString("day_status_explanation.optimal", comment: ""))
    }

    @Test func run_moderateDay_returnsStatusExplanation() throws {
        let day = TestDataBuilder.makeModerateDay()
        let expected = try #require(day.statusExplanation)
        #expect(run(storing: day).text == expected)
    }

    @Test func run_poorDay_returnsStatusExplanation() throws {
        let day = TestDataBuilder.makePoorDay()
        let expected = try #require(day.statusExplanation)
        #expect(run(storing: day).text == expected)
    }

    @Test func run_incompleteDay_returnsIncompleteLine() {
        let day = TestDataBuilder.makeIncompleteDay()
        #expect(run(storing: day).text == NSLocalizedString("intent_day_status_incomplete", comment: ""))
    }

    @Test func run_noStoredDay_returnsNoDataLine() {
        let (text, mockRepository) = run(storing: nil)
        #expect(text == NSLocalizedString("intent_day_status_no_data", comment: ""))
        #expect(mockRepository.dayDataForDateCalledWith == TestDataBuilder.fixedDate)
    }
}
