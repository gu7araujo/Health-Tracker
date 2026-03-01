# Testing Patterns

**Analysis Date:** 2026-03-01

## Test Framework

**Runner:**
- Swift Testing (native Swift testing framework)
- No config file (uses Xcode project configuration)

**Assertion Library:**
- `#expect` macro (Swift Testing)
- `#require` for unwrapping with early exit

**Run Commands:**
```bash
# From Xcode
Product → Test (Cmd+U)

# From command line
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

## Swift Testing Fundamentals

**Building Blocks:**
- Import `Testing` only in test targets (never in app targets)
- Use `@Test` to declare tests explicitly (global function or type method)
- Use suites (`struct`, `actor`, or `class`) to group related tests
- Prefer `struct` suites for value semantics and prevent accidental state sharing
- Use `@Suite` when adding suite-level traits or display names
- Use nested suites to reflect feature grouping and improve discoverability

**Key Principles:**
- Each test has a single clear behavior
- Use descriptive names or display names for readable output
- Keep setup local or centralize in suite init when shared
- Avoid hidden global mutable state
- Use `@MainActor` only when code under test requires main-thread isolation
- Use `@available` on test functions for platform gating (never on suite types)

## Test File Organization

**Location:**
- Separate test target: `HealthTrackerTests/`
- Mirrors source structure:
  - `HealthTrackerTests/Domain/Entities/` mirrors `HealthTracker/Domain/Entities/`
  - `HealthTrackerTests/Domain/UseCases/` mirrors `HealthTracker/Domain/UseCases/`
  - `HealthTrackerTests/Data/` mirrors `HealthTracker/Data/`
  - `HealthTrackerTests/Presentation/` mirrors `HealthTracker/Presentation/`

**Naming:**
- Source file: `Meal.swift` → Test file: `MealTests.swift`
- Source file: `MainViewModel.swift` → Test file: `MainViewModelTests.swift`
- Pattern: `{SourceName}Tests.swift`

**Structure:**
```
HealthTrackerTests/
├── TestHelpers/
│   └── TestDataBuilder.swift        # Test fixtures and factories
├── Mocks/
│   ├── MockHealthDataRepository.swift
│   └── MockLocalDataSource.swift
├── Domain/
│   ├── Entities/
│   │   ├── MealTests.swift
│   │   ├── WorkoutTests.swift
│   │   └── DayStatusTests.swift
│   └── UseCases/
│       ├── LoadDayDataUseCaseTests.swift
│       └── SaveDayDataUseCaseTests.swift
├── Data/
│   ├── DataSources/
│   │   └── UserDefaultsDataSourceTests.swift
│   ├── Repositories/
│   │   └── HealthDataRepositoryTests.swift
│   └── Models/
│       └── DayDataContainerTests.swift
└── Presentation/
    └── ViewModels/
        └── MainViewModelTests.swift
```

## Test Structure

**Suite Organization:**
```swift
@MainActor
struct MealTests {
    // MARK: - Quantity Enum Tests

    @Test func quantity_allCases_areAccessible() {
        let cases = Meal.Quantity.allCases

        #expect(cases.count == 4)
        #expect(cases.contains(.verySmall))
    }

    @Test(arguments: [
        (Meal.Quantity.verySmall, "Muito pequena"),
        (.small, "Pequena")
    ])
    func quantity_localizedNames(quantity: Meal.Quantity, expectedName: String) {
        #expect(quantity.localizedName == expectedName)
    }

    // MARK: - Satisfaction Enum Tests
    // MARK: - Meal Initialization Tests
    // MARK: - Codable Tests
    // MARK: - Equatable Tests
}
```

**Patterns:**
- Use `struct` for test suites (Swift Testing convention)
- `@MainActor` annotation when testing types that require main thread
- MARK comments organize test sections by feature area
- Test function names format: `{feature}_{scenario}_{expectedResult}`
- Use `@Test` attribute (no `func test` prefix needed)
- Parameterized tests with `@Test(arguments:)` for exhaustive case coverage

**Test Naming Convention:**
- Format: `{subject}_{condition}_{expectedOutcome}`
- Examples:
  - `quantity_allCases_areAccessible`
  - `initialization_withDefaults`
  - `codable_roundTrip_preservesAllData`
  - `equatable_sameValues_areEqual`
  - `updateWater_updatesCurrentDay`
  - `meal_withId_returnsNil_whenNotFound`

## Expectations and Assertions

**`#expect` as the Default:**
- Use `#expect` for most assertions
- Pass natural Swift expressions (`==`, `>`, `.contains`, `.isEmpty`, etc.)
- Rely on captured sub-expression values for rich diagnostics in Xcode
- Avoid old XCTest assertion families in Swift Testing tests

**Example: Expressive Assertions**
```swift
@Test func pricingRules() {
    let subtotal = 25
    let discount = 5
    let total = subtotal - discount

    #expect(total == 20)
    #expect(total > 0)
    #expect([10, 20, 30].contains(total))
}
```

**`#require` for Prerequisites:**
- Use `try #require(...)` when later assertions depend on this condition
- Treat `#require` as "guard + fail test early"
- Use return value to unwrap optionals safely and reduce noisy optional chaining
- Prefer this pattern over manual optional checks when failure should halt test flow

**Example: Optional Precondition + Unwrapped Usage**
```swift
@Test func parsedURLHasHTTPS() throws {
    let value = "https://www.avanderlee.com"
    let url = try #require(URL(string: value), "URL should parse")
    #expect(url.scheme == "https")
}

@Test func loadData_loadsFromRepository() throws {
    let (viewModel, mockRepository) = createViewModel()
    let day1 = try #require(TestDataBuilder.makeRecordedOptimalDay(date: TestDataBuilder.fixedDate))

    mockRepository.loadAllDaysResult = [day1]
    viewModel.loadData()

    #expect(viewModel.days.count == 1)
}
```

**Throwing Behavior Checks:**
- For success-path calls to throwing functions, call directly and assert returned value
- For expected failure, use throw-aware expectations to verify:
  - any throw
  - specific error type
  - specific error case/value
- Avoid verbose hand-written `do/catch` unless custom branching is truly needed

**Example: Expected Throw and No-Throw**
```swift
enum BrewError: Error, Equatable {
    case missingBeans
}

func brew(_ hasBeans: Bool) throws -> String {
    guard hasBeans else { throw BrewError.missingBeans }
    return "coffee"
}

@Test func expectedThrows() {
    #expect(throws: BrewError.self) {
        try brew(false)
    }
}

@Test func expectedNoThrow() {
    #expect(throws: Never.self) {
        try brew(true)
    }
}
```

**Known Issue Handling:**
- Use `withKnownIssue` for temporary expected failures you still want to compile/run
- Prefer `withKnownIssue` over blanket disabling when you need ongoing visibility
- Remove known-issue wrappers once failure condition is fixed

```swift
@Test func checkoutFlow() {
    #expect(true) // still validated

    withKnownIssue("Checkout backend intermittently returns 503", isIntermittent: true) {
        Issue.record("Known upstream issue")
    }
}
```

## Parameterized Testing

**When to Use:**
- Replace repetitive test methods that differ only in input values
- Test exhaustive case coverage with clear input/output pairs
- Reduce code duplication while maintaining test clarity

**Example from Codebase:**
```swift
@Test(arguments: [
    (DayStatus.optimal, Color?.some(.green)),
    (.moderate, .some(.yellow)),
    (.poor, .some(.red)),
    (.incomplete, .some(.primary)),
    (.noData, nil)
])
func color_mappings(status: DayStatus, expectedColor: Color?) {
    #expect(status.color == expectedColor)
}

@Test(arguments: [
    (Meal.Quantity.verySmall, "Muito pequena"),
    (.small, "Pequena"),
    (.medium, "Média"),
    (.large, "Grande")
])
func quantity_localizedNames(quantity: Meal.Quantity, expectedName: String) {
    #expect(quantity.localizedName == expectedName)
}
```

**Benefits:**
- Reduces test code duplication
- Makes test coverage explicit
- Easy to add new test cases
- Clear failure messages show which input failed

## Mocking

**Framework:** Manual mocks (no mocking library)

**Patterns:**
```swift
final class MockHealthDataRepository: HealthDataRepositoryProtocol {
    // MARK: - Stored Results
    var loadAllDaysResult: [RecordedDayData] = []
    var dayDataForDateResult: [Date: RecordedDayData] = [:]

    // MARK: - Call Tracking
    var saveCalledWithDays: [RecordedDayData]?
    var loadAllDaysCalled = false

    // MARK: - Protocol Implementation
    func loadAllDays() -> [RecordedDayData] {
        loadAllDaysCalled = true
        return loadAllDaysResult
    }

    func save(days: [RecordedDayData]) {
        saveCalledWithDays = days
    }
}
```

**Mock Structure:**
- Store configurable return values: `var loadAllDaysResult: [RecordedDayData] = []`
- Track method calls: `var saveCalledWithDays: [RecordedDayData]?`
- Implement protocol methods to return stored values
- Located in `HealthTrackerTests/Mocks/` directory

**What to Mock:**
- Data sources: `MockLocalDataSource.swift`
- Repositories: `MockHealthDataRepository.swift`
- Any protocol-based dependencies
- External services: notification services, network clients

**What NOT to Mock:**
- Domain entities (use real instances)
- Value types (structs)
- View models (test with mocked dependencies)

## Fixtures and Factories

**Test Data:**
```swift
enum TestDataBuilder {
    // MARK: - Fixed Dates

    /// Fixed date for deterministic testing: Feb 19, 2024 12:00 PM UTC
    static let fixedDate = Date(timeIntervalSince1970: 1_708_387_200)

    /// Fixed date for testing date comparisons: Feb 20, 2024 12:00 PM UTC
    static let fixedDatePlusOne = Date(timeIntervalSince1970: 1_708_473_600)

    // MARK: - DayData Builders

    /// Creates a `DayData` with specified properties.
    @MainActor
    static func makeDayData(
        date: Date = fixedDate,
        meals: [Meal] = [],
        workouts: [Workout] = [],
        water: Double? = nil,
        mood: Mood? = nil
    ) -> DayData {
        DayData(date: date, meals: meals, workouts: workouts, water: water, mood: mood)
    }

    /// Creates an optimal day (should result in `.optimal` status).
    @MainActor
    static func makeOptimalDay(date: Date = fixedDate) -> DayData {
        makeDayData(
            date: date,
            meals: [
                Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty),
                Meal(description: "Lunch", quantity: .medium, satisfaction: .fifty)
            ],
            workouts: [Workout(description: "Morning run", duration: Workout.Duration(minutes: 30))],
            water: 2.0,
            mood: .good
        )
    }

    @MainActor
    static func makeModerateDay(date: Date = fixedDate) -> DayData { /* ... */ }

    @MainActor
    static func makePoorDay(date: Date = fixedDate) -> DayData { /* ... */ }
}
```

**Location:**
- `HealthTrackerTests/TestHelpers/TestDataBuilder.swift`

**Patterns:**
- Enum with static factory methods (no instantiation needed)
- Fixed dates for deterministic testing
- Builder methods with default parameters
- Semantic factory methods: `makeOptimalDay()`, `makeModerateDay()`, `makePoorDay()`
- `@MainActor` annotation only on methods that create `@MainActor`-isolated types
- Non-isolated constants (dates) accessible from any context

**Usage in Tests:**
```swift
@Test func dayData_status_optimal_hasGreenColor() {
    let dayData = TestDataBuilder.makeOptimalDay()
    #expect(dayData.status.color == .green)
}
```

## Parallelization and Isolation

**Default Behavior:**
- Swift Testing runs tests in parallel by default for performance
- Tests must be parallel-safe (no shared mutable state)

**When Tests Share State:**
- First, fix shared state to make tests isolated
- Use `.serialized` trait only as a transition step
- Prefer isolated dependencies (in-memory repositories, per-test state)

**Actor Isolation:**
- Mark test functions with `@MainActor` when code under test requires main-thread isolation
- Don't mark entire suite types with `@MainActor`
- Keep tests as non-isolated as possible for parallel execution

**Example:**
```swift
@MainActor
struct MainViewModelTests {
    @Test func loadData_loadsFromRepository() throws {
        // Test requires @MainActor because MainViewModel is @MainActor-isolated
        let (viewModel, mockRepository) = createViewModel()
        // ...
    }
}
```

## Coverage

**Requirements:** 80%+ coverage target (not enforced by tooling, but maintained through practice)

**View Coverage:**
- Coverage available through Xcode's built-in code coverage tool
- Enable in scheme settings: Edit Scheme → Test → Options → Code Coverage

**Command:**
```bash
# Generate coverage report via command line
xcodebuild test -scheme HealthTracker -enableCodeCoverage YES -derivedDataPath ./DerivedData

# View: ./DerivedData/Logs/Test/*.xcresult in Xcode
# Or: Report Navigator → Coverage tab in Xcode
```

**Current Coverage:**
- **Domain Layer:** 95%+ (core business logic)
- **Data Layer:** 80%+ (persistence and data transformation)
- **Presentation Layer:** 70%+ (ViewModels and state management)
- **Overall:** 80%+
- **Total Tests:** 211 tests across all layers

## Test Types

**Unit Tests:**
- Scope: Individual functions, methods, and computed properties
- Approach: Test in isolation with mocked dependencies
- Examples:
  - Entity tests: `MealTests.swift`, `WorkoutTests.swift`, `DayStatusTests.swift`
  - Use case tests: `LoadDayDataUseCaseTests.swift`, `SaveDayDataUseCaseTests.swift`
  - ViewModel tests: `MainViewModelTests.swift`
  - Repository tests: `HealthDataRepositoryTests.swift`

**Integration Tests:**
- Scope: Multiple components working together
- Approach: Test with real implementations where feasible
- Examples:
  - Repository + DataSource: `HealthDataRepositoryTests.swift`
  - ViewModel + Use Cases: `MainViewModelTests.swift`

**E2E Tests:**
- Framework: Not implemented
- UI testing not detected in current test suite

## Common Patterns

**Async Testing:**
- Not extensively used (most operations are synchronous)
- Swift Testing supports async with `async` test functions when needed
- Use `.task` for automatic cancellation in async tests

**Parameterized Testing:**
```swift
@Test(arguments: [
    (DayStatus.optimal, Color?.some(.green)),
    (.moderate, .some(.yellow)),
    (.poor, .some(.red)),
    (.incomplete, .some(.primary)),
    (.noData, nil)
])
func color_mappings(status: DayStatus, expectedColor: Color?) {
    #expect(status.color == expectedColor)
}
```

**Error Testing:**
```swift
@Test func codable_roundTrip_preservesAllData() throws {
    let original = Meal(description: "Dinner", quantity: .medium, satisfaction: .eighty)

    let encoded = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(Meal.self, from: encoded)

    #expect(decoded.id == original.id)
    #expect(decoded.description == original.description)
}
```

**Optional Unwrapping:**
```swift
@Test func loadData_loadsFromRepository() throws {
    let (viewModel, mockRepository) = createViewModel()
    let day1 = try #require(TestDataBuilder.makeRecordedOptimalDay(date: TestDataBuilder.fixedDate))

    mockRepository.loadAllDaysResult = [day1]
    viewModel.loadData()

    #expect(viewModel.days.count == 1)
}
```

**Test Helper Functions:**
```swift
private func createViewModel() -> (
    viewModel: MainViewModel,
    mockRepository: MockHealthDataRepository
) {
    let mockRepository = MockHealthDataRepository()
    let loadUseCase = LoadDayDataUseCase(repository: mockRepository)
    let saveUseCase = SaveDayDataUseCase(repository: mockRepository)
    let viewModel = MainViewModel(loadUseCase: loadUseCase, saveUseCase: saveUseCase)
    return (viewModel, mockRepository)
}
```

**Setup/Teardown:**
- Not commonly used (Swift Testing uses function-scoped setup)
- Helper functions create fresh instances per test
- No `setUp()` or `tearDown()` methods (XCTest pattern not used)
- Suite initializers can provide shared setup when needed

## Assertion Patterns

**Swift Testing Macros:**
```swift
// Equality
#expect(value == expected)

// Inequality
#expect(value != other)

// Boolean conditions
#expect(collection.isEmpty == true)
#expect(condition)

// Optional unwrapping with early exit
let unwrapped = try #require(optional)

// Collection assertions
#expect(array.count == 3)
#expect(cases.contains(.verySmall))

// Throwing expectations
#expect(throws: ErrorType.self) {
    try throwingFunction()
}

// No-throw expectations
#expect(throws: Never.self) {
    try safeFunction()
}
```

**Comparison with XCTest:**
- No `XCTAssertEqual` (use `#expect(a == b)`)
- No `XCTAssertTrue` (use `#expect(condition)`)
- No `XCTAssertNil` (use `#expect(value == nil)`)
- No `XCTUnwrap` (use `try #require(optional)`)

## Test Organization Best Practices

**MARK Comments:**
```swift
// MARK: - Quantity Enum Tests
// MARK: - Satisfaction Enum Tests
// MARK: - Meal Initialization Tests
// MARK: - Codable Tests
// MARK: - Equatable Tests
// MARK: - Test Helpers
```

**Grouping:**
- Group related tests under MARK sections
- Order sections logically: setup, initialization, operations, edge cases
- Keep helper functions at top or bottom of test struct
- Use nested suites for feature grouping

**Test Independence:**
- Each test creates its own instances
- No shared mutable state between tests
- Use helper functions to create fresh test subjects
- Default parallel execution requires isolation

**Arrange-Act-Assert:**
```swift
@Test func addMeal_addsToCurrentDay() {
    // Arrange
    let (viewModel, mockRepository) = createViewModel()
    mockRepository.loadAllDaysResult = []
    viewModel.loadData()
    viewModel.selectedDate = TestDataBuilder.fixedDate

    // Act
    let meal = Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty)
    viewModel.addMeal(meal)

    // Assert
    #expect(viewModel.currentDayData?.meals.count == 1)
    #expect(viewModel.currentDayData?.meals.first?.description == "Breakfast")
    #expect(mockRepository.saveCalledWithDays != nil)
}
```

## Traits and Tags

**Traits:**
- Use traits for behavior and metadata
- `.enabled`/`.disabled` for conditional test execution
- `.timeLimit` for performance requirements
- `.bug` for tracking known issues
- `.serialized` for sequential execution (use sparingly)

**Tags:**
- Use tags for cross-cutting grouping across files/targets
- Filter tests by tag in Xcode test plans
- Promote shared traits to suite level when all tests inherit them

## Migration from XCTest

**Incremental Migration Strategy:**
1. Convert assertions first (`XCTAssertEqual` → `#expect`)
2. Organize suites (class → struct, remove `test` prefix)
3. Introduce parameterization and traits
4. Keep XCTest for UI automation and performance metrics

**XCTest Patterns to Swift Testing:**
- `class` → `struct` (prefer value semantics)
- `func testFeature()` → `@Test func feature()`
- `XCTAssertEqual(a, b)` → `#expect(a == b)`
- `XCTUnwrap(optional)` → `try #require(optional)`
- `XCTAssertThrows` → `#expect(throws: ErrorType.self)`

## Performance and Best Practices

**Test Speed:**
- Keep tests fast (< 1 second each) with proper mocking
- Avoid real network calls or file I/O when possible
- Use in-memory storage for data source tests

**Determinism:**
- Use fixed dates for time-dependent tests
- Avoid randomness unless testing random behavior
- Ensure consistent test execution order independence

**Flakiness Prevention:**
- Eliminate shared mutable state
- Make tests parallel-safe by design
- Use proper async waiting patterns
- Avoid timing-dependent assertions

**Test Quality:**
- One behavior per test
- Clear test names that describe what's being tested
- Minimal setup code (use helper functions)
- Descriptive assertion messages when helpful

## Review Checklist

**Test Structure:**
- [ ] Test target imports `Testing`, app targets do not
- [ ] Suite choice (`struct`/`actor`/`class`) matches setup needs
- [ ] Instance tests have callable zero-argument init path
- [ ] Availability applied to test functions, not suite types
- [ ] Each test has single clear behavior
- [ ] Tests follow Arrange-Act-Assert pattern

**Assertions:**
- [ ] Using `#expect` for most assertions
- [ ] Using `#require` for prerequisites
- [ ] Proper throw expectations for error cases
- [ ] Clear assertion messages when needed

**Mocking:**
- [ ] Mocks implement protocol contracts
- [ ] Mocks track call counts and arguments
- [ ] Mocks provide configurable return values
- [ ] Tests inject mocks via dependency injection

**Test Helpers:**
- [ ] Fixed dates for deterministic tests
- [ ] Factory methods with sensible defaults
- [ ] Only `@MainActor` on methods creating isolated types
- [ ] Non-isolated constants accessible from any context

**Coverage:**
- [ ] New features have corresponding tests
- [ ] Domain layer maintains 95%+ coverage
- [ ] Overall maintains 80%+ coverage
- [ ] Critical paths fully covered

**Best Practices:**
- [ ] Tests are parallel-safe
- [ ] No shared mutable state
- [ ] Tests execute quickly (< 1 second each)
- [ ] Tests are deterministic and non-flaky
- [ ] Parameterization used for repetitive cases

---

*Testing analysis: 2026-03-01*
