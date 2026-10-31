//
//  IntentUseCaseFactoryTests.swift
//  HealthTrackerTests
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct IntentUseCaseFactoryTests {
    @Test func executeAndNotify_savesAndPostsHealthDataDidChange() async throws {
        let mockRepository = MockHealthDataRepository()
        let useCase = UpdateDayDataUseCase(repository: mockRepository, logger: MockLogger())

        await confirmation { posted in
            let token = NotificationCenter.default.addObserver(
                forName: .healthDataDidChange, object: nil, queue: nil
            ) { _ in posted() }
            defer { NotificationCenter.default.removeObserver(token) }

            useCase.executeAndNotify(for: TestDataBuilder.fixedDate) { $0.mood = .good }
        }

        let saved = try #require(mockRepository.saveDayDataCalledWith)
        #expect(saved.dayData.mood == .good)
    }

    @Test func executeAndNotify_unchangedDay_postsNothing() async {
        let useCase = UpdateDayDataUseCase(repository: MockHealthDataRepository(), logger: MockLogger())

        await confirmation(expectedCount: 0) { posted in
            let token = NotificationCenter.default.addObserver(
                forName: .healthDataDidChange, object: nil, queue: nil
            ) { _ in posted() }
            defer { NotificationCenter.default.removeObserver(token) }

            useCase.executeAndNotify(for: TestDataBuilder.fixedDate) { $0.mood = nil }
        }
    }
}
