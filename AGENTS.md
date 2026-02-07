# Agent Guide

This file provides guidance to AI agents when working with code in this repository.

## Project Overview

HealthTracker is a modern iOS 26.0 health tracking app built with SwiftUI and Swift 6. The app helps users monitor daily habits including meals, water intake, workouts, and mood. It uses a Clean Architecture approach with clear separation between Domain, Data, and Presentation layers.

## Technology Stack

- **Language**: Swift 6
- **UI Framework**: SwiftUI with iOS 26+ Liquid Glass effects
- **Target**: iOS 26.0+
- **Architecture**: Clean Architecture (Domain/Data/Presentation)
- **Persistence**: UserDefaults (JSON encoding)
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

## Architecture

The codebase follows Clean Architecture principles with three main layers:

### Domain Layer (`HealthTracker/Domain/`)
- **Entities**: Core business models (`DayData`, `Meal`, `Workout`, `Mood`, `DayStatus`)
  - `DayData`: Aggregate root containing all health data for a single day
  - Implements business logic for health status computation (optimal/moderate/poor)
- **Protocols**: Abstract interfaces (`HealthDataRepositoryProtocol`, `LocalDataSourceProtocol`)
- **Use Cases**: Business operations (`LoadDayDataUseCase`, `SaveDayDataUseCase`)

### Data Layer (`HealthTracker/Data/`)
- **Repositories**: Concrete implementations of domain protocols
  - `HealthDataRepository`: Orchestrates data operations
- **DataSources**: Platform-specific storage implementations
  - `UserDefaultsDataSource`: JSON-based persistence using UserDefaults

### Presentation Layer (`HealthTracker/Presentation/`)
- **Views**: SwiftUI views with section-based composition
  - `MainView`: Root view with meals, water, workouts, mood sections
  - `AddEditModal`: Shared modal for adding/editing meals and workouts
  - **Components**: Reusable UI components (`CardView`, `CalendarStrip`, `CardListView`)
- **ViewModels**: Observable view models using @Observable macro
  - `MainViewModel`: Manages all health tracking state and coordinates with use cases
  - Uses dependency injection with default convenience initializer

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
</avoid>

## Language and Localization

The app is currently in Portuguese (Brazil). All UI strings, entity property names (e.g., `Meal.Quantity.localizedName`), and user-facing text are in Portuguese.

## Working with the Codebase

### Adding New Features
1. Start with Domain layer (entities, use cases)
2. Implement Data layer changes (repository, data source if needed)
3. Update Presentation layer (views, view model)
4. Use dependency injection for testability

### Modifying Views
- Follow existing section-based composition pattern in `MainView`
- Extract complex sections into private structs (see `MealsSectionView`, `WorkoutsSectionView`)
- Use `CardView` for consistent glass effect styling
- Leverage iOS 26+ Liquid Glass with `.glassEffect()` modifier

### Storage Changes
- All persistence goes through `LocalDataSourceProtocol`
- Storage key is "store" in UserDefaults
- Data is wrapped in `DayDataContainer` for encoding/decoding
- Graceful error handling: returns empty arrays on decode failures

### Entity Modifications
- Entities are `Codable`, so changes may require migration logic
- `DayData` computes health status based on business rules (see `status`, `meetsOptimalCriteria`, `meetsModerateCriteria`)
- Nested enums have localized names (e.g., `Meal.Quantity.localizedName`)

## Agent Skills - Available Skills

When working on specific tasks, use these specialized skills:

<skills_system priority="1">

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
<name>swift-concurrency</name>
<description>'Expert guidance on Swift Concurrency best practices, patterns, and implementation. Use when developers mention: (1) Swift Concurrency, async/await, actors, or tasks, (2) "use Swift Concurrency" or "modern concurrency patterns", (3) migrating to Swift 6, (4) data races or thread safety issues, (5) refactoring closures to async/await, (6) @MainActor, Sendable, or actor isolation, (7) concurrent code architecture or performance optimization, (8) concurrency-related linter warnings (SwiftLint or similar; e.g. async_without_await, Sendable/actor isolation/MainActor lint).'</description>
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
- No unit tests exist yet in the project
- For external knowledge consult the `context7` tool for most up-to-date software package documentation
- For internal knowledge consult the `serena` tool before editing code to verify existing function signatures, find references, or map project dependencies
- Prefer serena's symbol-based reading over full-file reading for large files to maintain a lean context window and efficiency
- Use the agent skills to perform activities
