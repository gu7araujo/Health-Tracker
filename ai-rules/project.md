# Project Context

## Product Overview

HealthTracker is a minimalist iOS app for daily health habit monitoring. Users track **meals**, **water intake**, **workouts**, and **mood** — with automatic status evaluation (optimal/moderate/poor) based on predefined healthy criteria.

### Core Value Proposition
- Distraction-free tracking focused on essentials
- Visual daily status feedback via calendar strip
- No account required — local-first persistence

### Target Audience
- Health-conscious individuals wanting simple habit tracking
- Portuguese-speaking users (UI is in pt-BR)

---

## Architecture

The project follows **Clean Architecture** with three distinct layers:

```
┌─────────────────────────────────────────────────────────────┐
│  Presentation Layer (Views + ViewModels)                    │
│  - SwiftUI Views, @Observable ViewModels                    │
├─────────────────────────────────────────────────────────────┤
│  Domain Layer (Entities + Use Cases + Protocols)            │
│  - Business logic, pure Swift types                         │
├─────────────────────────────────────────────────────────────┤
│  Data Layer (Repositories + DataSources)                    │
│  - Persistence implementation (UserDefaults)                │
└─────────────────────────────────────────────────────────────┘
```

**Dependency Rule**: Inner layers know nothing about outer layers. Domain defines protocols; Data implements them.

---

## Folder Structure

```
HealthTracker/
└── HealthTracker/
    ├── HealthTrackerApp.swift         # App entry point (@main)
    │
    ├── Domain/                        # Business logic layer
    │   ├── Entities/                  # Core data models
    │   │   ├── DayData.swift          # Aggregate root for daily tracking
    │   │   ├── DayStatus.swift        # Status enum (optimal/moderate/poor/incomplete/noData)
    │   │   ├── Meal.swift             # Meal with quantity + satisfaction
    │   │   ├── Mood.swift             # User mood (good/neutral/sad)
    │   │   └── Workout.swift          # Workout with duration
    │   │
    │   ├── Protocols/                 # Abstractions for dependency inversion
    │   │   └── HealthDataRepositoryProtocol.swift
    │   │
    │   └── UseCases/                  # Application-specific business rules
    │       ├── LoadDayDataUseCase.swift
    │       └── SaveDayDataUseCase.swift
    │
    ├── Data/                          # Data access layer
    │   ├── DataSources/
    │   │   └── UserDefaultsDataSource.swift  # Low-level storage access
    │   └── Repositories/
    │       └── HealthDataRepository.swift    # Protocol implementation
    │
    ├── Presentation/                  # UI layer
    │   ├── ViewModels/
    │   │   └── MainViewModel.swift    # @Observable, coordinates use cases
    │   └── Views/
    │       ├── MainView.swift         # Primary screen
    │       ├── AddEditModal.swift     # Meal/Workout entry modal
    │       └── Components/            # Reusable UI components
    │           ├── CalendarStrip.swift    # Horizontal date picker with status dots
    │           ├── CardListView.swift     # Horizontal scrollable card container
    │           ├── CardView.swift         # Glass-effect card wrapper
    │           └── HeaderListView.swift   # Section header with action button
    │
    ├── Extensions/
    │   └── View+Extensions.swift      # SwiftUI view helpers (e.g., onFirstAppear)
    │
    └── Assets.xcassets/               # App icons, colors
```

---

## Key Domain Concepts

### DayData (Aggregate Root)
Central entity representing all health data for a single day:
- `meals: [Meal]` — food entries with quantity and satisfaction
- `workouts: [Workout]` — exercise entries with duration
- `water: Double?` — liters consumed
- `mood: Mood?` — emotional state
- `status: DayStatus` — computed property evaluating day health

### DayStatus Calculation
The app evaluates daily health based on these rules:

| Status | Criteria |
|--------|----------|
| **Optimal** (green) | All: small meals + 50% satiety, water ≥ 1.8L, has workout, good mood |
| **Moderate** (yellow) | Any: 1-2 medium meals + 80% satiety, OR water 1.0-1.7L, OR neutral mood |
| **Poor** (red) | Has data but doesn't meet optimal/moderate |
| **Incomplete** | Only 1-2 of 4 categories have data |
| **No Data** | Nothing recorded |

### Entity Enums
- **Meal.Quantity**: verySmall, small, medium, large
- **Meal.Satisfaction**: thirty, fifty, eighty, hundred (percentage)
- **Workout.Duration**: fifteenMin, thirtyMin, oneHour, oneHourThirty
- **Mood**: good, neutral, sad

---

## Data Flow

```
User Action → View → ViewModel → UseCase → Repository → DataSource → UserDefaults
                ↑                                              │
                └──────────────────────────────────────────────┘
                              (data loads back)
```

1. **MainViewModel** holds `days: [DayData]` and `selectedDate`
2. User interactions call ViewModel methods (e.g., `addMeal`, `updateWater`)
3. ViewModel mutates state and calls `SaveDayDataUseCase`
4. Repository persists via `UserDefaultsDataSource`
5. On app launch, `LoadDayDataUseCase` hydrates state

---

## UI Structure

### MainView Sections
1. **CalendarStrip** — horizontal date selector with colored status dots
2. **Meals Section** — horizontal card scroll, double-tap for edit/delete
3. **Water Section** — stepper for 0.1L increments (0-10L range)
4. **Workouts Section** — horizontal card scroll, double-tap for edit/delete
5. **Mood Section** — three mood buttons with selection highlight

### Navigation
- Single-screen app with sheet modals for add/edit
- No deep navigation hierarchy

---

## Technical Details

### Dependencies
- Pure SwiftUI (no external packages)
- UserDefaults for persistence (JSON-encoded `[DayData]`)

### Concurrency Model
- Synchronous persistence (UserDefaults)
- `@Observable` macro for state management (iOS 17+)
- No async/await currently needed

### Localization
- UI strings are in Brazilian Portuguese (pt-BR)
- Entity display names use `localizedName` computed properties

---

## Key Files Quick Reference

| File | Purpose |
|------|---------|
| `HealthTrackerApp.swift` | App entry, creates `MainView` |
| `DayData.swift` | Core aggregate with status calculation logic |
| `MainViewModel.swift` | Coordinates all user actions and state |
| `MainView.swift` | Primary UI with all sections |
| `HealthDataRepository.swift` | Persistence implementation |
| `CalendarStrip.swift` | Visual date picker with status indicators |

---

## Future Considerations

When extending the app, consider:
- **New tracking categories**: Add to `DayData` and update status calculation
- **Persistence migration**: Current UserDefaults approach may need Core Data for complex queries
- **Async operations**: If adding network sync, use Swift Concurrency patterns per skill guide
