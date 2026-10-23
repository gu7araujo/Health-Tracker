//
//  HealthDataRepository.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/18/25.
//

import Foundation

/// Concrete implementation of `HealthDataRepositoryProtocol`.
/// Coordinates data operations through the local data source.
final class HealthDataRepository: HealthDataRepositoryProtocol {
    private let dataSource: LocalDataSourceProtocol

    init(dataSource: LocalDataSourceProtocol = ICloudDriveDataSource()) {
        self.dataSource = dataSource
    }

    func loadAllDays() -> [RecordedDayData] {
        dataSource.load()
    }

    func save(days: [RecordedDayData]) {
        dataSource.save(days)
    }

    func dayData(for date: Date) -> RecordedDayData? {
        let days = dataSource.load()
        return days.first { Calendar.current.isDate($0.dayData.date, inSameDayAs: date) }
    }

    func saveDayData(_ dayData: RecordedDayData) {
        var days = dataSource.load()

        if let index = days.firstIndex(where: {
            Calendar.current.isDate($0.dayData.date, inSameDayAs: dayData.dayData.date)
        }) {
            days[index] = dayData
        } else {
            days.append(dayData)
        }

        dataSource.save(days)
    }
}
