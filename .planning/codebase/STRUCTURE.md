# Codebase Structure

**Analysis Date:** 2026-02-26

## Directory Layout

```
HealthTracker/
├── HealthTracker/                     # Main app target
│   ├── HealthTrackerApp.swift         # App entry point
│   ├── Domain/                        # Business logic layer
│   │   ├── Entities/                  # Domain models
│   │   ├── Protocols/                 # Domain interfaces
│   │   └── UseCases/                  # Business operations
│   ├── Data/                          # Data persistence layer
│   │   ├── DataSources/               # Storage implementations
│   │   ├── Repositories/              # Repository implementations
│   │   ├── Models/                    # Data transfer objects
│   │   └── Migration/                 # Data migration logic
│   ├── Presentation/                  # UI layer
│   │   ├── Views/                     # SwiftUI views
│   │   │   └── Components/            # Reusable UI components
│   │   │       └── Charts/            # Analytics chart components
│   │   └── ViewModels/                # Presentation logic
│   ├── Extensions/                    # Framework extensions
│   ├── Assets.xcassets/               # Images and colors
│   ├── Info.plist                     # App configuration
│   └── HealthTracker.entitlements     # App capabilities (iCloud)
├── HealthTrackerTests/                # Test target (mirrors main structure)
│   ├── Domain/                        # Domain layer tests
│   ├── Data/                          # Data layer tests
│   ├── Presentation/                  # Presentation layer tests
│   ├── Mocks/                         # Test doubles
│   └── TestHelpers/                   # Testing utilities
├── HealthTracker.xcodeproj/           # Xcode project
├── AGENTS.md                          # AI agent documentation
└── README.md                          # Project readme
```

## Directory Purposes

**HealthTracker/Domain/Entities:**
- Purpose: Pure business entities with no dependencies
- Contains: `DayData.swift`, `Meal.swift`, `Workout.swift`, `Mood.swift`, `DayStatus.swift`, `RecordedDayData.swift`, analytics entities
- Key files: `DayData.swift` (aggregate root), `RecordedDayData.swift` (persistence wrapper)

**HealthTracker/Domain/Protocols:**
- Purpose: Domain-level abstractions for dependency inversion
- Contains: `HealthDataRepositoryProtocol.swift`
- Key files: `HealthDataRepositoryProtocol.swift` (defines repository contract)

**HealthTracker/Domain/UseCases:**
- Purpose: Single-purpose business operations
- Contains: `LoadDayDataUseCase.swift`, `SaveDayDataUseCase.swift`, `CalculateAnalyticsUseCase.swift`
- Key files: All three use cases are critical for app functionality

**HealthTracker/Data/DataSources:**
- Purpose: Concrete storage implementations
- Contains: `ICloudDriveDataSource.swift`, `UserDefaultsDataSource.swift` (includes `LocalDataSourceProtocol`)
- Key files: `ICloudDriveDataSource.swift` (production storage), `UserDefaultsDataSource.swift` (protocol + legacy implementation)

**HealthTracker/Data/Repositories:**
- Purpose: Repository pattern implementations
- Contains: `HealthDataRepository.swift`
- Key files: `HealthDataRepository.swift` (implements `HealthDataRepositoryProtocol`)

**HealthTracker/Data/Models:**
- Purpose: Data transfer objects for serialization
- Contains: `DayDataContainer.swift`
- Key files: `DayDataContainer.swift` (JSON wrapper for days array)

**HealthTracker/Data/Migration:**
- Purpose: One-time data migrations
- Contains: `DataMigration.swift`
- Key files: `DataMigration.swift` (handles UserDefaults→iCloud and workout duration migrations)

**HealthTracker/Presentation/Views:**
- Purpose: SwiftUI view hierarchies
- Contains: `MainView.swift`, `AnalyticsView.swift`, `AddEditModal.swift`, components
- Key files: `MainView.swift` (daily tracking), `AnalyticsView.swift` (analytics display)

**HealthTracker/Presentation/Views/Components:**
- Purpose: Reusable UI components
- Contains: `CalendarStrip.swift`, `CardView.swift`, `CardListView.swift`, `PeriodSelector.swift`
- Key files: `CalendarStrip.swift` (date picker with status indicators), `CardView.swift` (generic card container)

**HealthTracker/Presentation/Views/Components/Charts:**
- Purpose: Analytics visualization components
- Contains: `MealsBarChart.swift`, `WaterLineChart.swift`, `WorkoutsBarChart.swift`, `MoodBarChart.swift`, `OverallHealthRingChart.swift`
- Key files: All five chart components for analytics view

**HealthTracker/Presentation/ViewModels:**
- Purpose: Presentation logic with @Observable
- Contains: `MainViewModel.swift`, `AnalyticsViewModel.swift`
- Key files: `MainViewModel.swift` (manages daily data), `AnalyticsViewModel.swift` (manages analytics loading)

**HealthTracker/Extensions:**
- Purpose: Framework extensions and utilities
- Contains: `View+Extensions.swift`
- Key files: `View+Extensions.swift` (includes `onFirstAppear` modifier)

**HealthTrackerTests/**
- Purpose: Unit and integration tests
- Contains: Test files mirroring source structure, mocks, test helpers
- Key files: Tests organized by layer (Domain/, Data/, Presentation/)

## Key File Locations

**Entry Points:**
- `HealthTracker/HealthTrackerApp.swift`: @main entry point, runs migrations, creates TabView

**Configuration:**
- `HealthTracker/Info.plist`: App metadata and settings
- `HealthTracker/HealthTracker.entitlements`: iCloud capability declarations
- `HealthTracker.xcodeproj/project.pbxproj`: Xcode build settings

**Core Logic:**
- `HealthTracker/Domain/Entities/DayData.swift`: Aggregate root entity with health status computation
- `HealthTracker/Domain/UseCases/SaveDayDataUseCase.swift`: Persistence orchestration
- `HealthTracker/Data/Repositories/HealthDataRepository.swift`: Data access coordination

**Testing:**
- `HealthTrackerTests/Mocks/`: Test doubles for repositories and data sources
- `HealthTrackerTests/TestHelpers/`: Shared test utilities

## Naming Conventions

**Files:**
- Pattern: PascalCase with descriptive suffixes
- Examples: `MainViewModel.swift`, `HealthDataRepository.swift`, `LoadDayDataUseCase.swift`, `View+Extensions.swift`
- Views: `[Name]View.swift` (MainView, AnalyticsView)
- ViewModels: `[Name]ViewModel.swift`
- Use Cases: `[Verb][Noun]UseCase.swift`
- Protocols: `[Name]Protocol.swift` or `[Name]` (e.g., `LocalDataSourceProtocol`)
- Extensions: `[Type]+Extensions.swift`

**Directories:**
- Pattern: PascalCase, plural for collections
- Examples: `Entities/`, `UseCases/`, `ViewModels/`, `Components/`, `Charts/`

## Where to Add New Code

**New Feature:**
- Primary code: Start with domain entity in `HealthTracker/Domain/Entities/`, then use case in `HealthTracker/Domain/UseCases/`, then ViewModel in `HealthTracker/Presentation/ViewModels/`, finally View in `HealthTracker/Presentation/Views/`
- Tests: Mirror structure in `HealthTrackerTests/Domain/`, `HealthTrackerTests/Presentation/`

**New Domain Entity:**
- Implementation: `HealthTracker/Domain/Entities/[EntityName].swift`
- Tests: `HealthTrackerTests/Domain/Entities/[EntityName]Tests.swift`
- Pattern: Struct with Codable, Equatable, Identifiable conformance

**New Use Case:**
- Implementation: `HealthTracker/Domain/UseCases/[Action][Entity]UseCase.swift`
- Tests: `HealthTrackerTests/Domain/UseCases/[Action][Entity]UseCaseTests.swift`
- Pattern: Final class with repository dependency, `execute()` method

**New View Component:**
- Simple component: `HealthTracker/Presentation/Views/Components/[ComponentName].swift`
- Chart component: `HealthTracker/Presentation/Views/Components/Charts/[ChartName]Chart.swift`
- Full screen: `HealthTracker/Presentation/Views/[Name]View.swift`

**New ViewModel:**
- Implementation: `HealthTracker/Presentation/ViewModels/[Name]ViewModel.swift`
- Tests: `HealthTrackerTests/Presentation/ViewModels/[Name]ViewModelTests.swift`
- Pattern: @Observable final class with use case dependencies, convenience init with defaults

**New Data Source:**
- Implementation: `HealthTracker/Data/DataSources/[Source]DataSource.swift`
- Tests: `HealthTrackerTests/Data/DataSources/[Source]DataSourceTests.swift`
- Pattern: Conform to `LocalDataSourceProtocol`, implement `load()` and `save()`

**Utilities:**
- Shared helpers: `HealthTracker/Extensions/[Type]+Extensions.swift`
- View extensions: `HealthTracker/Extensions/View+Extensions.swift`

## Special Directories

**HealthTracker.xcodeproj:**
- Purpose: Xcode project configuration
- Generated: No (manually maintained)
- Committed: Yes (required for building)

**HealthTracker.xcodeproj/xcuserdata:**
- Purpose: User-specific Xcode settings (breakpoints, window positions)
- Generated: Yes (by Xcode)
- Committed: No (.gitignore'd)

**Assets.xcassets:**
- Purpose: App icons, images, color assets
- Generated: Partially (by Xcode asset catalog)
- Committed: Yes

**.planning/codebase:**
- Purpose: GSD codebase analysis documents
- Generated: Yes (by /gsd:map-codebase)
- Committed: Yes (used by other GSD commands)

**.claude:**
- Purpose: Claude Code configuration and GSD framework
- Generated: Yes (by Claude Code)
- Committed: Yes (contains commands and agents)

**.serena:**
- Purpose: AI agent memory/cache (different AI tool)
- Generated: Yes
- Committed: No (.gitignore'd)

---

*Structure analysis: 2026-02-26*
