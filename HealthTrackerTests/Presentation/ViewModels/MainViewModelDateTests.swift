//
//  MainViewModelDateTests.swift
//  HealthTrackerTests
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct MainViewModelDateTests {
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

    @Test func selectedDate_change_ensuresDayDataExists() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.selectedDate = TestDataBuilder.fixedDate
        viewModel.loadData()
        #expect(viewModel.days.count == 1)
        #expect(Calendar.current.isDate(viewModel.days[0].date, inSameDayAs: TestDataBuilder.fixedDate))
    }

    @Test func selectedDate_change_doesNotDuplicateExistingDay() throws {
        let (viewModel, mockRepository) = createViewModel()
        let existingDay = try #require(TestDataBuilder.makeRecordedOptimalDay(date: TestDataBuilder.fixedDate))
        mockRepository.loadAllDaysResult = [existingDay]
        viewModel.selectedDate = TestDataBuilder.fixedDate
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate
        #expect(viewModel.days.count == 1)
    }

    @Test func currentDayData_returnsCorrectDay() throws {
        let (viewModel, mockRepository) = createViewModel()
        let day1 = try #require(TestDataBuilder.makeRecordedOptimalDay(date: TestDataBuilder.fixedDate))
        let day2 = try #require(TestDataBuilder.makeRecordedModerateDay(date: TestDataBuilder.fixedDatePlusOne))
        mockRepository.loadAllDaysResult = [day1, day2]
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate
        #expect(viewModel.currentDayData?.date == day1.dayData.date)
    }

    @Test func dateSwitch_preservesData() throws {
        let (viewModel, mockRepository) = createViewModel()
        let day1 = try #require(TestDataBuilder.makeRecordedOptimalDay(date: TestDataBuilder.fixedDate))
        let day2 = try #require(TestDataBuilder.makeRecordedModerateDay(date: TestDataBuilder.fixedDatePlusOne))
        mockRepository.loadAllDaysResult = [day1, day2]
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate
        let firstDate = viewModel.currentDayData?.date
        viewModel.selectedDate = TestDataBuilder.fixedDatePlusOne
        let secondDate = viewModel.currentDayData?.date
        viewModel.selectedDate = TestDataBuilder.fixedDate
        #expect(firstDate == day1.dayData.date)
        #expect(secondDate == day2.dayData.date)
        #expect(viewModel.currentDayData?.date == day1.dayData.date)
    }
}
