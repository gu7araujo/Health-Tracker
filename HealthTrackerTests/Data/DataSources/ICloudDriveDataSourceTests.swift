//
//  ICloudDriveDataSourceTests.swift
//  HealthTrackerTests
//
//  Tests for the pre-migration backup behavior of ICloudDriveDataSource.
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct ICloudDriveDataSourceTests {
    private func makeTempDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

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
