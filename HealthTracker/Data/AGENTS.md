# Data Layer

Adapts persistence and platform services to the domain: raw I/O, orchestration, DTOs, one-time migrations, and cross-cutting infrastructure.

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
**PERSISTENCE & TRANSFORMATION TESTS** — every non-trivial data-layer behaviour earns a focused unit test.
- Each `DataSource`: happy-path load, happy-path save, missing-file/empty-store default, and ≥1 error path (corrupt data, permission denied).
- `HealthDataRepository`: `loadAllDays`, `save`, `dayData(for:)`, `saveDayData`, plus edges (empty store, unknown date).
- Each migration (`migrateToICloudDrive`, `migrateWorkoutDurations`): already-migrated no-op, successful migration, source-absent.
- Back tests with in-memory fakes of `LocalDataSourceProtocol` — never real `UserDefaults`/files — so they stay fast and parallel-safe.
- `await` async persistence in `async` tests; no `XCTestExpectation`.
</rule_4>
