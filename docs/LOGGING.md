# Logging Guide

## Overview

HealthTracker uses Apple's OSLog framework for comprehensive logging throughout the application. Logs are organized by architectural layer (Domain, Data, Presentation) and categorized by feature.

## Using Loggers

### Getting a Logger

Loggers are injected via dependency injection. Get them from LoggerFactory in your composition root:

```swift
let logger = LoggerFactory.domainLogger(category: "Data.Save")
let useCase = SaveDayDataUseCase(repository: repository, logger: logger)
```

### Log Levels

- **Debug**: Detailed flow tracing, visible only in DEBUG builds
- **Info**: Successful operations, key business events
- **Warning**: Recoverable errors, unexpected but handled states
- **Error**: Failures, exceptions, unrecoverable states

### Example Usage

```swift
logger.debug("Starting operation with \(count) items")
logger.info("Operation completed successfully")
logger.warning("Unexpected state, using fallback")
logger.error("Operation failed: \(error.localizedDescription)")
```

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

```bash
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.healthtracker"'
```

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

```swift
let mockLogger = MockLogger()
let useCase = SaveDayDataUseCase(repository: mockRepository, logger: mockLogger)

useCase.execute(dayData: testData)

XCTAssertTrue(mockLogger.didLog(level: .info, containing: "saved successfully"))
```

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
