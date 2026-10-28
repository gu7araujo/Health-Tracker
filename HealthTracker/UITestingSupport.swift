//
//  UITestingSupport.swift
//  HealthTracker
//

import Foundation

/// Hooks for running the app under XCUITest with isolated, deterministic state.
enum UITestingSupport {
    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains("-uiTesting")
    }

    /// True when the app is only the host process for the unit-test bundle.
    static var isHostingUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    /// Production repository, or one backed by a fresh temp directory per launch when UI testing.
    static func makeRepository() -> HealthDataRepositoryProtocol {
        guard isActive else { return HealthDataRepository() }
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("uitest-\(UUID().uuidString)", isDirectory: true)
        return HealthDataRepository(dataSource: ICloudDriveDataSource(directoryOverride: directory))
    }
}
