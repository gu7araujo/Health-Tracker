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
    private let backupFileName = "HealthTrackerData.backup.json"
    private let fileCoordinator = NSFileCoordinator()
    private let logger: LoggerProtocol
    private let directoryOverride: URL?

    init(
        logger: LoggerProtocol = LoggerFactory.dataLogger(category: "Storage.iCloud"),
        directoryOverride: URL? = nil
    ) {
        self.logger = logger
        self.directoryOverride = directoryOverride
    }

    /// Resolves the file URL: iCloud Documents if available, local Documents otherwise.
    /// Uses `FileManager.url(forUbiquityContainerIdentifier: nil)` for the first container.
    /// Never force-unwraps — returns local fallback URL if iCloud is unavailable.
    private var fileURL: URL {
        if let directoryOverride {
            return directoryOverride.appendingPathComponent(fileName)
        }

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

    /// Copies the current data file to a rolling backup (`HealthTrackerData.backup.json`)
    /// in the same directory, overwriting any previous backup. Raw byte copy — never
    /// decodes/re-encodes, so it preserves data even when decoding is broken.
    /// The backup is user-visible in the Files app alongside the data file.
    /// - Returns: `true` when it is safe to proceed (backup written, or no data file
    ///   to back up); `false` when the data file exists but the copy failed.
    @discardableResult
    func backUpDataFile() -> Bool {
        logger.debug("Backing up data file")
        let sourceURL = fileURL
        let backupURL = sourceURL.deletingLastPathComponent().appendingPathComponent(backupFileName)
        var coordinatorError: NSError?
        var result = true

        fileCoordinator.coordinate(
            readingItemAt: sourceURL, options: [],
            writingItemAt: backupURL, options: .forReplacing,
            error: &coordinatorError
        ) { readURL, writeURL in
            guard FileManager.default.fileExists(atPath: readURL.path) else {
                return
            }

            do {
                if FileManager.default.fileExists(atPath: writeURL.path) {
                    try FileManager.default.removeItem(at: writeURL)
                }
                try FileManager.default.copyItem(at: readURL, to: writeURL)
                logger.info("Backed up data file to \(backupURL.lastPathComponent)")
            } catch {
                logger.error("Failed to back up data file: \(error.localizedDescription)")
                result = false
            }
        }

        if let coordinatorError {
            logger.error("File coordination error on backup: \(coordinatorError.localizedDescription)")
            result = false
        }

        return result
    }
}
