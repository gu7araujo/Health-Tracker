//
//  HealthDataRepository.swift
//  HealthTracker
//
//  Data Layer - Repository implementation
//

import Foundation

/// Concrete implementation of `HealthDataRepositoryProtocol`.
/// Coordinates data operations through the local data source.
final class HealthDataRepository: HealthDataRepositoryProtocol {

    private let dataSource: LocalDataSourceProtocol

    init(dataSource: LocalDataSourceProtocol = UserDefaultsDataSource()) {
        self.dataSource = dataSource
    }

    func loadAllDays() -> [DayData] {
        dataSource.load()
    }

    func save(days: [DayData]) {
        dataSource.save(days)
    }

    func dayData(for date: Date) -> DayData? {
        let days = dataSource.load()
        return days.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    func saveDayData(_ dayData: DayData) {
        var days = dataSource.load()

        if let index = days.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: dayData.date) }) {
            days[index] = dayData
        } else {
            days.append(dayData)
        }

        dataSource.save(days)
    }
}
