//
//  OSLogLoggerTests.swift
//  HealthTrackerTests
//
//  Tests for OSLogLogger covering every log level in both
//  debug and release privacy modes. os.Logger produces no return value or
//  observable output to assert on, so these drive every branch and verify the
//  bridge constructs and logs without crashing.
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct OSLogLoggerTests {
    private func exerciseAllMethods(_ logger: OSLogLogger) {
        logger.debug("debug message")
        logger.info("info message")
        logger.warning("warning message")
        logger.error("error message")
    }

    @Test("Debug builds log every level (public privacy) without crashing")
    func allMethods_debugBuild() {
        let logger = OSLogLogger(
            subsystem: "com.healthtracker.tests",
            category: "OSLogLoggerTests",
            isDebugBuild: true
        )
        exerciseAllMethods(logger)
    }

    @Test("Release builds log every level (private privacy) without crashing")
    func allMethods_releaseBuild() {
        let logger = OSLogLogger(
            subsystem: "com.healthtracker.tests",
            category: "OSLogLoggerTests",
            isDebugBuild: false
        )
        exerciseAllMethods(logger)
    }

    @Test("The default initializer resolves the build configuration and logs without crashing")
    func defaultInitializer_logs() {
        let logger = OSLogLogger(subsystem: "com.healthtracker.tests", category: "OSLogLoggerTests")
        logger.info("using default isDebugBuild")
    }
}
