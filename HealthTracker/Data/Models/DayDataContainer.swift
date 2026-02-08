//
//  DayDataContainer.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/18/25.
//

import Foundation

/// Container for encoding/decoding day data array.
/// Maintains backwards compatibility with the original `Store` structure.
/// Shared between `UserDefaultsDataSource` and `ICloudDriveDataSource`.
struct DayDataContainer: Codable {
    let days: [DayData]
}
