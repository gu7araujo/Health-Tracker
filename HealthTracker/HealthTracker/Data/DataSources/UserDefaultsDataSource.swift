//
//  UserDefaultsDataSource.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/18/25.
//

import Foundation

/// Protocol for local data storage operations.
/// Allows for easy testing and future replacement of storage mechanism.
protocol LocalDataSourceProtocol {
    func load() -> [DayData]
    func save(_ days: [DayData])
}

/// UserDefaults-based implementation of local data storage.
/// Extracts persistence logic from the presentation layer.
final class UserDefaultsDataSource: LocalDataSourceProtocol {

    private let userDefaults: UserDefaults
    private let storageKey: String

    init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = "store"
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
    }

    /// Loads all stored day data from UserDefaults.
    /// - Returns: Array of `DayData`, or empty array if none exist or decoding fails.
    func load() -> [DayData] {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return []
        }

        do {
            let container = try JSONDecoder().decode(DayDataContainer.self, from: data)
            return container.days
        } catch {
            // Log error in debug builds, return empty array for graceful degradation
            #if DEBUG
            print("UserDefaultsDataSource: Failed to decode stored data - \(error)")
            #endif
            return []
        }
    }

    /// Saves day data to UserDefaults.
    /// - Parameter days: Array of `DayData` to persist.
    func save(_ days: [DayData]) {
        let container = DayDataContainer(days: days)

        do {
            let data = try JSONEncoder().encode(container)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            #if DEBUG
            print("UserDefaultsDataSource: Failed to encode data - \(error)")
            #endif
        }
    }
}

// MARK: - Storage Container

/// Container for encoding/decoding day data array.
/// Maintains backwards compatibility with the original `Store` structure.
private struct DayDataContainer: Codable {
    let days: [DayData]
}
