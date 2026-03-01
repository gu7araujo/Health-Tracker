# Logging Mechanism Design

**Date:** 2026-03-01
**Status:** Approved
**Purpose:** Add comprehensive debug and development logging throughout HealthTracker application

## Overview

Implement a protocol-based logging system using Apple's OSLog framework that integrates with HealthTracker's Clean Architecture pattern. The system will provide comprehensive visibility during development while maintaining privacy controls for health data.

## Requirements Summary

- **Purpose:** Debug and development logging to troubleshoot issues during development and TestFlight
- **Scope:** Comprehensive logging across all layers (Domain, Data, Presentation)
- **Log Levels:** Debug, Info, Warning, Error (standard levels)
- **Framework:** OSLog (os.Logger) - Apple's native unified logging system
- **Privacy:** Full logging in DEBUG builds, automatic redaction in RELEASE builds
- **Organization:** Hybrid approach - subsystems by architecture layer, categories by feature

## Architecture & Layer Organization

### Clean Architecture Integration

The logging system follows the existing three-layer Clean Architecture pattern:

**Domain Layer** (`HealthTracker/Domain/Protocols/`)
- `LoggerProtocol` - Abstract logging interface
- No iOS framework imports, pure Swift
- Defines log levels: debug, info, warning, error
- Each method takes a message and optional privacy-sensitive parameters

**Data Layer** (`HealthTracker/Data/Services/`)
- `OSLogLogger` - Concrete implementation using Apple's `os.Logger`
- Imports `OSLog` framework (only file that should)
- Handles subsystem/category configuration
- Implements privacy controls based on build configuration (DEBUG vs RELEASE)

**Presentation Layer** (ViewModels)
- Receives logger via dependency injection
- Uses logger for UI state changes and user interactions

### Subsystem & Category Structure (Hybrid Organization)

**Subsystems by Layer:**
- `com.healthtracker.domain` - Use cases, business logic
- `com.healthtracker.data` - Repositories, persistence, services
- `com.healthtracker.presentation` - ViewModels, UI coordination

**Categories by Feature:**
- Domain: `Notifications.Scheduling`, `Notifications.Cancellation`, `Data.Save`, `Data.Load`, `Analytics.Calculate`
- Data: `Storage.iCloud`, `Storage.Local`, `Notifications.Service`, `Repository.DayData`
- Presentation: `MainView`, `AnalyticsView`, `DateSelection`

**Example log filtering in Console.app:**
```
subsystem:com.healthtracker.domain AND category:Notifications.Scheduling
```

This provides both layer-based and feature-based filtering capabilities.

## Protocol Design & Implementation

### LoggerProtocol (Domain Layer)

```swift
protocol LoggerProtocol: Sendable {
    func debug(_ message: String)
    func info(_ message: String)
    func warning(_ message: String)
    func error(_ message: String)

    // For logging with context/metadata
    func debug(_ message: String, metadata: [String: Any])
    func info(_ message: String, metadata: [String: Any])
    func warning(_ message: String, metadata: [String: Any])
    func error(_ message: String, metadata: [String: Any])
}
```

**Key decisions:**
- Simple String-based messages (most common case)
- Optional metadata dictionary for structured logging (dates, IDs, counts)
- No varargs or string interpolation in protocol (keeps it clean)
- Sendable conformance for Swift 6 concurrency safety

### OSLogLogger (Data Layer)

```swift
import OSLog

final class OSLogLogger: LoggerProtocol, Sendable {
    private let logger: Logger
    private let isDebugBuild: Bool

    init(subsystem: String, category: String, isDebugBuild: Bool = isDebugConfiguration()) {
        self.logger = Logger(subsystem: subsystem, category: category)
        self.isDebugBuild = isDebugBuild
    }

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

    // Metadata overloads
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

    private var privacyLevel: OSLogPrivacy {
        isDebugBuild ? .public : .private
    }
}
```

**Key features:**
- Privacy control: public in DEBUG, private in RELEASE builds
- Build configuration detected at initialization
- Each logger instance tied to specific subsystem/category
- Thread-safe (Sendable) for use with Swift Concurrency

### Logger Factory Pattern

```swift
enum LoggerFactory {
    static func domainLogger(category: String) -> LoggerProtocol {
        OSLogLogger(subsystem: "com.healthtracker.domain", category: category)
    }

    static func dataLogger(category: String) -> LoggerProtocol {
        OSLogLogger(subsystem: "com.healthtracker.data", category: category)
    }

    static func presentationLogger(category: String) -> LoggerProtocol {
        OSLogLogger(subsystem: "com.healthtracker.presentation", category: category)
    }
}
```

This factory simplifies logger creation in the composition root and keeps subsystem names consistent.

## Component Integration

### Dependency Injection Pattern

Following the existing DI pattern, loggers are injected through initializers alongside other dependencies.

**Use Case Example:**
```swift
final class SaveDayDataUseCase {
    private let repository: DayDataRepository
    private let logger: LoggerProtocol

    init(repository: DayDataRepository, logger: LoggerProtocol) {
        self.repository = repository
        self.logger = logger
    }

    func execute(_ data: DayData) async throws {
        logger.debug("Starting save operation for date: \(data.date)")

        do {
            try await repository.save(data)
            logger.info("Day data saved successfully for date: \(data.date)")
        } catch {
            logger.error("Failed to save day data: \(error.localizedDescription)")
            throw error
        }
    }
}
```

**Repository Example:**
```swift
final class CloudDayDataRepository: DayDataRepository {
    private let localDataSource: LocalDayDataSource
    private let cloudDataSource: CloudDayDataSource
    private let logger: LoggerProtocol

    init(
        localDataSource: LocalDayDataSource,
        cloudDataSource: CloudDayDataSource,
        logger: LoggerProtocol
    ) {
        self.localDataSource = localDataSource
        self.cloudDataSource = cloudDataSource
        self.logger = logger
    }

    func save(_ data: DayData) async throws {
        logger.debug("Saving to local storage first")
        try await localDataSource.save(data)

        logger.debug("Syncing to iCloud")
        try await cloudDataSource.save(data)

        logger.info("Data synced successfully")
    }
}
```

**ViewModel Example:**
```swift
@Observable
final class MainViewModel {
    private let loadUseCase: LoadDayDataUseCase
    private let saveUseCase: SaveDayDataUseCase
    private let cancelNotificationsUseCase: CancelNotificationsUseCase
    private let logger: LoggerProtocol

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

    func addMeal(_ meal: Meal) async {
        logger.debug("User adding meal")

        guard var currentDay = currentDayData else {
            logger.warning("No current day data available")
            return
        }

        currentDay.meals.append(meal)

        do {
            try await saveUseCase.execute(currentDay)
            logger.info("Meal added and saved")

            await cancelNotificationsUseCase.execute(for: selectedDate)
            logger.debug("Notifications canceled after meal entry")
        } catch {
            logger.error("Failed to add meal: \(error.localizedDescription)")
        }
    }
}
```

### Composition Root Updates

The app entry point creates loggers and injects them:

```swift
@main
struct HealthTrackerApp: App {
    init() {
        // Create loggers
        let saveUseCaseLogger = LoggerFactory.domainLogger(category: "Data.Save")
        let repositoryLogger = LoggerFactory.dataLogger(category: "Repository.DayData")
        let viewModelLogger = LoggerFactory.presentationLogger(category: "MainView")

        // Build dependency graph with loggers
        let repository = CloudDayDataRepository(
            localDataSource: localDataSource,
            cloudDataSource: cloudDataSource,
            logger: repositoryLogger
        )

        let saveUseCase = SaveDayDataUseCase(
            repository: repository,
            logger: saveUseCaseLogger
        )

        // ... rest of initialization
    }
}
```

## Testing Strategy

### MockLogger for Unit Tests

Following the existing pattern with `MockNotificationService`, create a `MockLogger` for testing:

```swift
final class MockLogger: LoggerProtocol {
    private(set) var debugMessages: [String] = []
    private(set) var infoMessages: [String] = []
    private(set) var warningMessages: [String] = []
    private(set) var errorMessages: [String] = []

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

    // Test helpers
    func reset() {
        debugMessages.removeAll()
        infoMessages.removeAll()
        warningMessages.removeAll()
        errorMessages.removeAll()
    }

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
}

enum LogLevel {
    case debug, info, warning, error
}
```

### Test Examples

**Use Case Test:**
```swift
func testSaveUseCaseLogsSuccessfully() async throws {
    let mockLogger = MockLogger()
    let mockRepository = MockDayDataRepository()
    let useCase = SaveDayDataUseCase(
        repository: mockRepository,
        logger: mockLogger
    )

    let data = DayData(date: Date())
    try await useCase.execute(data)

    // Verify logging occurred
    XCTAssertTrue(mockLogger.didLog(level: .debug, containing: "Starting save"))
    XCTAssertTrue(mockLogger.didLog(level: .info, containing: "saved successfully"))
    XCTAssertEqual(mockLogger.errorMessages.count, 0)
}

func testSaveUseCaseLogsError() async throws {
    let mockLogger = MockLogger()
    let mockRepository = MockDayDataRepository(shouldFail: true)
    let useCase = SaveDayDataUseCase(
        repository: mockRepository,
        logger: mockLogger
    )

    let data = DayData(date: Date())

    do {
        try await useCase.execute(data)
        XCTFail("Should have thrown error")
    } catch {
        // Verify error was logged
        XCTAssertTrue(mockLogger.didLog(level: .error, containing: "Failed to save"))
    }
}
```

**ViewModel Test:**
```swift
func testAddMealLogsWarningWhenNoCurrentDay() async {
    let mockLogger = MockLogger()
    let viewModel = MainViewModel(
        loadUseCase: loadUseCase,
        saveUseCase: saveUseCase,
        cancelNotificationsUseCase: cancelUseCase,
        logger: mockLogger
    )

    // No day data loaded
    await viewModel.addMeal(meal)

    XCTAssertTrue(mockLogger.didLog(level: .warning, containing: "No current day data"))
}
```

### Test Coverage Approach

- **Don't test logging itself** - Don't write tests just to verify logs happen
- **Test behavior, verify logs** - Use MockLogger to verify component behavior through log inspection
- **Use for debugging test failures** - When tests fail, check logged messages in MockLogger
- **Optional assertions** - Only assert on critical logs (errors, warnings) in tests

## Implementation Guidelines & Best Practices

### What to Log at Each Level

**Debug Level:**
- Method entry/exit with parameters
- Loop iterations and conditional branches
- Internal state changes
- Data transformations

**Info Level:**
- Successful completion of operations
- Key business events (meal saved, notification scheduled)
- State transitions (loading → loaded)
- User actions (button taps, navigation)

**Warning Level:**
- Recoverable errors (retry succeeded)
- Unexpected but handled states (missing data with fallback)
- Deprecated code paths
- Performance degradation

**Error Level:**
- Exceptions and thrown errors
- Failed operations (save failed, network error)
- Data corruption
- Unrecoverable states

### Privacy Guidelines

**Always redact in logs:**
- Meal quantities and satisfaction ratings
- Workout durations and types
- Water intake values
- Mood ratings
- Any health metrics

**Safe to log:**
- Dates (day-level granularity)
- Count of items (e.g., "Saved 3 meals")
- Success/failure status
- Error types (not error messages containing data)

**Example:**
```swift
// Good - no sensitive data
logger.info("Saved meal for date: \(date)")

// Bad - exposes health data
logger.info("Saved meal: quantity=\(meal.quantity), satisfaction=\(meal.satisfaction)")

// Good - aggregate count only
logger.debug("User has \(meals.count) meals for today")
```

### Migration Strategy

Replace existing `print()` statements incrementally:

**Phase 1 - Infrastructure:**
1. Add LoggerProtocol to Domain layer
2. Add OSLogLogger to Data layer
3. Add LoggerFactory helper
4. Add MockLogger to test target

**Phase 2 - Critical Paths:**
1. NotificationService (replace existing prints)
2. SaveDayDataUseCase and LoadDayDataUseCase
3. CloudDayDataRepository and data sources
4. MainViewModel

**Phase 3 - Remaining Components:**
1. Analytics use cases
2. Other view models
3. Utility components

**Phase 4 - Cleanup:**
1. Search for remaining `print()` statements
2. Remove or replace with proper logging
3. Add SwiftLint rule to prevent `print()` usage

### Performance Considerations

**OSLog is highly optimized:**
- Logs are stored in a compact binary format
- Console.app reads from unified logging system
- Minimal performance impact even with verbose logging
- String interpolation is lazy (only evaluated if log level active)

**Best practices:**
- Don't pre-format expensive strings before logging (OSLog does lazy evaluation)
- Use `logger.debug` liberally - disabled in Release builds automatically
- Avoid logging in tight loops (batch log summary instead)

### Anti-Patterns to Avoid

**Don't:**
- ❌ Log sensitive health data without privacy markers
- ❌ Use logging for control flow (checking if something was logged)
- ❌ Log every line of code (adds noise)
- ❌ Create logger per method call (create once, reuse)
- ❌ Mix print() and logger (choose one system)

**Do:**
- ✅ Log at boundaries (entry/exit of layers)
- ✅ Log state changes and decisions
- ✅ Log errors with context
- ✅ Use appropriate log levels
- ✅ Keep messages concise and searchable

## Trade-offs & Decisions

### Chosen: Protocol-Based Logger

**Pros:**
- Perfect alignment with Clean Architecture pattern
- Fully testable (MockLogger in tests)
- Follows existing dependency injection pattern
- Domain layer stays independent of iOS frameworks
- Easy to switch implementations later

**Cons:**
- Requires passing logger through initializers (more parameters)
- Slightly more boilerplate (protocol + implementation)
- Need to update factory/composition root to inject loggers

**Alternatives Considered:**

1. **Global Logger Singleton** - Rejected because it violates Clean Architecture, hard to test, couples code to concrete implementation
2. **Type-Based Automatic Logging** - Rejected because it's less explicit about dependencies, harder to customize per-component

### Chosen: DEBUG/RELEASE Privacy Toggle

**Rationale:**
- Full visibility during development for debugging
- Automatic privacy in production builds
- Aligns with Apple's best practices for OSLog
- No risk of accidentally shipping verbose logs

**Alternative:** Always redact - Would make debugging significantly harder during development

### Chosen: Hybrid Subsystem/Category Organization

**Rationale:**
- Subsystems by layer align with architecture
- Categories by feature enable feature-specific filtering
- Provides maximum flexibility for different debugging scenarios

**Alternative:** Single organizational scheme (layer-only or feature-only) - Would limit filtering options

## Success Criteria

The logging system will be considered successful when:

1. ✅ All layers (Domain, Data, Presentation) have logging integrated
2. ✅ Existing `print()` statements replaced with proper logging
3. ✅ MockLogger used in all unit tests requiring logging verification
4. ✅ Console.app can filter logs by subsystem and category
5. ✅ No sensitive health data appears in RELEASE build logs
6. ✅ DEBUG builds show full log details for troubleshooting
7. ✅ Zero impact on existing functionality (tests still pass)

## Next Steps

After design approval:
1. Create implementation plan using `writing-plans` skill
2. Break down into atomic tasks for each phase
3. Implement incrementally with tests
4. Review and verify logging output in Console.app

---

*Design approved: 2026-03-01*
