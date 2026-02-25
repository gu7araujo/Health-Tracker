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

## Development Commands

### Building and Running
```bash
# Build the project
xcodebuild -project HealthTracker.xcodeproj -scheme HealthTracker -configuration Debug build
```

### Code Quality
```bash
# Lint Swift code and apply fixes for autocorrectable rules (run after editing)
swiftlint --fix && swiftlint

# Format Swift code (run after editing)
swiftformat . --swift-version 6
```

### Testing
```bash
# Identify possible simulator ids
xcrun simctl list devices

# Run all tests
xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,id=<simulator-id>'

# Run specific test file
xcodebuild test -scheme HealthTracker -only-testing:HealthTrackerTests/DayDataTests

# Run with coverage report
xcodebuild test -scheme HealthTracker -enableCodeCoverage YES -derivedDataPath ./DerivedData

# View coverage report (after running with coverage)
# Open: ./DerivedData/Logs/Test/*.xcresult in Xcode
```

## Architecture

The codebase follows Clean Architecture principles with three main layers:

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

## Key Patterns

### State Management
- Uses Swift's native `@Observable` macro (not `ObservableObject`)
- View models coordinate between UI and use cases
- State flows unidirectionally: View → ViewModel → Use Case → Repository → DataSource

### Dependency Injection
```swift
// MainViewModel provides both explicit and convenience initializers
init(loadUseCase: LoadDayDataUseCase, saveUseCase: SaveDayDataUseCase) // Testable
convenience init(repository: HealthDataRepositoryProtocol = HealthDataRepository()) // Production
```

### Data Flow
1. `MainView` holds `@State private var viewModel = MainViewModel()`
2. User interactions trigger ViewModel methods
3. ViewModel updates internal state and calls appropriate use case
4. Use case coordinates with repository
5. Repository delegates to data source for persistence
6. SwiftUI observes ViewModel changes and re-renders
7. Analytics tab loads → `AnalyticsViewModel` calls `CalculateAnalyticsUseCase`
8. Use case retrieves filtered days from repository (`loadDaysInRange`)
9. Use case calculates all analytics metrics and returns `AnalyticsData`
10. View renders charts using Swift Charts framework with computed data

### Custom View Extensions
- `View.if(_:transform:)`: Conditional view modifier
- `View.onFirstAppear(perform:)`: One-time initialization on first appearance
- Located in `Extensions/View+Extensions.swift`

### Implementation patterns

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

<rule_3>
```swift
// 1. DO NOT abstract on the first or second usage.
// 2. DUPLICATE code until the pattern is proven three times.
// 3. REFRACTOR only when the commonality is structural, not accidental.

// Initial usage: Keep it local
struct UserAvatar: View { ... }

// Second usage: Copy-paste if domains differ
struct EmployeeAvatar: View { ... }

// Third usage: Extract reusable component
struct CircleImage(url: URL): View { ... }
</rule_3>

#### Type-Driven Design Methodology (Use type system to encode business rules and guarantees)

<rule_4>
**COMPREHENSIVE ERROR HANDLING**: Make impossible states unrepresentable
- Use exhaustive enums with associated values
- Provide actionable recovery paths
- NEVER force unwrap in production
</rule_4>

<rule_5>
**PARSE, DON'T VALIDATE**: Use types to carry proof of validation
- Create validation-carrying types (e.g., `Email`, `Password`) instead of validating raw strings
- Types serve as vessels for validated data, carrying validation invariants within them
- Prefer parsing (transformation with retention) over validation (check with discard)
- Validation checks can be displaced; parsed types cannot be created without validation
- Eliminates systemic vulnerabilities from scattered validation logic
</rule_5>

<rule_6>
**DOMAIN BOUNDARIES & TYPE PLACEMENT**: Keep strongly-typed domain types in the domain, weakly-typed primitives at boundaries
- Domain logic lives with domain types (e.g., `Email`, `Password` in login domain)
- UI domain works with strings (for display purposes)
- Network/Data layer works with strings/JSON (for serialization)
- Parse at boundaries: convert strings → domain types when entering domain, domain types → strings when leaving
- Pushing weakly-typed types outside the domain achieves clean, robust domain code
- Domain code becomes unbreakable: even if boundary checks are commented out, domain invariants remain enforced by types
</rule_6>

<rule_7>
**WITNESS PATTERN FOR ACCESS CONTROL**: Turn conventions into compile-time requirements
- A **Witness** is a value that proves a precondition is met (e.g., feature enabled, user authenticated, data saved)
- Replace boolean flags with optional witness types (e.g., `isEnabled: Bool` → `enabled: FeatureEnabled?`)
- Use `fileprivate init()` to prevent forging witnesses outside their origin
- Require witnesses as non-optional arguments to enforce access control at compile time
- Code fails to compile if access control isn't enforced, catching mistakes early
- Use "black hole" arguments (`init(_: Witness)`) when witness is only proof, not data
</rule_7>

## Testing Architecture

The project uses **Swift Testing framework** (not XCTest) with comprehensive test coverage across all layers.

### Test Structure
```
HealthTrackerTests/
├── Domain/
│   ├── Entities/           # Entity tests (DayData, RecordedDayData, Meal, Workout, Mood, DayStatus, AnalyticsPeriod, analytics entities)
│   └── UseCases/          # Use case tests with mocked repositories (LoadDayDataUseCase, SaveDayDataUseCase, CalculateAnalyticsUseCase)
├── Data/
│   ├── Repositories/      # Repository tests with mocked data sources
│   ├── DataSources/       # Data source tests (UserDefaultsDataSource)
│   └── Models/            # Model tests (DayDataContainer)
├── Presentation/
│   └── ViewModels/        # ViewModel tests with mocked use cases (MainViewModel, AnalyticsViewModel)
├── Mocks/                 # Mock implementations of protocols
└── TestHelpers/           # Test data builders and utilities
```

### Testing Patterns

**Framework:** Swift Testing with `@Test` macro and `#expect()` assertions

**Mocking Strategy:**
- Protocol-based mocks for `HealthDataRepositoryProtocol` and `LocalDataSourceProtocol`
- In-memory UserDefaults for data source tests
- Test data builders for creating fixtures with sensible defaults

**Key Principles:**
- Use fixed dates (`TestDataBuilder.fixedDate`) for deterministic tests
- Test one behavior per test function
- Use descriptive test names: `statusIsOptimal_whenMeetsOptimalCriteria`
- Follow Arrange-Act-Assert pattern
- Keep tests fast (< 1 second each) with proper mocking
- All test functions are marked `@MainActor` due to `@Observable` macro isolation

**Actor Isolation in Test Helpers:**
- ⚠️ **Don't** mark entire test helper enums/structs with `@MainActor`
- ✅ **Do** mark only specific factory methods that create `@Observable` types with `@MainActor`
- ✅ **Keep** date constants and other non-isolated properties accessible from any context
- Example: In `TestDataBuilder`, only `makeDayData()`, `makeOptimalDay()`, etc. are `@MainActor`, not the enum itself

### Coverage Areas
- **Domain Layer:** 95%+ (core business logic)
- **Data Layer:** 80%+ (persistence and data transformation)
- **Presentation Layer:** 70%+ (ViewModels and state management)
- **Overall:** 80%+
- **Total Tests:** 211 tests across all layers

### Running Tests
See **Development Commands > Testing** section for test execution commands.

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

## Language and Localization

The app is currently in Portuguese (Brazil). All UI strings, entity property names (e.g., `Meal.Quantity.localizedName`), and user-facing text are in Portuguese.

## Working with the Codebase

### Adding New Features
1. Start with Domain layer (entities, use cases)
2. Implement Data layer changes (repository, data source if needed)
3. Update Presentation layer (views, view model)
4. Use dependency injection for testability
5. For chart visualizations: Use Swift Charts framework (built-in iOS 16+), create reusable chart components, follow existing patterns in `Presentation/Views/Components/Charts/`
6. **ALWAYS run the test suite after implementation** to ensure no regressions
7. **Update/fix/create tests** as needed to maintain passing tests and 80%+ coverage

### Modifying Views
- Follow existing section-based composition pattern in `MainView`
- Extract complex sections into private structs (see `MealsSectionView`, `WorkoutsSectionView`)
- Use `CardView` for consistent glass effect styling
- Leverage iOS 26+ Liquid Glass with `.glassEffect()` modifier

### Storage Changes
- All persistence goes through `LocalDataSourceProtocol`
- Default data source is `ICloudDriveDataSource` (iCloud Drive JSON file at `<ubiquityContainer>/Documents/HealthTrackerData.json`)
- Falls back to local `Documents/HealthTrackerData.json` when iCloud is unavailable
- Data is wrapped in `DayDataContainer` for encoding/decoding (shared model in `Data/Models/`)
- Uses `NSFileCoordinator` for safe concurrent file access
- Graceful error handling: returns empty arrays on decode failures
- Migration from UserDefaults runs once at app startup via `DataMigration.migrateIfNeeded()`

### Entity Modifications
- Entities are `Codable`, so changes may require migration logic
- `DayData` computes health status based on business rules (see `status`, `meetsOptimalCriteria`, `meetsModerateCriteria`, `meetsPoorCriteria`)
  - **Status thresholds**: 0 categories → `.noData`, 1 category → `.incomplete`, 2+ categories → evaluated for `.optimal`/`.moderate`/`.poor`
  - **Health Status Logic** (comprehensive evaluation of all 4 categories):
    - 🟢 **Optimal** (ALL must be true): Only verySmall/small meals OR ≤1 medium meal + Water ≥1.8L + Workouts ≥30 min total + Mood = good
    - 🟡 **Moderate** (ANY one of): Exactly 1 medium meal (when other criteria prevent optimal) OR Water 1.0-1.7L OR Workouts <30 min OR Mood = neutral
    - 🔴 **Poor** (ANY one of): 2+ medium meals OR any large meal OR Water <1.0L (or nil) OR Mood = sad (workouts don't affect poor status)
    - ⚪ **Incomplete**: Only 1 category filled
    - **Note**: Meal satiety is **completely ignored** - only meal size (verySmall/small/medium/large) affects status
    - **Workout duration**: `Workout.Duration` is a struct storing minutes as Int (1-300 range). Sums all workouts in a day (e.g., 2x 15min = 30min total). Supports free-form time input via DatePicker in AddEditModal with `Duration(minutes:)` constructor.
- Nested enums have localized names (e.g., `Meal.Quantity.localizedName`)

### Writing Tests

**⚠️ CRITICAL: Always run tests after implementation!** Every code change MUST be followed by running the full test suite to ensure:
- All existing tests still pass (no regressions)
- New/modified behavior has corresponding tests
- Test failures are fixed immediately, never left broken

**Test Writing Guidelines:**
- All tests use Swift Testing framework (`import Testing`, `@Test` macro)
- Use `@testable import HealthTracker` to access internal types
- Mark all test functions with `@Test @MainActor` due to `@Observable` macro isolation
- Leverage existing mocks in `HealthTrackerTests/Mocks/`
- Use `TestDataBuilder` for creating test fixtures
- Follow existing test organization by layer (Domain/Data/Presentation)
- Ensure new features have corresponding tests (maintain 80%+ coverage)
- When changing behavior: update affected tests to reflect new expectations
- When fixing bugs: add regression tests to prevent reoccurrence

## Updating This Guide (AGENTS.md)

**As an AI agent, you are RESPONSIBLE for keeping this documentation accurate and improving it based on experience.** When you make changes that affect how the project is structured, documented, or used, **update AGENTS.md** so it stays accurate for future agents and developers.

### When to Update AGENTS.md

Update this file when you:

- **Add or remove layers, modules, or major types** — Update **Project Overview** and **Architecture** (Domain/Data/Presentation) so the listed entities, protocols, use cases, repositories, views, view models, and components reflect the codebase.
- **Change technology or tooling** — Update **Technology Stack** and **Development Commands** (e.g., new Swift version, new persistence, new lint/format commands).
- **Introduce or change patterns** — Update **Key Patterns** (state management, DI, data flow, view extensions) and **Implementation patterns** / rules if you add or change conventions.
- **Add or change quality or style rules** — Update **QUALITY GATES**, **ANTI-PATTERNS TO AVOID**, or add/remove rules in the implementation patterns section.
- **Add or remove agent skills** — Update **Agent Skills - Available Skills** (the skills table) so the listed skills match what’s available in the project.
- **Change localization or language** — Update **Language and Localization**.
- **Change how features are added or where things live** — Update **Working with the Codebase** (Adding New Features, Modifying Views, Storage Changes, Entity Modifications) so the steps and file/layer references are correct.
- **Follow instructions that are now obsolete** — Remove or update guidance that no longer applies (e.g., migration steps that have been completed, deprecated patterns, outdated tool versions).
- **Discover repetitive mistakes or common pitfalls** — Add warnings, anti-patterns, or best practices to prevent future agents from repeating the same errors.
- **Find instructions that could be clearer or more specific** — Improve wording, add examples, or break down complex instructions into actionable steps.
- **Complete major milestones** — Update completion status (e.g., "test coverage now at 80%+", "migration completed", "feature X implemented").

### How to Update

- Edit the **existing section** that matches the change (see list above). Do not duplicate sections.
- Keep the same structure and formatting (headers, lists, code blocks, checklist/avoid blocks).
- Be concise: add or adjust only what’s needed to reflect the current project; remove or reword anything that’s no longer true.
- **When removing obsolete instructions:** Explicitly state completion status if relevant (e.g., change "TODO: Add tests" to "✅ 166 tests implemented with 80%+ coverage").
- **When adding warnings about mistakes:** Be specific about what went wrong and how to avoid it (e.g., "❌ Don’t mark entire enums with @MainActor; only mark methods that create MainActor-isolated types").
- **When improving clarity:** Add concrete examples, file paths, or code snippets to make instructions actionable.

If a change doesn’t clearly fit any section, add a short note in the most relevant place or in **Important Notes**, and consider whether a new subsection is justified.

### Self-Improvement Mindset

As you work on this project:
1. **Notice patterns** — If you make the same mistake twice, add guidance to prevent it.
2. **Question outdated advice** — If instructions don’t match reality, update them immediately.
3. **Clarify ambiguity** — If you find yourself confused by documentation, improve it for the next agent.
4. **Document decisions** — When you make architectural choices, explain the reasoning in this file.
5. **Keep it current** — This guide is a living document. Treat it as your shared memory across sessions.

## Agent Skills - Available Skills

When working on specific tasks, use these specialized skills:

<skills_system priority="1">

## Available Skills

<!-- SKILLS_TABLE_START -->
<usage>
When users ask you to perform tasks, check if any of the available skills below can help complete the task more effectively. Skills provide specialized capabilities and domain knowledge.

How to use skills:
- Invoke: Bash("openskills read <skill-name>")
- The skill content will load with detailed instructions on how to complete the task
- Base directory provided in output for resolving bundled resources (references/, scripts/, assets/)

Usage notes:
- Only use skills listed in <available_skills> below
- Do not invoke a skill that is already loaded in your context
- Each skill invocation is stateless
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
<!-- SKILLS_TABLE_END -->

</skills_system>

Invoke skills using the Skill tool when relevant to the task at hand.

## Important Notes

- This is a Swift 6 project with strict concurrency checking
- Always use SwiftUI's modern `@Observable` macro, not the older `ObservableObject` protocol
- Maintain Clean Architecture boundaries: Domain should not depend on Data or Presentation
- When unsure or need to make a significant decision ASK the user for guidance
- The app has no network layer or external API calls currently
- Comprehensive unit test suite with 80%+ coverage using Swift Testing framework
- Run tests regularly to ensure code quality and prevent regressions
- For external knowledge consult the `context7` tool for most up-to-date software package documentation
- For internal knowledge consult the `serena` tool before editing code to verify existing function signatures, find references, or map project dependencies
- Prefer serena's symbol-based reading over full-file reading for large files to maintain a lean context window and efficiency
- Use the agent skills to perform activities
