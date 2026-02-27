# Coding Conventions

**Analysis Date:** 2026-02-26

## Naming Patterns

**Files:**
- PascalCase for all Swift files
- Entity files match their type name: `Meal.swift`, `Workout.swift`, `DayStatus.swift`
- View files descriptive with suffix: `MainView.swift`, `AddEditModal.swift`, `CardView.swift`
- ViewModels with suffix: `MainViewModel.swift`, `AnalyticsViewModel.swift`
- Test files mirror source with `Tests` suffix: `MealTests.swift`, `DayStatusTests.swift`
- Extensions follow pattern: `View+Extensions.swift`
- Protocols end with `Protocol`: `HealthDataRepositoryProtocol`, `LocalDataSourceProtocol`
- Mocks prefixed with `Mock`: `MockHealthDataRepository.swift`, `MockLocalDataSource.swift`
- Test helpers: `TestDataBuilder.swift`

**Functions:**
- camelCase for all functions
- Descriptive verb-based names: `loadData()`, `updateWater()`, `addMeal()`, `calculateAnalytics()`
- Boolean queries start with `is`: `isDate(_:inSameDayAs:)`
- Factory functions start with `make`: `makeDayData()`, `makeOptimalDay()`
- Use `execute()` for use case entry points

**Variables:**
- camelCase for properties and local variables
- Private properties prefixed with nothing (use `private` keyword)
- Descriptive names: `selectedDate`, `currentDayData`, `waterIntake`
- Collections pluralized: `days`, `meals`, `workouts`
- Optional values named naturally: `water: Double?`, `mood: Mood?`

**Types:**
- PascalCase for all types (structs, classes, enums, protocols)
- Enums with lowercase cases: `.optimal`, `.moderate`, `.poor`, `.good`, `.sad`
- Nested types capitalized: `Meal.Quantity`, `Meal.Satisfaction`, `Workout.Duration`

## Code Style

**Formatting:**
- Tool: Xcode default formatting (no custom .swiftformat or .swiftlint.yml detected)
- Indentation: 4 spaces
- Line length: No enforced limit, but typically kept under 120 characters
- Braces: K&R style (opening brace on same line)
- Blank lines separate logical sections with `// MARK: -` comments

**Linting:**
- Tool: None configured (no .swiftlint.yml)
- Style enforced through code review and convention

## Import Organization

**Order:**
1. Foundation framework imports
2. SwiftUI framework imports
3. Testing framework imports (`Testing` for tests)
4. `@testable import HealthTracker` (tests only)

**Example:**
```swift
import Foundation
import SwiftUI
@testable import HealthTracker
import Testing
```

**Path Aliases:**
- Not used (standard Swift module imports only)

## Error Handling

**Patterns:**
- Guard statements for early returns: `guard let index = currentDayIndex else { return }`
- Optional chaining for safe access: `currentDayData?.meals.first`
- `try?` for non-critical operations where failure is acceptable
- `try` with `throws` for operations that should propagate errors (seen in Codable)
- Nil-coalescing for defaults: `currentDayData?.water ?? 0`

**Example:**
```swift
func updateWater(_ value: Double) {
    guard let index = currentDayIndex else { return }
    days[index].water = value > 0 ? value : nil
    persistChanges()
}
```

## Logging

**Framework:** No logging framework detected (console-based or none)

**Patterns:**
- No explicit logging seen in codebase
- Errors handled through guard clauses and optional returns
- Tests use `#expect` assertions for validation

## Comments

**When to Comment:**
- File headers with copyright and creation info on every file
- Public API documentation using triple-slash `///` comments
- Complex logic explanation (seen in `CalculateAnalyticsUseCase.swift`)
- Algorithm explanations for non-obvious code
- MARK comments to organize sections

**Documentation Style:**
- Triple-slash `///` for types, functions, and properties
- Parameters documented with `- Parameter name: description`
- Returns documented with `- Returns: description`
- Enum cases documented inline

**Example:**
```swift
/// Represents a meal entry with quantity and satisfaction level.
/// Replaces the generic `Item` struct with meal-specific properties.
struct Meal: Identifiable, Codable, Equatable {
    /// Portion size of the meal
    enum Quantity: Int, Codable, CaseIterable {
        // ...
    }
}
```

**MARK Usage:**
```swift
// MARK: - Initialization
// MARK: - Public Methods
// MARK: - Water Management
// MARK: - Private Methods
```

## Function Design

**Size:**
- Single responsibility principle applied
- Most functions under 30 lines
- Complex calculations broken into private helper methods
- Example: `CalculateAnalyticsUseCase` breaks analytics into `calculateMealAnalytics()`, `calculateWaterAnalytics()`, etc.

**Parameters:**
- Use parameter labels for clarity: `meal(withId:)`, `loadDaysInRange(_:)`
- Default parameters for optional config: `init(repository: HealthDataRepositoryProtocol = HealthDataRepository())`
- Omit first parameter label when obvious from context using `_`
- Named parameters improve readability: `makeDayData(date:meals:workouts:water:mood:)`

**Return Values:**
- Return optionals when failure/absence is valid: `func meal(withId id: UUID) -> Meal?`
- Return concrete values when always available: `func execute() -> [RecordedDayData]`
- Return tuples for related values: `(current: Int, longest: Int)`
- Use `Void` or omit for side-effect-only functions

## Module Design

**Exports:**
- No explicit `public`/`internal` modifiers in most files (internal by default)
- Use `private` for implementation details
- Use `private(set)` for read-only external access: `private(set) var days: [DayData]`
- Protocols define public contracts

**Architecture:**
- Clean Architecture layers: Domain, Data, Presentation
- Domain entities and protocols in `Domain/` directory
- Data sources and repositories in `Data/` directory
- Views and ViewModels in `Presentation/` directory
- Extensions in `Extensions/` directory

**Barrel Files:**
- Not used (no re-export files detected)

## Property Wrappers

**Usage:**
- `@Observable` for view models: `@Observable final class MainViewModel`
- `@State` for view-local state: `@State private var hasAppeared = false`
- `@Binding` for two-way data flow: `@Binding var backgroundColor: Color?`
- `@ViewBuilder` for view builder closures: `@ViewBuilder var content: Content`
- `@MainActor` for main-thread-only types and functions (tests and view models)

## Protocols

**Naming:**
- Suffix with `Protocol`: `HealthDataRepositoryProtocol`, `LocalDataSourceProtocol`
- Describe capability: `Identifiable`, `Codable`, `Equatable`

**Usage:**
- Define interfaces for dependency injection
- Enable mocking in tests
- Standard library protocols for common functionality

## Enums

**Style:**
- lowercase cases consistently
- Associated values when needed (not heavily used in this codebase)
- Raw values for serialization: `enum Quantity: Int, Codable`
- `CaseIterable` for exhaustive iteration
- Computed properties for display: `var localizedName: String`
- Computed properties for UI: `var color: Color?`

**Example:**
```swift
enum DayStatus: Equatable {
    case optimal
    case moderate
    case poor
    case incomplete
    case noData

    var color: Color? {
        switch self {
        case .optimal: .green
        case .moderate: .yellow
        case .poor: .red
        case .incomplete: .primary
        case .noData: nil
        }
    }
}
```

## Type Inference

**Patterns:**
- Type inference used extensively for clarity
- Explicit types when ambiguous or for documentation
- Trailing closure syntax for single closure parameters
- Shorthand syntax in closures: `$0`, `$1`

**Example:**
```swift
// Type inference
let days = loadUseCase.execute().map(\.dayData)

// Explicit when needed
var water: Double? = nil

// Shorthand closures
days.first { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
```

## Initialization

**Patterns:**
- Designated initializers with all parameters
- Default parameter values for common cases
- Convenience initializers for simpler construction
- Dependency injection through initializers

**Example:**
```swift
init(
    id: UUID = UUID(),
    description: String,
    quantity: Quantity = .small,
    satisfaction: Satisfaction = .fifty
) {
    self.id = id
    self.description = description
    self.quantity = quantity
    self.satisfaction = satisfaction
}
```

## Computed Properties vs Functions

**Guidelines:**
- Use computed properties for derived state: `var currentDayData: DayData?`
- Use functions for operations with side effects: `func loadData()`
- Use computed properties for simple transformations: `var color: Color?`
- Use functions for operations that take parameters: `func meal(withId:)`

## Extensions

**Organization:**
- Located in `HealthTracker/Extensions/` directory
- Extend types with additional functionality
- Use for protocol conformance: `extension Workout.Duration: Codable`
- Group related functionality: `View+Extensions.swift` contains multiple View extensions

**Example from `HealthTracker/Extensions/View+Extensions.swift`:**
```swift
extension View {
    @ViewBuilder
    func `if`(_ condition: Bool, transform: (Self) -> some View) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
```

---

*Convention analysis: 2026-02-26*
