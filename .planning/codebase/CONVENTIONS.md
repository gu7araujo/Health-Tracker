# Coding Conventions

**Analysis Date:** 2026-03-01

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
- Mutating/nonmutating pairs follow Swift API guidelines: `reverse()` / `reversed()`, `sort()` / `sorted()`
- Methods form grammatical phrases at call site: `insert(y, at: z)`, `capitalizingNouns()`

**Variables:**
- camelCase for properties and local variables
- Private properties prefixed with nothing (use `private` keyword)
- Descriptive names by role, not type: `selectedDate`, `currentDayData`, `waterIntake`, `supplier` (not `dateVariable`, `dataObject`)
- Collections pluralized: `days`, `meals`, `workouts`
- Optional values named naturally: `water: Double?`, `mood: Mood?`
- Boolean properties read as assertions: `isEmpty`, `hasAppeared`, `isCancelled`

**Types:**
- PascalCase for all types (structs, classes, enums, protocols)
- Enums with lowercase cases: `.optimal`, `.moderate`, `.poor`, `.good`, `.sad`
- Nested types capitalized: `Meal.Quantity`, `Meal.Satisfaction`, `Workout.Duration`
- Capability protocols end with `-able`, `-ible`, or `-ing`: `Equatable`, `Identifiable`, `Codable`
- Descriptive protocols end with `Protocol`: `HealthDataRepositoryProtocol`, `LocalDataSourceProtocol`

## Swift API Design Guidelines

Following Apple's [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/):

**Fundamentals:**
- **Clarity at the point of use** is the primary goal
- Include all words needed to avoid ambiguity: `remove(at: position)` not `remove(position)`
- Omit needless words that repeat type information: `remove(_ member:)` not `removeElement(_ member:)`
- Name variables, parameters, and types by their **role**, not type constraints

**Fluent Usage:**
- Factory methods start with **make**: `makeIterator()`, `makeDayData()`
- Side-effect-free operations use noun phrases: `distance(to:)`, `status`
- Operations with side effects use imperative verbs: `updateWater()`, `persistChanges()`
- Boolean properties/methods read as assertions: `isEmpty`, `isDate(_:inSameDayAs:)`

**Argument Labels:**
- Omit labels when arguments can't be distinguished: `min(a, b)`, `zip(s1, s2)`
- First argument completes grammatical phrase → omit label: `addSubview(y)`, `addMeal(meal)`
- Otherwise use labels: `updateWater(_ value:)`, `dismiss(animated:)`
- All other arguments have labels: `makeDayData(date:meals:workouts:water:mood:)`

**Example from codebase:**
```swift
// Clear at call site
func updateWater(_ value: Double)
viewModel.updateWater(2.0)

// Factory method with "make" prefix
static func makeDayData(
    date: Date = fixedDate,
    meals: [Meal] = [],
    workouts: [Workout] = [],
    water: Double? = nil,
    mood: Mood? = nil
) -> DayData
```

## Code Style

**Formatting:**
- Tool: Xcode default formatting (no custom .swiftformat or .swiftlint.yml detected)
- Indentation: 4 spaces
- Line length: No enforced limit, typically kept under 120 characters
- Braces: K&R style (opening brace on same line)
- Blank lines separate logical sections with `// MARK: -` comments

**Linting:**
- Tool: None configured (no .swiftlint.yml)
- Style enforced through code review and Swift API Design Guidelines

**Commands:**
```bash
# Lint Swift code and apply fixes (run after editing)
swiftlint --fix && swiftlint

# Format Swift code (run after editing)
swiftformat . --swift-version 6
```

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
- **NEVER force unwrap** (`!`) in production code

**Comprehensive Error Handling (Type-Driven Design):**
- Make impossible states unrepresentable through type system
- Use exhaustive enums with associated values for error cases
- Provide actionable recovery paths
- Example: `RecordedDayData` has failable init that guarantees at least one health category

**Example:**
```swift
func updateWater(_ value: Double) {
    guard let index = currentDayIndex else { return }
    days[index].water = value > 0 ? value : nil
    persistChanges()
}
```

## Parse, Don't Validate Pattern

**Use types to carry proof of validation:**
- Create validation-carrying types instead of validating raw primitives
- Types serve as vessels for validated data with guaranteed invariants
- Prefer parsing (transformation with retention) over validation (check with discard)
- Example: `RecordedDayData` can only be constructed if data meets validation criteria
- Eliminates systemic vulnerabilities from scattered validation logic

**Domain Boundaries & Type Placement:**
- Domain logic lives with domain types
- Domain layer uses strongly-typed entities: `Meal`, `Workout`, `DayData`, `RecordedDayData`
- Data layer works with primitives for serialization: `Codable` conformance for JSON
- Parse at boundaries: convert JSON → domain types when loading, domain types → JSON when saving
- This achieves clean, robust domain code where invariants are enforced by types

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

**Documentation Style (Swift's Markdown dialect):**
- Triple-slash `///` for types, functions, and properties
- Begin with one-line summary (sentence fragment ending with period)
- Describe what function/method does and returns
- Describe what subscript accesses
- Describe what initializer creates
- Describe what other entities are
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

/// ViewModel for the main health tracking view.
/// Extracts business logic from the view and coordinates with use cases.
@Observable
final class MainViewModel {
    /// Returns the day data for the currently selected date.
    var currentDayData: DayData? {
        days.first { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    /// Updates water intake for the current day.
    /// - Parameter value: The new water intake value in liters.
    func updateWater(_ value: Double) {
        guard let index = currentDayIndex else { return }
        days[index].water = value > 0 ? value : nil
        persistChanges()
    }
}
```

**MARK Usage:**
```swift
// MARK: - Initialization
// MARK: - Public Methods
// MARK: - Water Management
// MARK: - Private Methods
// MARK: - Dependencies
// MARK: - State
// MARK: - Computed Properties
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
- Put parameters with defaults at end of parameter list

**Return Values:**
- Return optionals when failure/absence is valid: `func meal(withId id: UUID) -> Meal?`
- Return concrete values when always available: `func execute() -> [RecordedDayData]`
- Return tuples for related values: `(current: Int, longest: Int)`
- Use `Void` or omit for side-effect-only functions

**Prefer Methods Over Free Functions:**
- Use methods and properties unless:
  - No obvious `self`: `min(x, y, z)`
  - Unconstrained generic: `print(x)`
  - Domain notation: `sin(x)`

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

## Property Wrappers (SwiftUI)

**Usage:**
- `@Observable` for view models: `@Observable final class MainViewModel`
- `@State` for view-local state: `@State private var hasAppeared = false`
- `@State` for owned `@Observable` objects: `@State private var viewModel = MainViewModel()`
- `@Binding` for two-way data flow: `@Binding var backgroundColor: Color?`
- `@Bindable` for injected `@Observable` objects needing bindings
- `@ViewBuilder` for view builder closures: `@ViewBuilder var content: Content`
- `@MainActor` for main-thread-only types and functions (view models, SwiftUI views)

**Always prefer `@Observable` over `ObservableObject`** for new code (iOS 17+):
```swift
@Observable
final class MainViewModel {
    private(set) var days: [DayData] = []
    var selectedDate: Date = .init()
}

struct MyView: View {
    @State private var viewModel = MainViewModel()
}
```

**State Management Rules:**
- Always mark `@State` as `private` (makes dependencies clear)
- Never declare passed values as `@State` (they only accept initial values)
- Use `@Binding` only when child needs to modify parent state
- Use `let` for read-only values from parent
- Mark `@Observable` classes with `@MainActor` unless using default actor isolation

## Protocols

**Naming:**
- Suffix with `Protocol`: `HealthDataRepositoryProtocol`, `LocalDataSourceProtocol`
- Describe capability: `Identifiable`, `Codable`, `Equatable`

**Usage:**
- Define interfaces for dependency injection
- Enable mocking in tests
- Standard library protocols for common functionality

**Example:**
```swift
protocol HealthDataRepositoryProtocol {
    func loadAllDays() -> [RecordedDayData]
    func save(days: [RecordedDayData])
    func loadDaysInRange(_ range: ClosedRange<Date>) -> [RecordedDayData]
}
```

## Enums

**Style:**
- lowercase cases consistently: `.optimal`, `.moderate`, `.poor`
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

enum Quantity: Int, Codable, CaseIterable {
    case verySmall = 0
    case small = 1
    case medium = 2
    case large = 3

    var localizedName: String {
        switch self {
        case .verySmall: "Muito pequena"
        case .small: "Pequena"
        case .medium: "Média"
        case .large: "Grande"
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
- Static member lookup: `.blue` instead of `Color.blue`

**Example:**
```swift
// Type inference
let days = loadUseCase.execute().map(\.dayData)

// Explicit when needed
var water: Double? = nil

// Shorthand closures
days.first { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }

// Static member lookup
Text("Hello").foregroundStyle(.blue)
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

// Dependency injection with convenience initializer
init(
    loadUseCase: LoadDayDataUseCase,
    saveUseCase: SaveDayDataUseCase
) {
    self.loadUseCase = loadUseCase
    self.saveUseCase = saveUseCase
}

convenience init(repository: HealthDataRepositoryProtocol = HealthDataRepository()) {
    self.init(
        loadUseCase: LoadDayDataUseCase(repository: repository),
        saveUseCase: SaveDayDataUseCase(repository: repository)
    )
}
```

## Computed Properties vs Functions

**Guidelines:**
- Use computed properties for derived state: `var currentDayData: DayData?`
- Use functions for operations with side effects: `func loadData()`
- Use computed properties for simple transformations: `var color: Color?`
- Use functions for operations that take parameters: `func meal(withId:)`
- Document non-O(1) computed properties

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

    func onFirstAppear(perform action: @escaping () -> Void) -> some View {
        modifier(FirstAppearModifier(action: action))
    }
}
```

## Concurrency (Swift 6)

**Actor Isolation:**
- Mark `@Observable` classes with `@MainActor` for UI-related state (unless using default actor isolation)
- Use `@MainActor` on SwiftUI views and view models
- Prefer structured concurrency (child tasks, task groups) over unstructured tasks
- Use `.task` modifier for automatic cancellation of async work

**Sendable Conformance:**
- Enable safe concurrent access by conforming types to `Sendable`
- Value types (structs) are implicitly `Sendable` if all properties are `Sendable`
- Make types `Sendable` to enable safe passing across isolation boundaries

**Example:**
```swift
@Observable
final class MainViewModel {
    // All properties and methods implicitly @MainActor isolated
    private(set) var days: [DayData] = []

    func loadData() {
        days = loadUseCase.execute().map(\.dayData)
    }
}
```

**Actor Isolation in Test Helpers:**
- Don't mark entire test helper enums/structs with `@MainActor`
- Only mark specific factory methods that create `@Observable` types with `@MainActor`
- Keep date constants and other non-isolated properties accessible from any context

**Example from `TestDataBuilder`:**
```swift
enum TestDataBuilder {
    // Non-isolated constant
    static let fixedDate = Date(timeIntervalSince1970: 1_708_387_200)

    // Only factory methods that create @MainActor-isolated types are marked
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
}
```

## SwiftUI Best Practices

**State Management:**
- Prefer `@Observable` over `ObservableObject`
- Always mark `@State` and `@StateObject` as `private`
- Never declare passed values as `@State` or `@StateObject`
- Use `@Binding` only when child modifies parent state
- Use `let` for read-only values

**Modern APIs:**
- Use `foregroundStyle()` instead of `foregroundColor()`
- Use `clipShape(.rect(cornerRadius:))` instead of `cornerRadius()`
- Use `Tab` API instead of `tabItem()`
- Use `Button` instead of `onTapGesture()` (unless need location/count)
- Use `NavigationStack` instead of `NavigationView`
- Use two-parameter `onChange(of:) { old, new in }` or no-parameter variant
- Use `.sheet(item:)` instead of `.sheet(isPresented:)` for model-based content

**View Composition:**
- Prefer modifiers over conditional views for state changes (maintains view identity)
- Extract complex views into separate subviews
- Keep views small for optimal performance
- Keep view `body` simple and pure (no side effects or complex logic)

**Performance:**
- Pass only needed values to views (avoid large config objects)
- Eliminate unnecessary dependencies to reduce update fan-out
- Use `LazyVStack`/`LazyHStack` for large lists
- Use stable identity for `ForEach` (never `.indices` for dynamic content)

**iOS 26+ Liquid Glass:**
- Use native `glassEffect`, `GlassEffectContainer`, and glass button styles
- Wrap multiple glass elements in `GlassEffectContainer`
- Apply `.glassEffect()` after layout and visual modifiers
- Gate with `#available(iOS 26, *)` and provide fallbacks

## Swift 6 Strict Concurrency

**Project Settings:**
- Swift 6 language mode enabled
- Strict concurrency checking enforced
- Complete data-race safety at compile time

**Best Practices:**
- Prefer structured concurrency (task groups, async let) over unstructured tasks
- Handle cancellation with `Task.isCancelled` in long-running operations
- Never use semaphores or locks in async contexts
- Test concurrent code properly with async test methods

---

*Convention analysis: 2026-03-01*
