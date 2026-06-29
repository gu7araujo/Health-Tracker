# Data Layer Architecture

## Directory Map

| Directory / File | Type | Responsibility |
|---|---|---|
| `DataSources/` | — | Raw I/O adapters that read/write bytes; no business logic |
| `DataSources/ICloudDriveDataSource.swift` | `class ICloudDriveDataSource` | Persists the JSON container to iCloud Drive using `NSFileCoordinator` |
| `DataSources/UserDefaultsDataSource.swift` | `protocol LocalDataSourceProtocol`, `class UserDefaultsDataSource` | Defines the local-storage contract and its `UserDefaults`-backed implementation |
| `Repositories/` | — | Orchestrates data sources; exposes domain-friendly CRUD operations |
| `Repositories/HealthDataRepository.swift` | `class HealthDataRepository` | Loads/saves all days, retrieves a single day, and queries ranges via the injected data source |
| `Models/` | — | Serialisable data-transfer types shared between data sources and repositories |
| `Models/DayDataContainer.swift` | `struct DayDataContainer` | Top-level JSON envelope that holds the array of `DayData` values |
| `Migration/` | — | One-time upgrade logic; runs once per install, then marks itself done |
| `Migration/DataMigration.swift` | `enum DataMigration` | Migrates legacy `UserDefaults` records to iCloud Drive and upgrades workout-duration fields |
| `Services/` | — | Cross-cutting infrastructure used across the data layer |
| `Services/NotificationService.swift` | `class NotificationService` | Schedules and cancels local `UNUserNotification` alerts |
| `Services/NotificationPermissionManager.swift` | `class NotificationPermissionManager` | Requests and tracks `UNAuthorizationStatus` from the system |
| `Services/LoggerFactory.swift` | `enum LoggerFactory` | Creates pre-configured `Logger` instances scoped to a subsystem/category |
| `Services/OSLogLogger.swift` | `class OSLogLogger` | Bridges the domain `LoggerProtocol` to `os.Logger` |


## Storage

- All persistence goes through `LocalDataSourceProtocol`
- Default data source is `ICloudDriveDataSource` (iCloud Drive JSON file at `<ubiquityContainer>/Documents/HealthTrackerData.json`)
- Falls back to local `Documents/HealthTrackerData.json` when iCloud is unavailable
- Data is wrapped in `DayDataContainer` for encoding/decoding (shared model in `Data/Models/`)
- Uses `NSFileCoordinator` for safe concurrent file access
- Graceful error handling: returns empty arrays on decode failures
- Migration from UserDefaults runs once at app startup via `DataMigration.migrateIfNeeded()`

## Rules

Type-Driven Design Methodology (Use type system to encode business rules and guarantees):

<rule_1>
**DOMAIN BOUNDARIES & TYPE PLACEMENT**: Keep strongly-typed domain types in the domain, weakly-typed primitives at boundaries
- Domain logic lives with domain types (e.g., `Email`, `Password` in login domain)
- UI domain works with strings (for display purposes)
- Network/Data layer works with strings/JSON (for serialization)
- Parse at boundaries: convert strings → domain types when entering domain, domain types → strings when leaving
- Pushing weakly-typed types outside the domain achieves clean, robust domain code
- Domain code becomes unbreakable: even if boundary checks are commented out, domain invariants remain enforced by types
</rule_1>

<rule_2>
**COMPREHENSIVE ERROR HANDLING**: Make impossible states unrepresentable
- Use exhaustive enums with associated values
- Provide actionable recovery paths
- NEVER force unwrap in production
</rule_2>

<rule_3>
**PARSE, DON'T VALIDATE**: Use types to carry proof of validation
- Create validation-carrying types (e.g., `Email`, `Password`) instead of validating raw strings
- Types serve as vessels for validated data, carrying validation invariants within them
- Prefer parsing (transformation with retention) over validation (check with discard)
- Validation checks can be displaced; parsed types cannot be created without validation
- Eliminates systemic vulnerabilities from scattered validation logic
</rule_3>

<rule_4>
**UNIT TEST COVERAGE ≥ 80% FOR PERSISTENCE & DATA TRANSFORMATION**: Every non-trivial data-layer behaviour must be covered by a focused unit test
- Each `DataSource` must have tests for: happy-path load, happy-path save, missing-file/empty-store defaults, and at least one error path (corrupt data, permission denied, etc.)
- Each `Repository` must have tests for: `loadAllDays`, `save`, `dayData(for:)`, `saveDayData`, `loadDaysInRange`, and any edge cases (empty store, unknown date, overlapping ranges)
- Each `Migration` path (`migrateToICloudDrive`, `migrateWorkoutDurations`) must have tests covering: already-migrated guard (no-op), successful migration, and source-data-absent case
- Use **in-memory or fake implementations** of `LocalDataSourceProtocol` (never real `UserDefaults`/files) so tests are fast and parallel-safe
- Async persistence methods must be `await`-ed in `async` test functions; never use `XCTestExpectation` for new tests
</rule_4>
