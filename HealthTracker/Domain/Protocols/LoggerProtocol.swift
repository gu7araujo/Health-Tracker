//
//  LoggerProtocol.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 03/01/26.
//

import Foundation

/// Protocol defining the logging interface for the application.
///
/// This protocol abstracts logging implementation details from the Domain layer,
/// allowing the use of different logging backends (OSLog, file logging, etc.)
/// while maintaining Clean Architecture boundaries.
///
/// The protocol is marked Sendable to support Swift 6 concurrency, allowing
/// loggers to be safely passed across concurrency boundaries.
protocol LoggerProtocol: Sendable {
    /// Log a debug message.
    ///
    /// Debug messages are used for detailed flow tracing and should be verbose.
    /// These are typically only visible in DEBUG builds.
    ///
    /// - Parameter message: The message to log
    func debug(_ message: String)

    /// Log an informational message.
    ///
    /// Info messages track successful operations and key business events.
    ///
    /// - Parameter message: The message to log
    func info(_ message: String)

    /// Log a warning message.
    ///
    /// Warning messages indicate recoverable errors or unexpected but handled states.
    ///
    /// - Parameter message: The message to log
    func warning(_ message: String)

    /// Log an error message.
    ///
    /// Error messages indicate failures and unrecoverable states.
    ///
    /// - Parameter message: The message to log
    func error(_ message: String)
}
