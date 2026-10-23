//
//  MockLogger.swift
//  HealthTrackerTests
//
//  Created by Gustavo Araujo Santos on 03/01/26.
//

import Foundation
@testable import HealthTracker

/// Mock implementation of LoggerProtocol for unit testing.
///
/// This mock allows tests to verify logging behavior without interacting with
/// the real OSLog system. It captures all log messages and provides helper
/// methods for assertions.
///
/// Tests can:
/// - Verify specific messages were logged at specific levels
/// - Check that no errors were logged
/// - Inspect all captured messages
final class MockLogger: LoggerProtocol, @unchecked Sendable {
    // MARK: - Captured Messages

    private(set) var debugMessages: [String] = []
    private(set) var infoMessages: [String] = []
    private(set) var warningMessages: [String] = []
    private(set) var errorMessages: [String] = []

    // MARK: - LoggerProtocol Implementation

    func debug(_ message: String) {
        debugMessages.append(message)
    }

    func info(_ message: String) {
        infoMessages.append(message)
    }

    func warning(_ message: String) {
        warningMessages.append(message)
    }

    func error(_ message: String) {
        errorMessages.append(message)
    }

    // MARK: - Test Helpers

    /// Check if a message was logged at the specified level.
    ///
    /// - Parameters:
    ///   - level: The log level to check
    ///   - substring: A substring to search for in messages
    /// - Returns: true if any message at the level contains the substring
    func didLog(level: LogLevel, containing substring: String) -> Bool {
        let messages: [String] = switch level {
        case .debug: debugMessages
        case .info: infoMessages
        case .warning: warningMessages
        case .error: errorMessages
        }
        return messages.contains { $0.contains(substring) }
    }
}

/// Log levels for MockLogger test helpers.
enum LogLevel {
    case debug
    case info
    case warning
    case error
}
