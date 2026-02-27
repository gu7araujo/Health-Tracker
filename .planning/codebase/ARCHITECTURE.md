# Architecture

**Analysis Date:** 2026-02-26

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
- Contains: Repository implementations, DataSources, Models, Migrations
- Depends on: Domain protocols (`HealthDataRepositoryProtocol`)
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

**Use Cases:**
- Purpose: Encapsulate single business operations
- Examples: `HealthTracker/Domain/UseCases/LoadDayDataUseCase.swift`, `HealthTracker/Domain/UseCases/SaveDayDataUseCase.swift`, `HealthTracker/Domain/UseCases/CalculateAnalyticsUseCase.swift`
- Pattern: Single responsibility classes with `execute()` method. Injected into ViewModels.

## Entry Points

**HealthTrackerApp:**
- Location: `HealthTracker/HealthTrackerApp.swift`
- Triggers: @main attribute (app launch)
- Responsibilities: Runs data migrations, constructs root TabView with MainView and AnalyticsView tabs

**MainView:**
- Location: `HealthTracker/Presentation/Views/MainView.swift`
- Triggers: Selected tab in TabView
- Responsibilities: Daily health tracking interface, manages adding/editing meals and workouts, displays water slider and mood selector

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

## Cross-Cutting Concerns

**Logging:** `#if DEBUG print() #endif` conditionals for development-only console output. No production logging framework.

**Validation:** Parse, don't validate pattern. `RecordedDayData` failable init, `Workout.Duration` clamping (1-300 minutes), enum constraints for `Meal.Quantity` and `Meal.Satisfaction`.

**Authentication:** Not applicable. Single-user local app with optional iCloud sync.

**Migrations:** Startup data migrations in `HealthTracker/Data/Migration/DataMigration.swift`. Called from app init, uses UserDefaults flags to prevent re-running. Migrates UserDefaults → iCloud Drive and old workout duration format → new format.

---

*Architecture analysis: 2026-02-26*
