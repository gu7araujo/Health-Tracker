//
//  MainViewModelLoadTests.swift
//  HealthTrackerTests
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct MainViewModelLoadTests {
    private func createViewModel() -> (viewModel: MainViewModel,
                                       mockRepository: MockHealthDataRepository)
    {
        let mockRepository = MockHealthDataRepository()
        let mockLogger = MockLogger()
        let mockNotificationService = MockNotificationService()
        let viewModel = MainViewModel(
            loadUseCase: LoadDayDataUseCase(repository: mockRepository, logger: mockLogger),
            saveUseCase: SaveDayDataUseCase(repository: mockRepository, logger: mockLogger),
            cancelNotificationsUseCase: CancelNotificationsUseCase(
                notificationService: mockNotificationService, logger: mockLogger
            ),
            logger: mockLogger
        )
        return (viewModel, mockRepository)
    }

    @Test func initialization_setsDefaultState() {
        let (viewModel, _) = createViewModel()
        #expect(viewModel.days.isEmpty)
    }

    @Test func loadData_loadsFromRepository() throws {
        let (viewModel, mockRepository) = createViewModel()
        let day1 = try #require(TestDataBuilder.makeRecordedOptimalDay(date: TestDataBuilder.fixedDate))
        let day2 = try #require(TestDataBuilder.makeRecordedModerateDay(date: TestDataBuilder.fixedDatePlusOne))
        mockRepository.loadAllDaysResult = [day1, day2]
        viewModel.selectedDate = day1.dayData.date
        viewModel.loadData()
        #expect(viewModel.days.count == 2)
        #expect(Calendar.current.isDate(viewModel.days[0].date, inSameDayAs: day1.dayData.date))
        #expect(Calendar.current.isDate(viewModel.days[1].date, inSameDayAs: day2.dayData.date))
    }

    @Test func loadData_createsEmptyDayForSelectedDate() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.selectedDate = TestDataBuilder.fixedDate
        viewModel.loadData()
        #expect(viewModel.days.count == 1)
        #expect(viewModel.days[0].meals.isEmpty)
    }
}
