# Data Layer

Adapts persistence and platform services to the domain: raw I/O, orchestration, DTOs, one-time migrations, and cross-cutting infrastructure.

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

- All persistence goes through `LocalDataSourceProtocol`; the default implementation is `ICloudDriveDataSource`.
- The file lives at `<ubiquityContainer>/Documents/HealthTrackerData.json`, falling back to local `Documents/HealthTrackerData.json` when iCloud is unavailable.
- `NSFileCoordinator` guards concurrent file access.
- Decode failures degrade to empty arrays rather than crashing.

## Rules

Type-Driven Design — encode business rules and guarantees in the type system.

<rule_1>
**DOMAIN BOUNDARIES & TYPE PLACEMENT** — strong domain types inside, weak primitives at the edges.
- The domain owns strongly-typed values (`DayData`, `Meal`, `Workout`, `Mood`); this layer speaks JSON strings/numbers for serialisation.
- Parse at the boundary: JSON → domain types on the way in, domain types → JSON on the way out.
- Domain invariants then hold by construction — they survive even if a boundary check is later removed.
</rule_1>

<rule_2>
**MAKE IMPOSSIBLE STATES UNREPRESENTABLE**
- Model outcomes with exhaustive enums carrying associated values; give each error an actionable recovery path.
- Never force-unwrap in production.
</rule_2>

<rule_3>
**PARSE, DON'T VALIDATE** — types carry proof of validation.
- Build validation-carrying types instead of re-checking raw values at each use.
- A parsed value cannot be constructed without satisfying its invariant, so validation can never be skipped or displaced.
</rule_3>

<rule_4>
**PERSISTENCE & TRANSFORMATION TESTS ≥ 80%** — every non-trivial data-layer behaviour earns a focused unit test.
- Each `DataSource`: happy-path load, happy-path save, missing-file/empty-store default, and ≥1 error path (corrupt data, permission denied).
- `HealthDataRepository`: `loadAllDays`, `save`, `dayData(for:)`, `saveDayData`, `loadDaysInRange`, plus edges (empty store, unknown date, overlapping ranges).
- Each migration (`migrateToICloudDrive`, `migrateWorkoutDurations`): already-migrated no-op, successful migration, source-absent.
- Back tests with in-memory fakes of `LocalDataSourceProtocol` — never real `UserDefaults`/files — so they stay fast and parallel-safe.
- `await` async persistence in `async` tests; no `XCTestExpectation`.
</rule_4>
