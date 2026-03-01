# Architecture

**Analysis Date:** 2026-03-01

## Pattern Overview

**Overall:** Clean Architecture with MVVM presentation layer

**Key Characteristics:**
- Strict separation of Domain, Data, and Presentation layers
- Dependency inversion via protocols (Domain depends on abstractions, not implementations)
- Use Cases encapsulate business logic
- SwiftUI with @Observable ViewModels (iOS 17+ Observation framework)
- Pure domain entities with computed business logic

## Layers

**Domain Layer:**
- Purpose: Core business logic and entities independent of frameworks
- Location: `HealthTracker/Domain/`
- Contains: Entities, Protocols, Use Cases
- Depends on: Nothing (no external dependencies)
- Used by: Presentation layer (ViewModels), Data layer (implements protocols)

**Data Layer:**
- Purpose: Data persistence and external data access
- Location: `HealthTracker/Data/`
- Contains: Repository implementations, DataSources, Models, Migrations, Services
- Depends on: Domain protocols (`HealthDataRepositoryProtocol`, `NotificationServiceProtocol`)
- Used by: Domain use cases (via dependency injection)

**Presentation Layer:**
- Purpose: UI rendering and user interaction
- Location: `HealthTracker/Presentation/`
- Contains: Views (SwiftUI), ViewModels (@Observable), Components
- Depends on: Domain (Use Cases, Entities)
- Used by: App entry point

**Extensions:**
- Purpose: Cross-cutting utilities and framework extensions
- Location: `HealthTracker/Extensions/`
- Contains: SwiftUI View extensions
- Depends on: SwiftUI framework only
- Used by: Presentation layer

## Data Flow

**User Action Flow:**

1. User interacts with SwiftUI View (`MainView`, `AnalyticsView`)
2. View calls ViewModel method (`MainViewModel.addMeal()`, `AnalyticsViewModel.loadAnalytics()`)
3. ViewModel invokes Use Case (`SaveDayDataUseCase.execute()`, `CalculateAnalyticsUseCase.execute()`)
4. Use Case calls Repository protocol method (`HealthDataRepositoryProtocol.save()`)
5. Repository delegates to DataSource (`ICloudDriveDataSource.save()`)
6. DataSource persists to storage (iCloud Drive JSON file or UserDefaults)
7. ViewModel updates state, SwiftUI re-renders automatically

**Data Load Flow:**

1. View appears, triggers `onFirstAppear` → `MainViewModel.loadData()`
2. ViewModel calls `LoadDayDataUseCase.execute()`
3. Use Case fetches from Repository → DataSource
4. DataSource reads JSON, decodes to `DayDataContainer`, parses to `RecordedDayData`
5. Use Case returns array of `RecordedDayData`
6. ViewModel converts to `DayData` for in-memory manipulation
7. ViewModel state updates, SwiftUI re-renders with data

**Notification Flow:**

1. User enables notifications toggle → `MainViewModel.enableNotifications()`
2. ViewModel calls `RequestNotificationPermissionUseCase.execute()`
3. Use Case delegates to `NotificationPermissionManager` (wrapper for UNUserNotificationCenter)
4. Permission granted → ViewModel calls `ScheduleNotificationsUseCase.execute()`
5. Use Case delegates to `NotificationService` (implements `NotificationServiceProtocol`)
6. Service schedules recurring daily notifications via UNUserNotificationCenter
7. User disables → `CancelNotificationsUseCase` removes pending notifications

**State Management:**
- ViewModels use @Observable macro (Swift Observation framework)
- No external state management library (Redux, TCA, etc.)
- Single source of truth: ViewModel state
- SwiftUI automatically tracks property access and updates views

## Key Abstractions

**RecordedDayData vs DayData:**
- Purpose: Separate persistence model from in-memory model
- Examples: `HealthTracker/Domain/Entities/RecordedDayData.swift`, `HealthTracker/Domain/Entities/DayData.swift`
- Pattern: Parse, don't validate. `RecordedDayData` has failable init that only succeeds if day has actual data. Empty days cannot be represented as `RecordedDayData`, ensuring persistence layer never stores empty entries.

**LocalDataSourceProtocol:**
- Purpose: Abstract persistence mechanism for testing and flexibility
- Examples: `HealthTracker/Data/DataSources/UserDefaultsDataSource.swift`, `HealthTracker/Data/DataSources/ICloudDriveDataSource.swift`
- Pattern: Protocol with multiple implementations. Production uses iCloud Drive, legacy used UserDefaults.

**HealthDataRepositoryProtocol:**
- Purpose: Domain-level abstraction for data access (Dependency Inversion Principle)
- Examples: `HealthTracker/Domain/Protocols/HealthDataRepositoryProtocol.swift`, `HealthTracker/Data/Repositories/HealthDataRepository.swift`
- Pattern: Domain defines interface, Data layer implements it. Use Cases depend on protocol, not concrete repository.

**NotificationServiceProtocol:**
- Purpose: Abstract notification scheduling for testing and platform independence
- Examples: `HealthTracker/Domain/Protocols/NotificationServiceProtocol.swift`, `HealthTracker/Data/Services/NotificationService.swift`
- Pattern: Domain defines interface, Data layer wraps UserNotifications framework. Enables notification testing without system dependencies.

**Use Cases:**
- Purpose: Encapsulate single business operations
- Examples: `HealthTracker/Domain/UseCases/LoadDayDataUseCase.swift`, `HealthTracker/Domain/UseCases/SaveDayDataUseCase.swift`, `HealthTracker/Domain/UseCases/CalculateAnalyticsUseCase.swift`, `HealthTracker/Domain/UseCases/ScheduleNotificationsUseCase.swift`
- Pattern: Single responsibility classes with `execute()` method. Injected into ViewModels.

## Entry Points

**HealthTrackerApp:**
- Location: `HealthTracker/HealthTrackerApp.swift`
- Triggers: @main attribute (app launch)
- Responsibilities: Runs data migrations, constructs root TabView with MainView and AnalyticsView tabs

**MainView:**
- Location: `HealthTracker/Presentation/Views/MainView.swift`
- Triggers: Selected tab in TabView
- Responsibilities: Daily health tracking interface, manages adding/editing meals and workouts, displays water slider and mood selector, notification toggle

**AnalyticsView:**
- Location: `HealthTracker/Presentation/Views/AnalyticsView.swift`
- Triggers: Selected tab in TabView
- Responsibilities: Displays analytics charts for selected period (7d/30d/90d/1y), loads data on period change

## Error Handling

**Strategy:** Graceful degradation with DEBUG-only logging

**Patterns:**
- DataSource failures: Return empty array on decode errors, log in DEBUG builds
- Repository operations: Pass through DataSource results, no additional error handling
- ViewModels: Assume operations succeed, no explicit error states exposed to UI
- File I/O: Use NSFileCoordinator for safe concurrent access to iCloud Drive files
- Notification permission denial: Silent fallback, toggle reflects actual permission state
- Notification scheduling errors: Logged in DEBUG, no UI feedback

## Cross-Cutting Concerns

**Logging:** `#if DEBUG print() #endif` conditionals for development-only console output. No production logging framework.

**Validation:** Parse, don't validate pattern. `RecordedDayData` failable init, `Workout.Duration` clamping (1-300 minutes), enum constraints for `Meal.Quantity` and `Meal.Satisfaction`.

**Authentication:** Not applicable. Single-user local app with optional iCloud sync.

**Migrations:** Startup data migrations in `HealthTracker/Data/Migration/DataMigration.swift`. Called from app init, uses UserDefaults flags to prevent re-running. Migrates UserDefaults → iCloud Drive and old workout duration format → new format.

**Notifications:** UserNotifications framework integration via `NotificationServiceProtocol`. Daily recurring notifications (3x per day: 12:00, 15:00, 18:00) with localized content. Permission management via `NotificationPermissionManager` wrapper.

## Clean Architecture Principles (from AGENTS.md)

### Progressive Architecture
Start simple → Add complexity only when proven necessary. Do NOT abstract on first or second usage. DUPLICATE code until pattern is proven three times. Refactor only when commonality is structural, not accidental.

### Testable by Design
Inject all dependencies via initializer. Design for testing from start. Test behavior, not implementation. Decouple from frameworks.

### Type-Driven Design

**Comprehensive Error Handling:** Make impossible states unrepresentable using exhaustive enums with associated values. Provide actionable recovery paths. NEVER force unwrap in production.

**Parse, Don't Validate:** Use types to carry proof of validation. Create validation-carrying types instead of validating raw strings. Types serve as vessels for validated data. Validation checks can be displaced; parsed types cannot be created without validation.

**Domain Boundaries & Type Placement:** Keep strongly-typed domain types in domain, weakly-typed primitives at boundaries. Domain logic lives with domain types. UI domain works with strings. Network/Data layer works with strings/JSON. Parse at boundaries: convert strings → domain types when entering domain, domain types → strings when leaving.

**Witness Pattern for Access Control:** Turn conventions into compile-time requirements. A Witness is a value that proves a precondition is met. Replace boolean flags with optional witness types. Use `fileprivate init()` to prevent forging witnesses outside their origin. Require witnesses as non-optional arguments to enforce access control at compile time.

### Layer Responsibilities

**Domain Layer Rules:**
- No dependencies on frameworks or external libraries
- Define protocols, never implementations
- Pure business logic only
- Entities contain computed business logic (e.g., `DayData.status`)
- Use Cases coordinate between protocols

**Data Layer Rules:**
- Implements domain protocols
- Depends on domain abstractions only
- Handles framework-specific code (FileManager, UserDefaults, UserNotifications)
- Repository delegates to DataSource
- Services wrap system frameworks

**Presentation Layer Rules:**
- Depends on domain only (Use Cases, Entities)
- Never accesses Data layer directly
- ViewModels coordinate between Views and Use Cases
- Views are pure, side-effect-free SwiftUI
- Use @Observable (not ObservableObject) for state management

---

*Architecture analysis: 2026-03-01*
