//
//  MainViewModelWaterMoodTests.swift
//  HealthTrackerTests
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct MainViewModelWaterMoodTests {
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

    @Test func updateWater_updatesCurrentDay() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate
        viewModel.updateWater(1.5)
        #expect(viewModel.currentDayData?.water == 1.5)
        #expect(mockRepository.saveCalledWithDays != nil)
    }

    @Test func updateWater_zeroRemovesWater() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate
        viewModel.updateWater(2.0)
        viewModel.updateWater(0)
        #expect(viewModel.currentDayData?.water == nil)
    }

    @Test func waterIntake_getter_returnsCurrentWater() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate
        viewModel.updateWater(2.5)
        #expect(viewModel.waterIntake == 2.5)
    }

    @Test func waterIntake_getter_returnsZero_whenNil() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate
        #expect(viewModel.waterIntake == 0)
    }

    @Test func updateMood_updatesCurrentDay() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate
        viewModel.updateMood(.good)
        #expect(viewModel.currentDayData?.mood == .good)
        #expect(mockRepository.saveCalledWithDays != nil)
    }

    @Test func updateMood_changesMood() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate
        viewModel.updateMood(.good)
        viewModel.updateMood(.sad)
        #expect(viewModel.currentDayData?.mood == .sad)
    }
}
