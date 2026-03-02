//
//  UserDefaultsDataSource.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/18/25.
//

import Foundation

/// Protocol for local data storage operations.
/// Allows for easy testing and future replacement of storage mechanism.
/// Works with `RecordedDayData` to ensure only non-empty days are persisted.
protocol LocalDataSourceProtocol {
    func load() -> [RecordedDayData]
    func save(_ days: [RecordedDayData])
}

/// UserDefaults-based implementation of local data storage.
/// Extracts persistence logic from the presentation layer.
final class UserDefaultsDataSource: LocalDataSourceProtocol {
    private let userDefaults: UserDefaults
    private let storageKey: String
    private let logger: LoggerProtocol

    init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = "store",
        logger: LoggerProtocol = LoggerFactory.dataLogger(category: "Storage.UserDefaults")
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
        self.logger = logger
    }

    /// Loads all stored day data from UserDefaults.
    /// - Returns: Array of `RecordedDayData`, or empty array if none exist or decoding fails.
    ///   Empty entries are filtered out during the parse from `DayData` to `RecordedDayData`.
    func load() -> [RecordedDayData] {
        logger.debug("Loading data from UserDefaults")
        guard let data = userDefaults.data(forKey: storageKey) else {
            return []
        }

        do {
            let container = try JSONDecoder().decode(DayDataContainer.self, from: data)
            let decoded = container.days.compactMap(RecordedDayData.init)
            logger.info("Successfully loaded \(decoded.count) days from UserDefaults")
            return decoded
        } catch {
            logger.error("Failed to decode UserDefaults data: \(error.localizedDescription)")
            return []
        }
    }

    /// Saves day data to UserDefaults.
    /// - Parameter days: Array of `RecordedDayData` to persist.
    func save(_ days: [RecordedDayData]) {
        logger.debug("Saving \(days.count) days to UserDefaults")
        let container = DayDataContainer(days: days.map(\.dayData))

        do {
            let data = try JSONEncoder().encode(container)
            userDefaults.set(data, forKey: storageKey)
            logger.info("Successfully saved \(days.count) days to UserDefaults")
        } catch {
            logger.error("Failed to save to UserDefaults: \(error.localizedDescription)")
        }
    }
}
