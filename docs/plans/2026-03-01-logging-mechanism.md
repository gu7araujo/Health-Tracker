# Logging Mechanism Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add comprehensive OSLog-based logging throughout HealthTracker following Clean Architecture with protocol-based dependency injection.

**Architecture:** Protocol in Domain layer, OSLogLogger implementation in Data layer, MockLogger in test target. Loggers injected via initializers with hybrid subsystem (layer) + category (feature) organization.

**Tech Stack:** Swift 6.0, OSLog (os.Logger), XCTest

---

## Task 1: Infrastructure - LoggerProtocol (Domain Layer)

**Files:**
- Create: `HealthTracker/Domain/Protocols/LoggerProtocol.swift`

**Step 1: Create LoggerProtocol file**

Create the protocol file with basic structure:

```swift
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

    /// Log a debug message with structured metadata.
    ///
    /// - Parameters:
    ///   - message: The message to log
    ///   - metadata: Additional context as key-value pairs
    func debug(_ message: String, metadata: [String: Any])

    /// Log an informational message with structured metadata.
    ///
    /// - Parameters:
    ///   - message: The message to log
    ///   - metadata: Additional context as key-value pairs
    func info(_ message: String, metadata: [String: Any])

    /// Log a warning message with structured metadata.
    ///
    /// - Parameters:
    ///   - message: The message to log
    ///   - metadata: Additional context as key-value pairs
    func warning(_ message: String, metadata: [String: Any])

    /// Log an error message with structured metadata.
    ///
    /// - Parameters:
    ///   - message: The message to log
    ///   - metadata: Additional context as key-value pairs
    func error(_ message: String, metadata: [String: Any])
}
```

**Step 2: Verify file compiles**

Build the project to ensure the protocol is valid:

```bash
xcodebuild -project HealthTracker.xcodeproj -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

Expected: Build succeeds

**Step 3: Commit**

```bash
git add HealthTracker/Domain/Protocols/LoggerProtocol.swift
git commit -m "feat(logging): add LoggerProtocol in Domain layer

Add protocol-based logging interface following Clean Architecture.
Protocol is Sendable for Swift 6 concurrency support.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 2: Infrastructure - OSLogLogger (Data Layer)

**Files:**
- Create: `HealthTracker/Data/Services/OSLogLogger.swift`

**Step 1: Create OSLogLogger implementation**

Create the concrete implementation using Apple's OSLog:

```swift
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
final class OSLogLogger: LoggerProtocol, Sendable {
    private let logger: Logger
    private let isDebugBuild: Bool

    /// Initialize an OSLog logger with subsystem and category.
    ///
    /// - Parameters:
    ///   - subsystem: Reverse-DNS style identifier (e.g., "com.healthtracker.domain")
    ///   - category: Feature or component identifier (e.g., "Data.Save")
    ///   - isDebugBuild: Whether this is a debug build (defaults to compile-time check)
    init(subsystem: String, category: String, isDebugBuild: Bool = isDebugConfiguration()) {
        self.logger = Logger(subsystem: subsystem, category: category)
        self.isDebugBuild = isDebugBuild
    }

    // MARK: - LoggerProtocol Implementation

    func debug(_ message: String) {
        logger.debug("\(message, privacy: privacyLevel)")
    }

    func info(_ message: String) {
        logger.info("\(message, privacy: privacyLevel)")
    }

    func warning(_ message: String) {
        logger.warning("\(message, privacy: privacyLevel)")
    }

    func error(_ message: String) {
        logger.error("\(message, privacy: privacyLevel)")
    }

    func debug(_ message: String, metadata: [String: Any]) {
        logger.debug("\(message, privacy: privacyLevel) | metadata: \(String(describing: metadata), privacy: privacyLevel)")
    }

    func info(_ message: String, metadata: [String: Any]) {
        logger.info("\(message, privacy: privacyLevel) | metadata: \(String(describing: metadata), privacy: privacyLevel)")
    }

    func warning(_ message: String, metadata: [String: Any]) {
        logger.warning("\(message, privacy: privacyLevel) | metadata: \(String(describing: metadata), privacy: privacyLevel)")
    }

    func error(_ message: String, metadata: [String: Any]) {
        logger.error("\(message, privacy: privacyLevel) | metadata: \(String(describing: metadata), privacy: privacyLevel)")
    }

    // MARK: - Private Helpers

    /// Privacy level based on build configuration.
    ///
    /// DEBUG builds use .public (visible), RELEASE builds use .private (redacted).
    private var privacyLevel: OSLogPrivacy {
        isDebugBuild ? .public : .private
    }
}

/// Helper function to detect debug build configuration.
///
/// Returns true when running in DEBUG mode, false otherwise.
private func isDebugConfiguration() -> Bool {
    #if DEBUG
    return true
    #else
    return false
    #endif
}
```

**Step 2: Verify file compiles**

Build the project:

```bash
xcodebuild -project HealthTracker.xcodeproj -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

Expected: Build succeeds

**Step 3: Commit**

```bash
git add HealthTracker/Data/Services/OSLogLogger.swift
git commit -m "feat(logging): add OSLogLogger implementation in Data layer

Concrete implementation using Apple's os.Logger with privacy controls:
- DEBUG builds: public logging
- RELEASE builds: private (redacted) logging

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 3: Infrastructure - LoggerFactory Helper

**Files:**
- Create: `HealthTracker/Data/Services/LoggerFactory.swift`

**Step 1: Create LoggerFactory**

Create factory for consistent logger creation:

```swift
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
```

**Step 2: Verify file compiles**

Build the project:

```bash
xcodebuild -project HealthTracker.xcodeproj -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

Expected: Build succeeds

**Step 3: Commit**

```bash
git add HealthTracker/Data/Services/LoggerFactory.swift
git commit -m "feat(logging): add LoggerFactory for consistent logger creation

Factory provides layer-specific logger creation with hybrid
subsystem (layer) + category (feature) organization.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 4: Testing Infrastructure - MockLogger

**Files:**
- Create: `HealthTrackerTests/Mocks/MockLogger.swift`

**Step 1: Create MockLogger**

Create mock logger following the MockNotificationService pattern:

```swift
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
/// - Reset state between tests
final class MockLogger: LoggerProtocol {
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

    func debug(_ message: String, metadata: [String: Any]) {
        debugMessages.append("\(message) | metadata: \(metadata)")
    }

    func info(_ message: String, metadata: [String: Any]) {
        infoMessages.append("\(message) | metadata: \(metadata)")
    }

    func warning(_ message: String, metadata: [String: Any]) {
        warningMessages.append("\(message) | metadata: \(metadata)")
    }

    func error(_ message: String, metadata: [String: Any]) {
        errorMessages.append("\(message) | metadata: \(metadata)")
    }

    // MARK: - Test Helpers

    /// Reset all captured messages.
    ///
    /// Call this in test setUp or between test assertions to start fresh.
    func reset() {
        debugMessages.removeAll()
        infoMessages.removeAll()
        warningMessages.removeAll()
        errorMessages.removeAll()
    }

    /// Check if a message was logged at the specified level.
    ///
    /// - Parameters:
    ///   - level: The log level to check
    ///   - substring: A substring to search for in messages
    /// - Returns: true if any message at the level contains the substring
    func didLog(level: LogLevel, containing substring: String) -> Bool {
        let messages: [String]
        switch level {
        case .debug: messages = debugMessages
        case .info: messages = infoMessages
        case .warning: messages = warningMessages
        case .error: messages = errorMessages
        }
        return messages.contains { $0.contains(substring) }
    }

    /// Get all messages logged at a specific level.
    ///
    /// - Parameter level: The log level to retrieve
    /// - Returns: Array of messages at that level
    func messages(for level: LogLevel) -> [String] {
        switch level {
        case .debug: return debugMessages
        case .info: return infoMessages
        case .warning: return warningMessages
        case .error: return errorMessages
        }
    }
}

/// Log levels for MockLogger test helpers.
enum LogLevel {
    case debug
    case info
    case warning
    case error
}
```

**Step 2: Verify file compiles**

Build tests:

```bash
xcodebuild -project HealthTracker.xcodeproj -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build-for-testing
```

Expected: Build succeeds

**Step 3: Commit**

```bash
git add HealthTrackerTests/Mocks/MockLogger.swift
git commit -m "test(logging): add MockLogger for unit testing

Mock implementation captures messages and provides test helpers
for verifying logging behavior.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 5: Add Logging to SaveDayDataUseCase

**Files:**
- Modify: `HealthTracker/Domain/UseCases/SaveDayDataUseCase.swift`
- Create: `HealthTrackerTests/Domain/SaveDayDataUseCaseLoggingTests.swift`

**Step 1: Write the failing test**

Create test file for logging behavior:

```swift
//
//  SaveDayDataUseCaseLoggingTests.swift
//  HealthTrackerTests
//
//  Created by Gustavo Araujo Santos on 03/01/26.
//

import XCTest
@testable import HealthTracker

final class SaveDayDataUseCaseLoggingTests: XCTestCase {
    func testExecuteLogsSaveOperation() {
        // Arrange
        let mockRepository = MockHealthDataRepository()
        let mockLogger = MockLogger()
        let useCase = SaveDayDataUseCase(repository: mockRepository, logger: mockLogger)

        let testDate = Date(timeIntervalSince1970: 1709251200) // 2024-03-01 00:00:00 UTC
        let dayData = RecordedDayData(date: testDate, meals: [], workouts: [], waterIntake: nil, mood: nil)

        // Act
        useCase.execute(dayData: dayData)

        // Assert
        XCTAssertTrue(mockLogger.didLog(level: .debug, containing: "Saving day data"))
        XCTAssertTrue(mockLogger.didLog(level: .info, containing: "saved successfully"))
    }
}
```

**Step 2: Run test to verify it fails**

```bash
xcodebuild test -project HealthTracker.xcodeproj -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:HealthTrackerTests/SaveDayDataUseCaseLoggingTests/testExecuteLogsSaveOperation
```

Expected: FAIL - SaveDayDataUseCase init doesn't accept logger parameter

**Step 3: Add logger to SaveDayDataUseCase**

Modify the use case to accept and use logger:

```swift
//
//  SaveDayDataUseCase.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/18/25.
//

import Foundation

/// Use case for saving health tracking data.
/// Encapsulates the business logic for persisting day data.
final class SaveDayDataUseCase {
    private let repository: HealthDataRepositoryProtocol
    private let logger: LoggerProtocol

    init(repository: HealthDataRepositoryProtocol, logger: LoggerProtocol) {
        self.repository = repository
        self.logger = logger
    }

    /// Saves all day data entries, replacing existing data.
    /// - Parameter days: Array of `RecordedDayData` to persist (only non-empty days).
    func execute(days: [RecordedDayData]) {
        logger.debug("Saving \(days.count) days of data")
        repository.save(days: days)
        logger.info("Successfully saved \(days.count) days of data")
    }

    /// Saves or updates a single day's data.
    /// - Parameter dayData: The `RecordedDayData` to save or update.
    func execute(dayData: RecordedDayData) {
        logger.debug("Saving day data for date: \(dayData.date)")
        repository.saveDayData(dayData)
        logger.info("Day data saved successfully for date: \(dayData.date)")
    }
}
```

**Step 4: Run test to verify it passes**

```bash
xcodebuild test -project HealthTracker.xcodeproj -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:HealthTrackerTests/SaveDayDataUseCaseLoggingTests/testExecuteLogsSaveOperation
```

Expected: PASS

**Step 5: Commit**

```bash
git add HealthTracker/Domain/UseCases/SaveDayDataUseCase.swift HealthTrackerTests/Domain/SaveDayDataUseCaseLoggingTests.swift
git commit -m "feat(logging): add logging to SaveDayDataUseCase

Add logger dependency injection and log messages for save operations.
Includes test coverage for logging behavior.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 6: Add Logging to LoadDayDataUseCase

**Files:**
- Modify: `HealthTracker/Domain/UseCases/LoadDayDataUseCase.swift`
- Create: `HealthTrackerTests/Domain/LoadDayDataUseCaseLoggingTests.swift`

**Step 1: Write the failing test**

```swift
//
//  LoadDayDataUseCaseLoggingTests.swift
//  HealthTrackerTests
//
//  Created by Gustavo Araujo Santos on 03/01/26.
//

import XCTest
@testable import HealthTracker

final class LoadDayDataUseCaseLoggingTests: XCTestCase {
    func testExecuteLogsLoadOperation() {
        // Arrange
        let mockRepository = MockHealthDataRepository()
        let mockLogger = MockLogger()
        let useCase = LoadDayDataUseCase(repository: mockRepository, logger: mockLogger)

        // Act
        let _ = useCase.execute()

        // Assert
        XCTAssertTrue(mockLogger.didLog(level: .debug, containing: "Loading day data"))
        XCTAssertTrue(mockLogger.didLog(level: .info, containing: "Loaded"))
    }
}
```

**Step 2: Run test to verify it fails**

```bash
xcodebuild test -project HealthTracker.xcodeproj -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:HealthTrackerTests/LoadDayDataUseCaseLoggingTests/testExecuteLogsLoadOperation
```

Expected: FAIL - LoadDayDataUseCase init doesn't accept logger parameter

**Step 3: Add logger to LoadDayDataUseCase**

Read the current implementation first, then modify:

```bash
# This is a placeholder - implementer should read the file first
cat HealthTracker/Domain/UseCases/LoadDayDataUseCase.swift
```

Then modify to add logger parameter and log statements at the start and end of execute():

```swift
// Add to properties:
private let logger: LoggerProtocol

// Modify init to accept logger:
init(repository: HealthDataRepositoryProtocol, logger: LoggerProtocol) {
    self.repository = repository
    self.logger = logger
}

// Add at start of execute():
logger.debug("Loading day data from repository")

// Add before return:
logger.info("Loaded \(result.count) days of data")
```

**Step 4: Run test to verify it passes**

```bash
xcodebuild test -project HealthTracker.xcodeproj -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:HealthTrackerTests/LoadDayDataUseCaseLoggingTests/testExecuteLogsLoadOperation
```

Expected: PASS

**Step 5: Commit**

```bash
git add HealthTracker/Domain/UseCases/LoadDayDataUseCase.swift HealthTrackerTests/Domain/LoadDayDataUseCaseLoggingTests.swift
git commit -m "feat(logging): add logging to LoadDayDataUseCase

Add logger dependency injection and log messages for load operations.
Includes test coverage for logging behavior.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 7: Add Logging to CancelNotificationsUseCase

**Files:**
- Modify: `HealthTracker/Domain/UseCases/CancelNotificationsUseCase.swift`

**Step 1: Add logger to CancelNotificationsUseCase**

Read current file and add logger:

```swift
// Add to properties:
private let logger: LoggerProtocol

// Modify init:
init(notificationService: NotificationServiceProtocol, logger: LoggerProtocol) {
    self.notificationService = notificationService
    self.logger = logger
}

// Add logging in execute() method:
logger.debug("Canceling notifications for date: \(date)")
// ... existing code ...
logger.info("Successfully canceled notifications for date: \(date)")
```

**Step 2: Verify compiles**

```bash
xcodebuild -project HealthTracker.xcodeproj -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

Expected: Build succeeds

**Step 3: Commit**

```bash
git add HealthTracker/Domain/UseCases/CancelNotificationsUseCase.swift
git commit -m "feat(logging): add logging to CancelNotificationsUseCase

Log notification cancellation operations with date context.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 8: Add Logging to ScheduleNotificationsUseCase

**Files:**
- Modify: `HealthTracker/Domain/UseCases/ScheduleNotificationsUseCase.swift`

**Step 1: Add logger to ScheduleNotificationsUseCase**

```swift
// Add to properties:
private let logger: LoggerProtocol

// Modify init:
init(notificationService: NotificationServiceProtocol, logger: LoggerProtocol) {
    self.notificationService = notificationService
    self.logger = logger
}

// Add logging in execute() method:
logger.debug("Scheduling notifications for next 30 days")
// ... existing code ...
logger.info("Successfully scheduled \(notificationRequests.count) notifications")
```

**Step 2: Verify compiles**

```bash
xcodebuild -project HealthTracker.xcodeproj -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

Expected: Build succeeds

**Step 3: Commit**

```bash
git add HealthTracker/Domain/UseCases/ScheduleNotificationsUseCase.swift
git commit -m "feat(logging): add logging to ScheduleNotificationsUseCase

Log notification scheduling operations with count of scheduled notifications.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 9: Add Logging to RequestNotificationPermissionUseCase

**Files:**
- Modify: `HealthTracker/Domain/UseCases/RequestNotificationPermissionUseCase.swift`

**Step 1: Add logger to RequestNotificationPermissionUseCase**

```swift
// Add to properties:
private let logger: LoggerProtocol

// Modify init:
init(notificationService: NotificationServiceProtocol, logger: LoggerProtocol) {
    self.notificationService = notificationService
    self.logger = logger
}

// Add logging in execute() method:
logger.debug("Requesting notification permission")
// ... after permission request ...
if granted {
    logger.info("Notification permission granted")
} else {
    logger.warning("Notification permission denied")
}
// ... on error ...
logger.error("Failed to request notification permission: \(error.localizedDescription)")
```

**Step 2: Verify compiles**

```bash
xcodebuild -project HealthTracker.xcodeproj -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

Expected: Build succeeds

**Step 3: Commit**

```bash
git add HealthTracker/Domain/UseCases/RequestNotificationPermissionUseCase.swift
git commit -m "feat(logging): add logging to RequestNotificationPermissionUseCase

Log permission requests with granted/denied outcome and error handling.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 10: Add Logging to CalculateAnalyticsUseCase

**Files:**
- Modify: `HealthTracker/Domain/UseCases/CalculateAnalyticsUseCase.swift`

**Step 1: Add logger to CalculateAnalyticsUseCase**

```swift
// Add to properties:
private let logger: LoggerProtocol

// Modify init:
init(logger: LoggerProtocol) {
    self.logger = logger
}

// Add logging in execute() method:
logger.debug("Calculating analytics for \(days.count) days")
// ... existing code ...
logger.info("Analytics calculated: \(result.totalMeals) meals, \(result.totalWorkouts) workouts")
```

**Step 2: Verify compiles**

```bash
xcodebuild -project HealthTracker.xcodeproj -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

Expected: Build succeeds

**Step 3: Commit**

```bash
git add HealthTracker/Domain/UseCases/CalculateAnalyticsUseCase.swift
git commit -m "feat(logging): add logging to CalculateAnalyticsUseCase

Log analytics calculation with input day count and result summary.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 11: Add Logging to NotificationService

**Files:**
- Modify: `HealthTracker/Data/Services/NotificationService.swift`

**Step 1: Replace print() with logger**

Replace existing print() statements with proper logging:

```swift
// Add to properties:
private let logger: LoggerProtocol

// Modify init:
init(notificationCenter: UNUserNotificationCenter = .current(), logger: LoggerProtocol) {
    self.notificationCenter = notificationCenter
    self.logger = logger
}

// Replace print statements:
// OLD: print("[NotificationService] Delegate set (Phase 2 will implement bridging)")
// NEW: logger.debug("Delegate set (Phase 2 will implement bridging)")

// OLD: print("[NotificationService] Delegate removed")
// NEW: logger.debug("Delegate removed")

// Add logging for other operations:
// In requestAuthorization:
logger.debug("Requesting notification authorization")
logger.info("Notification authorization result: \(granted)")

// In authorizationStatus:
logger.debug("Checking notification authorization status")

// In schedule/cancel methods:
logger.debug("Scheduling notification: \(request.identifier)")
logger.debug("Canceling notification: \(identifier)")
```

**Step 2: Verify compiles**

```bash
xcodebuild -project HealthTracker.xcodeproj -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

Expected: Build succeeds

**Step 3: Commit**

```bash
git add HealthTracker/Data/Services/NotificationService.swift
git commit -m "feat(logging): add logging to NotificationService

Replace print() statements with proper logging and add comprehensive
logging for all notification operations.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 12: Add Logging to MainViewModel

**Files:**
- Modify: `HealthTracker/Presentation/ViewModels/MainViewModel.swift`

**Step 1: Add logger to MainViewModel**

```swift
// Add to properties:
private let logger: LoggerProtocol

// Modify init:
init(
    loadUseCase: LoadDayDataUseCase,
    saveUseCase: SaveDayDataUseCase,
    cancelNotificationsUseCase: CancelNotificationsUseCase,
    logger: LoggerProtocol
) {
    self.loadUseCase = loadUseCase
    self.saveUseCase = saveUseCase
    self.cancelNotificationsUseCase = cancelNotificationsUseCase
    self.logger = logger
}

// Add logging in key methods:
// In loadData():
logger.debug("Loading health data")
logger.info("Health data loaded successfully")

// In addMeal():
logger.debug("User adding meal")
logger.info("Meal added successfully")

// In addWorkout():
logger.debug("User adding workout")
logger.info("Workout added successfully")

// In updateWaterIntake():
logger.debug("User updating water intake")

// In updateMood():
logger.debug("User updating mood")

// In error handling:
logger.error("Failed to save data: \(error.localizedDescription)")
```

**Step 2: Verify compiles**

```bash
xcodebuild -project HealthTracker.xcodeproj -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

Expected: Build succeeds

**Step 3: Commit**

```bash
git add HealthTracker/Presentation/ViewModels/MainViewModel.swift
git commit -m "feat(logging): add logging to MainViewModel

Log user interactions and state changes in main view.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 13: Add Logging to AnalyticsViewModel

**Files:**
- Modify: `HealthTracker/Presentation/ViewModels/AnalyticsViewModel.swift`

**Step 1: Add logger to AnalyticsViewModel**

```swift
// Add to properties:
private let logger: LoggerProtocol

// Modify init to accept logger

// Add logging:
// When period changes:
logger.debug("Analytics period changed to: \(period)")

// When calculating:
logger.debug("Calculating analytics for period: \(period)")
logger.info("Analytics calculated successfully")

// On errors:
logger.error("Failed to calculate analytics: \(error.localizedDescription)")
```

**Step 2: Verify compiles**

```bash
xcodebuild -project HealthTracker.xcodeproj -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

Expected: Build succeeds

**Step 3: Commit**

```bash
git add HealthTracker/Presentation/ViewModels/AnalyticsViewModel.swift
git commit -m "feat(logging): add logging to AnalyticsViewModel

Log analytics calculations and period changes.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 14: Update Composition Root - App Entry Point

**Files:**
- Modify: `HealthTracker/HealthTrackerApp.swift` (or wherever dependency graph is built)

**Step 1: Create loggers in composition root**

Find where use cases and view models are instantiated and add logger creation:

```swift
// Create loggers
let saveUseCaseLogger = LoggerFactory.domainLogger(category: "Data.Save")
let loadUseCaseLogger = LoggerFactory.domainLogger(category: "Data.Load")
let scheduleNotifLogger = LoggerFactory.domainLogger(category: "Notifications.Scheduling")
let cancelNotifLogger = LoggerFactory.domainLogger(category: "Notifications.Cancellation")
let requestPermLogger = LoggerFactory.domainLogger(category: "Notifications.Permission")
let analyticsUseCaseLogger = LoggerFactory.domainLogger(category: "Analytics.Calculate")

let notificationServiceLogger = LoggerFactory.dataLogger(category: "Notifications.Service")
let repositoryLogger = LoggerFactory.dataLogger(category: "Repository.DayData")

let mainViewModelLogger = LoggerFactory.presentationLogger(category: "MainView")
let analyticsViewModelLogger = LoggerFactory.presentationLogger(category: "AnalyticsView")

// Update use case instantiations to include logger:
let saveUseCase = SaveDayDataUseCase(repository: repository, logger: saveUseCaseLogger)
let loadUseCase = LoadDayDataUseCase(repository: repository, logger: loadUseCaseLogger)
// ... etc for all use cases

// Update service instantiation:
let notificationService = NotificationService(logger: notificationServiceLogger)

// Update view model instantiations:
let mainViewModel = MainViewModel(
    loadUseCase: loadUseCase,
    saveUseCase: saveUseCase,
    cancelNotificationsUseCase: cancelNotificationsUseCase,
    logger: mainViewModelLogger
)
```

**Step 2: Build and run app**

```bash
xcodebuild -project HealthTracker.xcodeproj -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

Expected: Build succeeds

**Step 3: Verify logs in Console.app**

1. Launch the app in simulator
2. Open Console.app on Mac
3. Filter by "subsystem:com.healthtracker"
4. Interact with app and verify logs appear

Expected: Logs visible with proper subsystems and categories

**Step 4: Commit**

```bash
git add HealthTracker/HealthTrackerApp.swift
git commit -m "feat(logging): integrate logging throughout dependency graph

Create loggers with LoggerFactory and inject into all use cases,
services, and view models. Logging system now fully integrated.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 15: Update Existing Tests with MockLogger

**Files:**
- Modify: All existing test files that instantiate use cases, services, or view models

**Step 1: Update use case tests**

Find all test files that create use cases and add MockLogger:

```bash
# Find test files
find HealthTrackerTests -name "*UseCaseTests.swift" | grep -v Logging
```

For each test file:
- Add `let mockLogger = MockLogger()` in setUp or test method
- Update use case initialization to include `logger: mockLogger`

**Step 2: Update view model tests**

Find view model tests and update similarly.

**Step 3: Run all tests**

```bash
xcodebuild test -project HealthTracker.xcodeproj -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

Expected: All tests pass

**Step 4: Commit**

```bash
git add HealthTrackerTests/
git commit -m "test(logging): update existing tests to use MockLogger

Add MockLogger to all existing tests that instantiate components
requiring logger dependency. All tests passing.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 16: Search and Remove Remaining print() Statements

**Files:**
- Any files with remaining print() statements

**Step 1: Search for print statements**

```bash
grep -r "print(" HealthTracker/ --include="*.swift" | grep -v "// print"
```

**Step 2: Replace each print() with appropriate logging**

For each print() found:
- Determine appropriate log level (debug, info, warning, error)
- Replace with logger call
- Add logger parameter if component doesn't have one yet

**Step 3: Verify no prints remain**

```bash
grep -r "print(" HealthTracker/ --include="*.swift" | grep -v "// print"
```

Expected: No results (or only commented prints)

**Step 4: Build and test**

```bash
xcodebuild test -project HealthTracker.xcodeproj -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

Expected: All tests pass

**Step 5: Commit**

```bash
git add HealthTracker/
git commit -m "refactor(logging): remove all print() statements

Replace remaining print() statements with proper OSLog-based logging.
Application now uses logging system consistently throughout.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 17: Add SwiftLint Rule (Optional)

**Files:**
- Modify: `.swiftlint.yml` (if exists)
- Create: `.swiftlint.yml` (if doesn't exist)

**Step 1: Check if SwiftLint config exists**

```bash
ls -la .swiftlint.yml
```

**Step 2: Add or update rule to discourage print()**

Add to `.swiftlint.yml`:

```yaml
# Discourage print() usage - use logger instead
custom_rules:
  no_print:
    name: "No Print Statements"
    regex: "print\\("
    message: "Use logger instead of print() for consistent logging"
    severity: warning
```

**Step 3: Run SwiftLint**

```bash
swiftlint lint
```

Expected: No violations (or only warnings for legitimate prints)

**Step 4: Commit**

```bash
git add .swiftlint.yml
git commit -m "chore(logging): add SwiftLint rule to discourage print()

Prevent future print() usage by warning developers to use logger.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 18: Documentation - Update README or Add Logging Guide

**Files:**
- Create: `docs/LOGGING.md` (new guide)

**Step 1: Create logging documentation**

```markdown
# Logging Guide

## Overview

HealthTracker uses Apple's OSLog framework for comprehensive logging throughout the application. Logs are organized by architectural layer (Domain, Data, Presentation) and categorized by feature.

## Using Loggers

### Getting a Logger

Loggers are injected via dependency injection. Get them from LoggerFactory in your composition root:

\`\`\`swift
let logger = LoggerFactory.domainLogger(category: "Data.Save")
let useCase = SaveDayDataUseCase(repository: repository, logger: logger)
\`\`\`

### Log Levels

- **Debug**: Detailed flow tracing, visible only in DEBUG builds
- **Info**: Successful operations, key business events
- **Warning**: Recoverable errors, unexpected but handled states
- **Error**: Failures, exceptions, unrecoverable states

### Example Usage

\`\`\`swift
logger.debug("Starting operation with \(count) items")
logger.info("Operation completed successfully")
logger.warning("Unexpected state, using fallback")
logger.error("Operation failed: \(error.localizedDescription)")
\`\`\`

## Privacy

All logs respect privacy based on build configuration:
- **DEBUG builds**: Full visibility (`.public`)
- **RELEASE builds**: Automatic redaction (`.private`)

Never log sensitive health data (meal quantities, workout durations, mood ratings).

## Viewing Logs

### Console.app

1. Open Console.app on Mac
2. Connect your device or select simulator
3. Filter by subsystem: `subsystem:com.healthtracker`
4. Filter by category: `category:Data.Save`
5. Combine: `subsystem:com.healthtracker.domain AND category:Notifications.Scheduling`

### Xcode Console

Logs appear in Xcode console during debugging. Use `os_log` tool for filtering:

\`\`\`bash
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.healthtracker"'
\`\`\`

## Organization

**Subsystems (by layer):**
- `com.healthtracker.domain` - Use cases, business logic
- `com.healthtracker.data` - Repositories, persistence, services
- `com.healthtracker.presentation` - ViewModels, UI coordination

**Categories (by feature):**
- Domain: `Data.Save`, `Data.Load`, `Notifications.Scheduling`, etc.
- Data: `Storage.iCloud`, `Repository.DayData`, `Notifications.Service`, etc.
- Presentation: `MainView`, `AnalyticsView`, etc.

## Testing

Use `MockLogger` in tests to verify logging behavior:

\`\`\`swift
let mockLogger = MockLogger()
let useCase = SaveDayDataUseCase(repository: mockRepository, logger: mockLogger)

useCase.execute(dayData: testData)

XCTAssertTrue(mockLogger.didLog(level: .info, containing: "saved successfully"))
\`\`\`

## Best Practices

✅ **Do:**
- Log at layer boundaries (entry/exit)
- Log state changes and decisions
- Log errors with context
- Use appropriate log levels
- Keep messages concise and searchable

❌ **Don't:**
- Log sensitive health data
- Use logging for control flow
- Log every line of code
- Mix print() and logger
- Create logger per method call (inject once)
```

**Step 2: Commit**

```bash
git add docs/LOGGING.md
git commit -m "docs(logging): add comprehensive logging guide

Document how to use the logging system, view logs, and follow
best practices for privacy-aware logging.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Success Criteria

The implementation is complete when:

1. ✅ LoggerProtocol exists in Domain layer
2. ✅ OSLogLogger implements protocol in Data layer
3. ✅ MockLogger available for testing
4. ✅ All use cases have logging integrated
5. ✅ All services (NotificationService, repositories) have logging
6. ✅ All view models have logging
7. ✅ No print() statements remain in codebase
8. ✅ All existing tests updated to use MockLogger
9. ✅ All tests pass
10. ✅ Logs visible in Console.app with proper filtering
11. ✅ Documentation complete

## Testing Strategy

- Write tests before implementation (TDD)
- Use MockLogger to verify logging behavior
- Don't test that logging happens unless it's critical to behavior
- Use logging to debug test failures
- Keep test assertions focused on behavior, not implementation

## Related Skills

- @swift-concurrency - LoggerProtocol is Sendable for Swift 6
- @swift-api-design-guidelines - Protocol and API naming
- @systematic-debugging - Use logs to debug issues
- @test-driven-development - TDD approach throughout

---

**Implementation Notes:**

- Each task is 2-5 minutes of focused work
- Frequent commits after each completed task
- Build and test incrementally
- Use exact file paths
- Follow existing code style and patterns
- Maintain Clean Architecture boundaries
- DRY: LoggerFactory prevents subsystem name duplication
- YAGNI: No complex features, just OSLog basics
