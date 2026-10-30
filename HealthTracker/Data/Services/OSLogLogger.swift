//
//  OSLogLogger.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 03/01/26.
//

import Foundation
import OSLog

/// Concrete implementation of LoggerProtocol using Apple's Unified Logging System (OSLog).
///
/// This class wraps os.Logger and provides privacy-aware logging that automatically
/// adapts based on build configuration:
/// - DEBUG builds: All log messages are public (visible in Console.app)
/// - RELEASE builds: All log messages are private (redacted in Console.app)
///
/// This is the ONLY file in the project that should import OSLog framework.
///
/// Thread-safe and Sendable for use with Swift Concurrency.
final nonisolated class OSLogLogger: LoggerProtocol, Sendable {
    private let logger: Logger
    private let isDebugBuild: Bool

    /// Initialize an OSLog logger with subsystem and category.
    ///
    /// - Parameters:
    ///   - subsystem: Reverse-DNS style identifier (e.g., "com.healthtracker.domain")
    ///   - category: Feature or component identifier (e.g., "Data.Save")
    ///   - isDebugBuild: Whether this is a debug build (defaults to compile-time check)
    init(subsystem: String, category: String, isDebugBuild: Bool = isDebugConfiguration()) {
        logger = Logger(subsystem: subsystem, category: category)
        self.isDebugBuild = isDebugBuild
    }

    // MARK: - LoggerProtocol Implementation

    func debug(_ message: String) {
        if isDebugBuild {
            logger.debug("\(message, privacy: .public)")
        } else {
            logger.debug("\(message, privacy: .private)")
        }
    }

    func info(_ message: String) {
        if isDebugBuild {
            logger.info("\(message, privacy: .public)")
        } else {
            logger.info("\(message, privacy: .private)")
        }
    }

    func warning(_ message: String) {
        if isDebugBuild {
            logger.warning("\(message, privacy: .public)")
        } else {
            logger.warning("\(message, privacy: .private)")
        }
    }

    func error(_ message: String) {
        if isDebugBuild {
            logger.error("\(message, privacy: .public)")
        } else {
            logger.error("\(message, privacy: .private)")
        }
    }
}

/// Helper function to detect debug build configuration.
///
/// Returns true when running in DEBUG mode, false otherwise.
private nonisolated func isDebugConfiguration() -> Bool {
    #if DEBUG
        return true
    #else
        return false
    #endif
}
