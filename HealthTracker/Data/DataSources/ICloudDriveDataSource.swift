//
//  ICloudDriveDataSource.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 02/07/26.
//

import Foundation

/// iCloud Drive implementation of local data storage.
/// Persists health data as a user-visible JSON file in the iCloud Documents container.
/// Falls back to local Documents directory when iCloud is unavailable.
///
/// Implicitly `@MainActor` (project default). Synchronous file I/O is acceptable
/// because it targets the local ubiquity container copy (small payload).
final class ICloudDriveDataSource: LocalDataSourceProtocol {
    private let fileName = "HealthTrackerData.json"
    private let fileCoordinator = NSFileCoordinator()
    private let logger: LoggerProtocol

    init(logger: LoggerProtocol = LoggerFactory.dataLogger(category: "Storage.iCloud")) {
        self.logger = logger
    }

    /// Resolves the file URL: iCloud Documents if available, local Documents otherwise.
    /// Uses `FileManager.url(forUbiquityContainerIdentifier: nil)` for the first container.
    /// Never force-unwraps — returns local fallback URL if iCloud is unavailable.
    private var fileURL: URL {
        if let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) {
            let documentsURL = containerURL.appendingPathComponent("Documents")
            return documentsURL.appendingPathComponent(fileName)
        }

        // Fallback: local Documents directory
        let localDocuments = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsURL = localDocuments.first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return documentsURL.appendingPathComponent(fileName)
    }

    /// Loads all stored day data from the JSON file.
    /// - Returns: Array of `RecordedDayData`, or empty array if file doesn't exist or decoding fails.
    ///   Empty entries are filtered out during the parse from `DayData` to `RecordedDayData`.
    func load() -> [RecordedDayData] {
        logger.debug("Loading data from iCloud Drive")
        let url = fileURL
        var coordinatorError: NSError?
        var result: [RecordedDayData] = []

        fileCoordinator.coordinate(readingItemAt: url, options: [], error: &coordinatorError) { coordinatedURL in
            guard FileManager.default.fileExists(atPath: coordinatedURL.path) else {
                return
            }

            do {
                let data = try Data(contentsOf: coordinatedURL)
                let container = try JSONDecoder().decode(DayDataContainer.self, from: data)
                result = container.days.compactMap(RecordedDayData.init)
                logger.info("Successfully loaded \(container.days.count) days from iCloud")
            } catch {
                logger.error("Failed to load from iCloud: \(error.localizedDescription)")
            }
        }

        if let coordinatorError {
            logger.error("File coordination error on read: \(coordinatorError.localizedDescription)")
        }

        return result
    }

    /// Saves day data to the JSON file with pretty-printed formatting.
    /// - Parameter days: Array of `RecordedDayData` to persist.
    /// Creates intermediate directories if needed. Logs errors in DEBUG.
    func save(_ days: [RecordedDayData]) {
        logger.debug("Saving \(days.count) days to iCloud Drive")
        let url = fileURL
        var coordinatorError: NSError?

        fileCoordinator.coordinate(
            writingItemAt: url, options: .forReplacing, error: &coordinatorError
        ) { coordinatedURL in
            do {
                // Ensure the Documents directory exists
                let directory = coordinatedURL.deletingLastPathComponent()
                if !FileManager.default.fileExists(atPath: directory.path) {
                    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                }

                let container = DayDataContainer(days: days.map(\.dayData))
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(container)
                try data.write(to: coordinatedURL, options: .atomic)
                logger.info("Successfully saved \(days.count) days to iCloud")
            } catch {
                logger.error("Failed to save to iCloud: \(error.localizedDescription)")
            }
        }

        if let coordinatorError {
            logger.error("File coordination error on write: \(coordinatorError.localizedDescription)")
        }
    }
}
