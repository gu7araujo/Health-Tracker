# Testing Architecture

The project uses **Swift Testing framework** (not XCTest) with comprehensive test coverage across all layers.

## Directory Structure

| Path | Purpose |
|------|---------|
| `HealthTrackerTests/Domain/Entities/` | Entity tests (`DayData`, `RecordedDayData`, `Meal`, `Workout`, `Mood`, `DayStatus`, `AnalyticsPeriod`, analytics entities) |
| `HealthTrackerTests/Domain/UseCases/` | Use case tests with mocked repositories (`LoadDayDataUseCase`, `SaveDayDataUseCase`, `CalculateAnalyticsUseCase`) |
| `HealthTrackerTests/Data/Repositories/` | Repository tests with mocked data sources |
| `HealthTrackerTests/Data/DataSources/` | Data source tests (`UserDefaultsDataSource`) |
| `HealthTrackerTests/Data/Models/` | Model tests (`DayDataContainer`) |
| `HealthTrackerTests/Presentation/ViewModels/` | ViewModel tests with mocked use cases (`MainViewModel`, `AnalyticsViewModel`) |
| `HealthTrackerTests/Mocks/` | Mock implementations of protocols |
| `HealthTrackerTests/TestHelpers/` | Test data builders and utilities |

## Coverage Areas
- **Domain Layer:** 95%+ (core business logic)
- **Data Layer:** 80%+ (persistence and data transformation)
- **Presentation Layer:** 70%+ (ViewModels and state management)
- **Overall:** 80%+
- **Total Tests:** 246 tests across all layers

## Writing Tests

**⚠️ CRITICAL: Always run tests after implementation!** Every code change MUST be followed by running the full test suite to ensure:
- All existing tests still pass (no regressions)
- New/modified behavior has corresponding tests
- Test failures are fixed immediately, never left broken

**Test Writing Guidelines:**
- All tests use Swift Testing framework (`import Testing`, `@Test` macro, and `#expect()` assertions)
- Use `@testable import HealthTracker` to access internal types
- Mark all test functions with `@Test @MainActor` due to `@Observable` macro isolation
- Leverage existing mocks in `HealthTrackerTests/Mocks/`
- Use `TestDataBuilder` for creating test fixtures
- Follow existing test organization by layer (Domain/Data/Presentation)
- Ensure new features have corresponding tests (maintain 80%+ coverage)
- When changing behavior: update affected tests to reflect new expectations
- When fixing bugs: add regression tests to prevent reoccurrence

**Key Principles:**
- Use fixed dates (`TestDataBuilder.fixedDate`) for deterministic tests
- Test one behavior per test function
- Use descriptive test names: `statusIsOptimal_whenMeetsOptimalCriteria`
- Follow Arrange-Act-Assert pattern
- Keep tests fast (< 1 second each) with proper mocking
- All test functions are marked `@MainActor` due to `@Observable` macro isolation

**Mocking Strategy:**
- Protocol-based mocks for `HealthDataRepositoryProtocol` and `LocalDataSourceProtocol`
- In-memory UserDefaults for data source tests
- Test data builders for creating fixtures with sensible defaults

**Actor Isolation in Test Helpers:**
- ⚠️ **Don't** mark entire test helper enums/structs with `@MainActor`
- ✅ **Do** mark only specific factory methods that create `@Observable` types with `@MainActor`
- ✅ **Keep** date constants and other non-isolated properties accessible from any context
- Example: In `TestDataBuilder`, only `makeDayData()`, `makeOptimalDay()`, etc. are `@MainActor`, not the enum itself

**Localization in Tests:**
- Always verify localization keys are used (not specific translated strings) to keep tests locale-independent
- Use `NSLocalizedString(key, comment: "")` as the expected value, never hardcoded translated strings

```swift
// ✅ Correct — locale-independent
@Test(arguments: [(Mood.good, "mood_good"), (.neutral, "mood_neutral")])
func localizedName_mappings(mood: Mood, localizationKey: String) {
    let expected = NSLocalizedString(localizationKey, comment: "")
    #expect(mood.localizedName == expected)
}

// ❌ Wrong — breaks under non-PT-BR locale
@Test(arguments: [(Mood.good, "Bom"), (.neutral, "Neutro")])
func localizedName_mappings(mood: Mood, expectedName: String) {
    #expect(mood.localizedName == expectedName)
}
```

## Running Tests

### Using Xcode MCP (preferred)

Use `RunAllTests` or `RunSomeTests` via the Xcode MCP server when Xcode is open. Always call `XcodeListWindows` first to get the `tabIdentifier`. See the **Xcode Bridge** section in the root `AGENTS.md` for the full tool reference.

### Using CLI

Use CLI commands if Xcode MCP doesn't work. See the **Using CLI Commands** section in the root `AGENTS.md` for the full reference.

## Available Skills

Use the following skills when writing or reviewing test code. See the **Available Skills** section in the root `AGENTS.md` for the full skill list and descriptions.

| Skill | When to use |
|-------|-------------|
| `swift-testing-expert` | Writing new tests, structuring test suites, using `#expect`/`#require` macros, parameterized tests, async waiting patterns, or debugging flaky tests |
| `swift-concurrency` | Writing async tests, handling `@MainActor` isolation, or dealing with actor-isolated types in tests |
| `swift-api-design-guidelines` | Naming test types, helper methods, or mock types to align with Swift API conventions |

Invoke skills via the `Skill` tool **before** responding to any task they cover.
