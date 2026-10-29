//
//  ICloudDriveDataSourceTests.swift
//  HealthTrackerTests
//
//  Tests for the load/save round trip and pre-migration backup behavior of ICloudDriveDataSource.
//

import Foundation
@testable import HealthTracker
import Testing

/// File presenter that refuses to save its changes (asked before a read) and to give up
/// its file (asked before a replacing write), so every coordinated access to the file
/// ends in a file coordination error.
private final nonisolated class FailingFilePresenter: NSObject, NSFilePresenter {
    let presentedItemURL: URL?
    let presentedItemOperationQueue = OperationQueue()

    init(url: URL) {
        presentedItemURL = url
    }

    func savePresentedItemChanges(completionHandler: @escaping (Error?) -> Void) {
        completionHandler(CocoaError(.fileWriteUnknown))
    }

    func accommodatePresentedItemDeletion(completionHandler: @escaping (Error?) -> Void) {
        completionHandler(CocoaError(.fileWriteUnknown))
    }
}

@MainActor
struct ICloudDriveDataSourceTests {
    private func makeTempDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    /// Registers a `FailingFilePresenter` on the data file; remove it when done.
    private func blockCoordination(of directory: URL) -> FailingFilePresenter {
        let presenter = FailingFilePresenter(url: directory.appendingPathComponent("HealthTrackerData.json"))
        NSFileCoordinator.addFilePresenter(presenter)
        return presenter
    }

    // MARK: - load / save

    @Test func save_thenLoad_roundTripsRecordedDays() throws {
        let directory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let dataSource = ICloudDriveDataSource(logger: MockLogger(), directoryOverride: directory)
        let days = try [
            #require(TestDataBuilder.makeRecordedOptimalDay()),
            #require(TestDataBuilder.makeRecordedPoorDay(date: TestDataBuilder.fixedDatePlusOne))
        ]

        dataSource.save(days)

        #expect(dataSource.load() == days)
    }

    @Test func save_writesPrettyPrintedSortedJSONContainer() throws {
        let directory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let dataSource = ICloudDriveDataSource(logger: MockLogger(), directoryOverride: directory)
        let day = try #require(TestDataBuilder.makeRecordedOptimalDay())

        dataSource.save([day])

        let data = try Data(contentsOf: directory.appendingPathComponent("HealthTrackerData.json"))
        let container = try JSONDecoder().decode(DayDataContainer.self, from: data)
        let expectedEncoder = JSONEncoder()
        expectedEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        #expect(container.days == [day.dayData])
        #expect(try data == (expectedEncoder.encode(DayDataContainer(days: [day.dayData]))))
    }

    @Test func save_createsMissingDirectory() throws {
        let directory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let nestedDirectory = directory.appendingPathComponent("Documents")
        let dataSource = ICloudDriveDataSource(logger: MockLogger(), directoryOverride: nestedDirectory)

        try dataSource.save([#require(TestDataBuilder.makeRecordedOptimalDay())])

        let dataFileURL = nestedDirectory.appendingPathComponent("HealthTrackerData.json")
        #expect(FileManager.default.fileExists(atPath: dataFileURL.path))
    }

    @Test func save_logsErrorWhenWriteFails() throws {
        let directory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let mockLogger = MockLogger()
        let dataSource = ICloudDriveDataSource(logger: mockLogger, directoryOverride: directory)

        // Read-only directory makes the write fail
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: directory.path)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: directory.path)
        }

        try dataSource.save([#require(TestDataBuilder.makeRecordedOptimalDay())])

        #expect(mockLogger.didLog(level: .error, containing: "Failed to save"))
        let dataFileURL = directory.appendingPathComponent("HealthTrackerData.json")
        #expect(!FileManager.default.fileExists(atPath: dataFileURL.path))
    }

    @Test func load_returnsEmptyWhenNoDataFileExists() throws {
        let directory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let mockLogger = MockLogger()
        let dataSource = ICloudDriveDataSource(logger: mockLogger, directoryOverride: directory)

        #expect(dataSource.load().isEmpty)
        #expect(mockLogger.errorMessages.isEmpty)
    }

    @Test func load_returnsEmptyAndLogsErrorWhenJSONIsInvalid() throws {
        let directory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let mockLogger = MockLogger()
        let dataSource = ICloudDriveDataSource(logger: mockLogger, directoryOverride: directory)
        let dataFileURL = directory.appendingPathComponent("HealthTrackerData.json")
        try Data("{ this is not valid json !!!".utf8).write(to: dataFileURL)

        #expect(dataSource.load().isEmpty)
        #expect(mockLogger.didLog(level: .error, containing: "Failed to load"))
    }

    @Test func load_returnsEmptyWhenFileCoordinationFails() throws {
        let directory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let dataSource = ICloudDriveDataSource(logger: MockLogger(), directoryOverride: directory)
        let day = try #require(TestDataBuilder.makeRecordedOptimalDay())
        dataSource.save([day])
        try #require(dataSource.load() == [day])
        let presenter = blockCoordination(of: directory)
        defer { NSFileCoordinator.removeFilePresenter(presenter) }

        #expect(dataSource.load().isEmpty)
    }

    @Test func save_leavesDataFileUntouchedWhenFileCoordinationFails() throws {
        let directory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let dataSource = ICloudDriveDataSource(logger: MockLogger(), directoryOverride: directory)
        let dataFileURL = directory.appendingPathComponent("HealthTrackerData.json")
        let currentContents = Data("current data".utf8)
        try currentContents.write(to: dataFileURL)
        let presenter = blockCoordination(of: directory)
        defer { NSFileCoordinator.removeFilePresenter(presenter) }

        try dataSource.save([#require(TestDataBuilder.makeRecordedOptimalDay())])

        #expect(try Data(contentsOf: dataFileURL) == currentContents)
    }

    @Test func load_filtersOutEmptyDays() throws {
        let directory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let dataSource = ICloudDriveDataSource(logger: MockLogger(), directoryOverride: directory)
        let optimalDay = TestDataBuilder.makeOptimalDay()
        let container = DayDataContainer(days: [
            TestDataBuilder.makeEmptyDay(date: TestDataBuilder.fixedDatePlusOne),
            optimalDay
        ])
        try JSONEncoder().encode(container).write(to: directory.appendingPathComponent("HealthTrackerData.json"))

        #expect(dataSource.load().map(\.dayData) == [optimalDay])
    }

    // MARK: - backUpDataFile

    @Test func backUpDataFile_copiesRawBytesWithoutReencoding() throws {
        let directory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let mockLogger = MockLogger()
        let dataSource = ICloudDriveDataSource(logger: mockLogger, directoryOverride: directory)

        // Invalid JSON proves the backup is a raw byte copy, not a decode/re-encode
        let invalidJSON = Data("{ this is not valid json !!!".utf8)
        let dataFileURL = directory.appendingPathComponent("HealthTrackerData.json")
        try invalidJSON.write(to: dataFileURL)

        let result = dataSource.backUpDataFile()

        let backupURL = directory.appendingPathComponent("HealthTrackerData.backup.json")
        #expect(result == true)
        #expect(FileManager.default.fileExists(atPath: backupURL.path))
        #expect(try Data(contentsOf: backupURL) == invalidJSON)
        #expect(try Data(contentsOf: dataFileURL) == invalidJSON)
    }

    @Test func backUpDataFile_overwritesExistingBackup() throws {
        let directory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let mockLogger = MockLogger()
        let dataSource = ICloudDriveDataSource(logger: mockLogger, directoryOverride: directory)

        let oldBackupContents = Data("old backup".utf8)
        let currentContents = Data("current data".utf8)
        try oldBackupContents.write(to: directory.appendingPathComponent("HealthTrackerData.backup.json"))
        try currentContents.write(to: directory.appendingPathComponent("HealthTrackerData.json"))

        let result = dataSource.backUpDataFile()

        let backupURL = directory.appendingPathComponent("HealthTrackerData.backup.json")
        #expect(result == true)
        #expect(try Data(contentsOf: backupURL) == currentContents)
    }

    @Test func backUpDataFile_returnsTrueWhenNoDataFileExists() throws {
        let directory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let mockLogger = MockLogger()
        let dataSource = ICloudDriveDataSource(logger: mockLogger, directoryOverride: directory)

        let result = dataSource.backUpDataFile()

        let backupURL = directory.appendingPathComponent("HealthTrackerData.backup.json")
        #expect(result == true)
        #expect(!FileManager.default.fileExists(atPath: backupURL.path))
    }

    @Test func backUpDataFile_returnsFalseWhenFileCoordinationFails() throws {
        let directory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let dataSource = ICloudDriveDataSource(logger: MockLogger(), directoryOverride: directory)
        try Data("current data".utf8).write(to: directory.appendingPathComponent("HealthTrackerData.json"))
        let presenter = blockCoordination(of: directory)
        defer { NSFileCoordinator.removeFilePresenter(presenter) }

        let result = dataSource.backUpDataFile()

        let backupURL = directory.appendingPathComponent("HealthTrackerData.backup.json")
        #expect(result == false)
        #expect(!FileManager.default.fileExists(atPath: backupURL.path))
    }

    @Test func backUpDataFile_returnsFalseWhenCopyFails() throws {
        let directory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let mockLogger = MockLogger()
        let dataSource = ICloudDriveDataSource(logger: mockLogger, directoryOverride: directory)

        try Data("current data".utf8).write(to: directory.appendingPathComponent("HealthTrackerData.json"))

        // Read-only directory makes the copy fail
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: directory.path)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: directory.path)
        }

        let result = dataSource.backUpDataFile()

        #expect(result == false)
        #expect(mockLogger.didLog(level: .error, containing: "back up"))
    }
}

/// File manager that reports `containerURL` as the iCloud ubiquity container.
private final nonisolated class UbiquityFileManager: FileManager {
    let containerURL: URL

    init(containerURL: URL) {
        self.containerURL = containerURL
        super.init()
    }

    override func url(forUbiquityContainerIdentifier _: String?) -> URL? {
        containerURL
    }
}

// MARK: - iCloud container

extension ICloudDriveDataSourceTests {
    @Test func save_writesToDocumentsInUbiquityContainer() throws {
        let container = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: container) }
        let dataSource = ICloudDriveDataSource(
            logger: MockLogger(), fileManager: UbiquityFileManager(containerURL: container)
        )
        let day = try #require(TestDataBuilder.makeRecordedOptimalDay())

        dataSource.save([day])

        let documents = ICloudDriveDataSource(
            logger: MockLogger(), directoryOverride: container.appendingPathComponent("Documents")
        )
        #expect(documents.load() == [day])
    }

    @Test func load_readsFromDocumentsInUbiquityContainer() throws {
        let container = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: container) }
        let day = try #require(TestDataBuilder.makeRecordedOptimalDay())
        ICloudDriveDataSource(logger: MockLogger(), directoryOverride: container.appendingPathComponent("Documents"))
            .save([day])
        let dataSource = ICloudDriveDataSource(
            logger: MockLogger(), fileManager: UbiquityFileManager(containerURL: container)
        )

        #expect(dataSource.load() == [day])
    }
}

/// File manager whose `createDirectory` always fails.
private final nonisolated class FailingCreateDirectoryFileManager: FileManager {
    override func createDirectory(
        at _: URL, withIntermediateDirectories _: Bool, attributes _: [FileAttributeKey: Any]? = nil
    ) throws {
        throw CocoaError(.fileWriteNoPermission)
    }
}

// MARK: - Injected file manager

extension ICloudDriveDataSourceTests {
    @Test func save_usesInjectedFileManagerToCreateMissingDirectory() throws {
        let directory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let mockLogger = MockLogger()
        let dataSource = ICloudDriveDataSource(
            logger: mockLogger,
            directoryOverride: directory.appendingPathComponent("Documents"),
            fileManager: FailingCreateDirectoryFileManager()
        )

        try dataSource.save([#require(TestDataBuilder.makeRecordedOptimalDay())])

        #expect(mockLogger.didLog(level: .error, containing: "Failed to save"))
        #expect(!FileManager.default.fileExists(atPath: directory.appendingPathComponent("Documents").path))
    }
}
