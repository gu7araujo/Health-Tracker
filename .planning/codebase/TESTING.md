# Testing Patterns

**Analysis Date:** 2026-02-26

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

# From command line (if using xcodebuild)
xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 15'
```

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

**What NOT to Mock:**
- Domain entities (use real instances)
- Value types (structs)
- View models (test with mocked dependencies)

## Fixtures and Factories

**Test Data:**
```swift
enum TestDataBuilder {
    // MARK: - Fixed Dates
    static let fixedDate = Date(timeIntervalSince1970: 1_708_387_200)
    static let fixedDatePlusOne = Date(timeIntervalSince1970: 1_708_473_600)

    // MARK: - DayData Builders
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
- `@MainActor` annotation for types requiring main thread

**Usage in Tests:**
```swift
@Test func dayData_status_optimal_hasGreenColor() {
    let dayData = TestDataBuilder.makeOptimalDay()
    #expect(dayData.status.color == .green)
}
```

## Coverage

**Requirements:** Not enforced (no coverage threshold configuration detected)

**View Coverage:**
- Coverage available through Xcode's built-in code coverage tool
- Enable in scheme settings: Edit Scheme → Test → Options → Code Coverage

**Command:**
```bash
# Generate coverage report via Xcode
# Edit Scheme → Test → Options → Enable "Code Coverage"
# View: Report Navigator → Coverage tab
```

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

**Test Independence:**
- Each test creates its own instances
- No shared mutable state between tests
- Use helper functions to create fresh test subjects

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

---

*Testing analysis: 2026-02-26*
