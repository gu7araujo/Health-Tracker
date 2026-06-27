# Agent Guide

This file provides guidance to AI agents when working with code in this repository.

## Project Overview

HealthTracker is a modern iOS 26.0 health tracking app built with SwiftUI and Swift 6. The app helps users monitor and analyze daily habits including meals, water intake, workouts, and mood with comprehensive charts, insights, and trend visualizations. It uses a Clean Architecture approach with clear separation between Domain, Data, and Presentation layers.

## Technology Stack

- **Language**: Swift 6
- **UI Framework**: SwiftUI with iOS 26+ Liquid Glass effects
- **Charts**: Swift Charts (native iOS 16+)
- **Target**: iOS 26.0+
- **Architecture**: Clean Architecture (Domain/Data/Presentation)
- **Persistence**: iCloud Drive (JSON file) with local Documents fallback; migrated from UserDefaults
- **State Management**: @Observable macro

## Architecture

The codebase follows Clean Architecture principles with three main layers separated by folders:

### Domain Layer (`HealthTracker/Domain/`)
- **Entities**: Core business models (`DayData`, `RecordedDayData`, `Meal`, `Workout`, `Mood`, `DayStatus`)
  - `DayData`: Aggregate root containing all health data for a single day (may be empty for UI purposes)
  - `RecordedDayData`: Parse-don't-validate wrapper that guarantees at least one health category has data. Failable init is the only construction path. Used throughout the persistence chain (data sources, repository, use cases). The ViewModel parses `DayData` to `RecordedDayData` before saving and converts back on load.
  - `DayStatus`: Enum representing day health status (`.noData`, `.incomplete`, `.poor`, `.moderate`, `.optimal`)
  - Implements business logic for health status computation:
    - 0 categories filled → `.noData` (no tracking data)
    - 1 category filled → `.incomplete` (insufficient data for evaluation)
    - 2+ categories filled → evaluated for `.optimal` (green) / `.moderate` (yellow) / `.poor` (red)
  - `AnalyticsPeriod`: Time period selection for analytics (thisWeek, last7Days, last30Days, etc.)
  - `AnalyticsData`: Container for all analytics metrics
  - `MealAnalytics`, `WaterAnalytics`, `WorkoutAnalytics`, `MoodAnalytics`, `OverallAnalytics`: Calculated statistics and chart data
- **Protocols**: Abstract interfaces (`HealthDataRepositoryProtocol`, `LocalDataSourceProtocol`)
- **Use Cases**: Business operations (`LoadDayDataUseCase`, `SaveDayDataUseCase`, `CalculateAnalyticsUseCase`)

### Data Layer (`HealthTracker/Data/`)
- **Repositories**: Concrete implementations of domain protocols
  - `HealthDataRepository`: Orchestrates data operations (defaults to `ICloudDriveDataSource`). Implements `loadDaysInRange(_ range: ClosedRange<Date>)` for filtered historical data retrieval
- **DataSources**: Platform-specific storage implementations
  - `ICloudDriveDataSource`: JSON file persistence via iCloud Drive (default). File visible at **Files app > iCloud Drive > HealthTracker > HealthTrackerData.json**. Falls back to local Documents directory when iCloud is unavailable. Uses `NSFileCoordinator` for safe reads/writes.
  - `UserDefaultsDataSource`: Legacy JSON-based persistence using UserDefaults (kept for migration and testing)
- **Models**: Shared data transfer objects
  - `DayDataContainer`: Codable wrapper for `[DayData]` array, used by both data sources
- **Migration**: One-time data migration logic
  - `DataMigration`: Handles one-time data migrations on app startup
    - `migrateToICloudDrive()`: Migrates existing UserDefaults data to iCloud Drive (runs once, controlled by `iCloudMigrationCompleted` flag)
    - `migrateWorkoutDurations()`: Migrates workout durations from enum raw values (0-6) to actual minutes (runs once, controlled by `workoutDurationMigrationCompleted` flag). Maps legacy values: 0→15min, 1→30min, 2→60min, 3→90min, 4→10min, 5→40min, 6→120min

### Presentation Layer (`HealthTracker/Presentation/`)
- **Views**: SwiftUI views with section-based composition
  - `MainView`: Daily tracking view with meals, water, workouts, mood sections
  - `AnalyticsView`: Analytics screen with charts and insights for all health metrics
  - `AddEditModal`: Shared modal for adding/editing meals and workouts
  - **Components**: Reusable UI components (`CardView`, `CalendarStrip`, `CardListView`, `PeriodSelector`)
  - **Charts**: Swift Charts-based visualizations (`WaterLineChart`, `OverallHealthRingChart`, `WorkoutsBarChart`, `MoodBarChart`, `MealsBarChart`)
- **ViewModels**: Observable view models using @Observable macro
  - `MainViewModel`: Manages all health tracking state and coordinates with use cases
  - `AnalyticsViewModel`: Manages analytics state, period selection, and data loading
  - Uses dependency injection with default convenience initializer
- **Navigation**: TabView with two tabs: "Hoje" (MainView) and "Gráficos" (AnalyticsView)

## Adding New Features
1. Start with Domain layer (entities, use cases)
2. Implement Data layer changes (repository, data source if needed)
3. Update Presentation layer (views, view model)
4. Use dependency injection for testability
5. For chart visualizations: Use Swift Charts framework (built-in iOS 16+), create reusable chart components, follow existing patterns in `Presentation/Views/Components/Charts/`
6. **ALWAYS run the test suite after implementation** to ensure no regressions
7. **Update/fix/create tests** as needed to maintain passing tests and 80%+ coverage

## Repo Map

| Path | Purpose |
|------|---------|
| `HealthTracker/HealthTrackerApp.swift` | App entry point; wires dependencies and bootstraps the app |
| `HealthTracker/Domain/Entities/` | Core business models: `DayData`, `Meal`, `Workout`, `Mood`, analytics types |
| `HealthTracker/Domain/Protocols/` | Abstract interfaces for repository, notifications, and logging |
| `HealthTracker/Domain/UseCases/` | Business operations: load/save data, calculate analytics, manage notifications |
| `HealthTracker/Data/DataSources/` | Storage drivers: `ICloudDriveDataSource` (default), `UserDefaultsDataSource` (legacy) |
| `HealthTracker/Data/Repositories/` | `HealthDataRepository` — orchestrates data sources behind the domain protocol |
| `HealthTracker/Data/Models/` | DTOs: `DayDataContainer` (Codable JSON wrapper) |
| `HealthTracker/Data/Migration/` | One-time migrations: UserDefaults → iCloud, workout duration format |
| `HealthTracker/Data/Services/` | Platform services: notifications (`NotificationService`), logging (`OSLogLogger`) |
| `HealthTracker/Presentation/ViewModels/` | `MainViewModel`, `AnalyticsViewModel` — state management via `@Observable` |
| `HealthTracker/Presentation/Views/` | `MainView` (daily tracking), `AnalyticsView` (charts & insights), `AddEditModal` |
| `HealthTracker/Presentation/Views/Components/` | Reusable UI: `CardView`, `CardListView`, `CalendarStrip`, `PeriodSelector` |
| `HealthTracker/Presentation/Views/Components/Charts/` | Swift Charts views: water, workouts, mood, meals, overall health ring |
| `HealthTracker/Extensions/` | SwiftUI `View` helpers |
| `HealthTracker/Resources/` | Localizable strings for `en` and `pt-BR` |
| `HealthTrackerTests/Domain/` | Unit tests for entities and use cases |
| `HealthTrackerTests/Data/` | Tests for repository, data sources, migration, and models |
| `HealthTrackerTests/Presentation/ViewModels/` | ViewModel unit tests |
| `HealthTrackerTests/Mocks/` | Protocol-backed test doubles |
| `HealthTrackerTests/TestHelpers/` | `TestDataBuilder` — factory for test fixtures |
| `HealthTracker.xcodeproj/` | Xcode project configuration |
| `docs/` | Project documentation |

## Build and Test

### Using Xcode MCP

The project has an Xcode MCP server (`user-xcode-tools`) configured. Prefer these tools over `xcodebuild` CLI commands when the user has Xcode open with the workspace — they provide structured results (errors with file/line, test pass/fail counts) without needing to parse CLI output.

**Getting the `tabIdentifier`**: All Xcode MCP tools require a `tabIdentifier`. Always call `XcodeListWindows` first to obtain it.

**Available tools**:

| Tool | Purpose |
|------|---------|
| `BuildProject` | Triggers a build using the active scheme in Xcode; returns structured errors |
| `GetBuildLog` | Retrieves the build log with optional filtering by severity, file glob, or message pattern |
| `XcodeListNavigatorIssues` | Lists current issues from Xcode's Issue Navigator (build errors, warnings, package resolution problems) |
| `GetTestList` | Discovers all available tests from the active scheme's test plan |
| `RunAllTests` | Runs all tests from the active scheme's test plan |
| `RunSomeTests` | Runs specific tests by `targetName` + `testIdentifier` (use `GetTestList` first to discover identifiers) |

**Typical workflows**:

- **Build and check errors**: `XcodeListWindows` → `BuildProject` → `GetBuildLog` (if errors)
- **Run specific tests**: `XcodeListWindows` → `GetTestList` (find identifiers) → `RunSomeTests`
- **Check existing issues**: `XcodeListWindows` → `XcodeListNavigatorIssues`

### Using CLI Commands

#### Building

Build the project
```bash
xcodebuild -project HealthTracker.xcodeproj -scheme HealthTracker -configuration Debug build | xcbeautify
```

Build for testing only (compiles tests without running them):
```bash
xcodebuild build-for-testing -project HealthTracker.xcodeproj -scheme HealthTracker | xcbeautify
```

#### Running Tests

Identify possible simulator ids
```bash
xcrun simctl list devices
```

Run all tests
```bash
xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,id=<simulator-id>' | xcbeautify
```

Run specific test file
```bash
xcodebuild test -scheme HealthTracker -only-testing:HealthTrackerTests/DayDataTests | xcbeautify
```

Run with coverage report
```bash
xcodebuild test -scheme HealthTracker -enableCodeCoverage YES -derivedDataPath ./DerivedData
```
View coverage report (after running with coverage)
Open: ./DerivedData/Logs/Test/*.xcresult in Xcode

## Code Quality

Lint Swift code and apply fixes for autocorrectable rules (run after editing)
```bash
swiftlint --fix && swiftlint
```

Format Swift code (run after editing)
```bash
swiftformat . --swift-version 6
```

## Nested AGENTS.md files

Each major directory contains its own `AGENTS.md` with layer-specific guidance. **Always load and follow the relevant sub-folder `AGENTS.md` when working in that area of the codebase.**

| Path | Purpose |
|------|---------|
| `HealthTracker/Domain/AGENTS.md` | Domain layer conventions: entities, protocols, use cases |
| `HealthTracker/Data/AGENTS.md` | Data layer conventions: repositories, data sources, migration |
| `HealthTracker/Presentation/AGENTS.md` | Presentation layer conventions: views, view models, components |
| `HealthTrackerTests/AGENTS.md` | Testing conventions, mocks, and test helpers |

### Self-Improvement Mindset

As you work on this project:
1. **Notice patterns** — If you make the same mistake twice, add guidance to prevent it.
2. **Question outdated advice** — If instructions don’t match reality, update them immediately.
3. **Clarify ambiguity** — If you find yourself confused by documentation, improve it for the next agent.
4. **Document decisions** — When you make architectural choices, explain the reasoning in these files.
5. **Keep it current** — These guides is a living document. Treat it as your shared memory across sessions.

## MCP Tools

Three MCP servers are available. Use them in preference to manual file reads or CLI commands where applicable.

### Serena

Serena provides semantic code intelligence — symbol-aware search, navigation, and editing. It is the **primary tool for reading and editing Swift source files**.

| Tool | When to use |
|------|-------------|
| `get_symbols_overview` | First call when exploring a new file — returns all symbols grouped by kind |
| `find_symbol` | Locate a class, method, or variable by name path (e.g. `MainViewModel/saveDay`) |
| `find_referencing_symbols` | Find all call sites of a symbol before renaming or changing its signature |
| `replace_symbol_body` | Replace an entire symbol definition (method, class, etc.) |
| `insert_after_symbol` / `insert_before_symbol` | Add new code at a precise location in a file |
| `rename_symbol` | Rename a symbol across the whole codebase |
| `search_for_pattern` | Regex search across files when symbol name is unknown |
| `list_dir` / `find_file` | Directory and file discovery |
| `write_memory` / `read_memory` | Persist and recall project knowledge across sessions |

**Workflow**: `get_symbols_overview` → `find_symbol` (with `include_body=true`) → edit. Avoid reading whole files unless strictly necessary.

### Xcode Bridge (`user-xcode-tools`)

Provides structured build and test feedback from a running Xcode instance. Prefer these over raw `xcodebuild` CLI because results include file/line-level errors and structured pass/fail counts.

**Always call `XcodeListWindows` first** to obtain the required `tabIdentifier`.

| Tool | When to use |
|------|-------------|
| `XcodeListWindows` | Obtain `tabIdentifier` before any other Xcode MCP call |
| `BuildProject` | Build the active scheme and receive structured error list |
| `GetBuildLog` | Retrieve full build log; supports filtering by severity, file glob, or message pattern |
| `XcodeListNavigatorIssues` | Inspect current build errors/warnings from the Issue Navigator |
| `GetTestList` | Discover all test identifiers from the active test plan |
| `RunAllTests` | Run the full test suite |
| `RunSomeTests` | Run a targeted subset by `targetName` + `testIdentifier` |

**Typical workflows**:
- Build and inspect errors: `XcodeListWindows` → `BuildProject` → `GetBuildLog`
- Run targeted tests: `XcodeListWindows` → `GetTestList` → `RunSomeTests`

### Context7

Context7 retrieves up-to-date documentation and code examples for any library or framework. Use it when you need authoritative API references (e.g. SwiftUI, Swift Charts, Swift Concurrency) rather than relying on potentially stale training data.

**Two-step usage**:

1. `resolve-library-id` — resolve the library name to a Context7 ID (e.g. `/apple/swift-charts`)
2. `query-docs` — fetch focused documentation with a specific question

Do not call either tool more than 3 times per question. Use the best result available after 3 calls.

---

## Available Skills (`.claude/skills/`)

Project-specific skills are installed under `.claude/skills/`. 

<usage>
When users ask you to perform tasks, check if any of the available skills below can help complete the task more effectively. Skills provide specialized capabilities and domain knowledge.

How to use skills: Invoke them via the `Skill` tool before responding to any task they cover.
</usage>

<available_skills>

<skill>
<name>swift-api-design-guidelines</name>
<description>Applies Apple's Swift API Design Guidelines when writing or reviewing Swift code. Use when writing Swift APIs, naming types and methods, designing Swift libraries, or when the user asks for Swift style, naming, or API design.</description>
<location>project</location>
</skill>

<skill>
<name>swift-concurrency</name>
<description>'Expert guidance on Swift Concurrency best practices, patterns, and implementation. Use when developers mention: (1) Swift Concurrency, async/await, actors, or tasks, (2) "use Swift Concurrency" or "modern concurrency patterns", (3) migrating to Swift 6, (4) data races or thread safety issues, (5) refactoring closures to async/await, (6) @MainActor, Sendable, or actor isolation, (7) concurrent code architecture or performance optimization, (8) concurrency-related linter warnings (SwiftLint or similar; e.g. async_without_await, Sendable/actor isolation/MainActor lint).'</description>
<location>project</location>
</skill>

<skill>
<name>swift-testing-expert</name>
<description>'Expert guidance for Swift Testing: test structure, #expect/#require macros, traits and tags, parameterized tests, test plans, parallel execution, async waiting patterns, and XCTest migration. Use when writing new Swift tests, modernizing XCTest suites, debugging flaky tests, or improving test quality and maintainability in Apple-platform or Swift server projects.'</description>
<location>project</location>
</skill>

<skill>
<name>swiftui-expert-skill</name>
<description>Write, review, or improve SwiftUI code following best practices for state management, view composition, performance, modern APIs, Swift concurrency, and iOS 26+ Liquid Glass adoption. Use when building new SwiftUI features, refactoring existing views, reviewing code quality, or adopting modern SwiftUI patterns.</description>
<location>project</location>
</skill>

</available_skills>

## General Rules

<rule_1>
**PROGRESSIVE ARCHITECTURE**: Start simple → Add complexity only when proven necessary
```swift
// Step 1: Direct implementation
// Step 2: Protocol when second implementation exists
// Step 3: Generic when pattern emerges
```
</rule_1>

<rule_2>
**TESTABLE BY DESIGN**: Inject all dependencies
- Design for testing from start
- Test behavior, not implementation
- Decouple from frameworks
</rule_2>

## QUALITY GATES

<checklist>
☐ NO force unwrapping (!, try!)
☐ ALL errors have recovery paths
☐ DEPENDENCIES injected via init
☐ PUBLIC APIs documented
☐ EDGE CASES handled (nil, empty, invalid)
☐ VALIDATION uses parsing (validation-carrying types) not boolean checks
☐ VALIDATED data flows through system as typed values, not raw strings
☐ DOMAIN BOUNDARIES: Domain uses domain types, boundaries parse strings ↔ domain types
☐ ROBUST DOMAIN: Domain code unbreakable even if boundary checks are removed
☐ ACCESS CONTROL: Preconditions use witnesses, not boolean checks
☐ OPERATION ORDER: Sequential operations enforced by witness types when critical
☐ NEW FEATURES have corresponding tests (maintain 80%+ coverage)
☐ **TESTS PASS**: Run full test suite after EVERY implementation - zero tolerance for failing tests
☐ **TESTS UPDATED**: Fix or update affected tests when changing behavior - never leave broken tests
☐ **NEW TESTS WRITTEN**: Create tests for new features and bug fixes - test-driven development preferred
</checklist>

## ANTI-PATTERNS TO AVOID

<avoid>
❌ God objects (500+ line ViewModels)
❌ Stringly-typed APIs
❌ Synchronous network calls
❌ Retained cycles in closures
❌ Force unwrapping optionals
❌ Scattered validation checks (validation that discards proof)
❌ Passing raw strings where validated types are needed
❌ Re-validating data that should already be validated (indicates missing type safety)
❌ Passing strings through domain layer (domain should use domain types)
❌ Domain types in UI/Network layers (boundaries should use primitives)
❌ Weakly-typed primitives in domain logic (domain should be strongly-typed)
❌ Boolean flags for access control (use witness types instead)
❌ Multiple entry points without compile-time access enforcement
❌ Forgeable proofs (witness init should be fileprivate)
❌ Relying on convention/discipline for access control (turn into compile-time requirement)
❌ Marking entire enums/structs with @MainActor when only specific methods need isolation (makes all static properties MainActor-isolated, preventing non-isolated access)
</avoid>
