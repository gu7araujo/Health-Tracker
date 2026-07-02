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

    /// Production repository, or one backed by a fresh temp directory per launch when UI testing.
    static func makeRepository() -> HealthDataRepositoryProtocol {
        guard isActive else { return HealthDataRepository() }
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("uitest-\(UUID().uuidString)", isDirectory: true)
        return HealthDataRepository(dataSource: ICloudDriveDataSource(directoryOverride: directory))
    }
}
