//
//  SaveDayDataUseCaseLoggingTests.swift
//  HealthTrackerTests
//
//  Created by Gustavo Araujo Santos on 03/01/26.
//

@testable import HealthTracker
import Testing

@MainActor
struct SaveDayDataUseCaseLoggingTests {
    @Test func execute_logsSaveOperation() throws {
        // Arrange
        let mockRepository = MockHealthDataRepository()
        let mockLogger = MockLogger()
        let useCase = SaveDayDataUseCase(repository: mockRepository, logger: mockLogger)

        let dayData = try #require(TestDataBuilder.makeRecordedOptimalDay())

        // Act
        useCase.execute(dayData: dayData)

        // Assert
        #expect(mockLogger.didLog(level: .debug, containing: "Saving day data"))
        #expect(mockLogger.didLog(level: .info, containing: "saved successfully"))
    }
}
