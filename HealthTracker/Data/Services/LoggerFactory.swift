//
//  LoggerFactory.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 03/01/26.
//

import Foundation

/// Factory for creating loggers with consistent subsystem naming.
///
/// Provides convenience methods for creating loggers organized by architectural layer:
/// - Domain layer: com.healthtracker.domain
/// - Data layer: com.healthtracker.data
/// - Presentation layer: com.healthtracker.presentation
///
/// Each layer uses categories to identify features (e.g., "Data.Save", "Notifications.Scheduling").
enum LoggerFactory {
    /// Create a logger for the Domain layer (use cases, business logic).
    ///
    /// - Parameter category: Feature identifier (e.g., "Data.Save", "Notifications.Scheduling")
    /// - Returns: Logger instance configured for domain layer
    static func domainLogger(category: String) -> LoggerProtocol {
        OSLogLogger(subsystem: "com.healthtracker.domain", category: category)
    }

    /// Create a logger for the Data layer (repositories, data sources, services).
    ///
    /// - Parameter category: Feature identifier (e.g., "Storage.iCloud", "Repository.DayData")
    /// - Returns: Logger instance configured for data layer
    static func dataLogger(category: String) -> LoggerProtocol {
        OSLogLogger(subsystem: "com.healthtracker.data", category: category)
    }

    /// Create a logger for the Presentation layer (ViewModels, UI coordination).
    ///
    /// - Parameter category: Feature identifier (e.g., "MainView", "AnalyticsView")
    /// - Returns: Logger instance configured for presentation layer
    static func presentationLogger(category: String) -> LoggerProtocol {
        OSLogLogger(subsystem: "com.healthtracker.presentation", category: category)
    }
}
