# Health-Tracker Project Overview

## Purpose
HealthTracker is a modern Swift 6 / iOS 26.0 user-focused, distraction-free app designed to help monitor healthy habits through pre-defined tracking points:
- **Meals** - Track food intake with quantity and satisfaction levels
- **Water** - Monitor daily water consumption (in liters)
- **Workouts** - Log exercises with duration
- **Mood** - Record daily emotional state

## Tech Stack
- **Language**: Swift 6
- **Platform**: iOS 26.0
- **UI Framework**: SwiftUI
- **State Management**: `@Observable` macro (Observation framework)
- **Persistence**: UserDefaults (via `UserDefaultsDataSource`)
- **Architecture**: Clean Architecture with MVVM presentation layer

## Project Structure
```
HealthTracker/HealthTracker/
├── Domain/                    # Pure Swift - business logic
│   ├── Entities/              # DayData, Meal, Mood, Workout
│   ├── Protocols/             # HealthDataRepositoryProtocol
│   └── UseCases/              # LoadDayDataUseCase, SaveDayDataUseCase
├── Data/                      # Implementation layer
│   ├── DataSources/           # UserDefaultsDataSource
│   └── Repositories/          # HealthDataRepository
├── Presentation/              # UI layer
│   ├── ViewModels/            # MainViewModel
│   └── Views/                 # MainView, AddEditModal, Components/
├── Extensions/                # View+Extensions
└── HealthTrackerApp.swift     # App entry point
```

## Key Files
| File | Purpose |
|------|---------|
| `HealthTrackerApp.swift` | App entry point (`@main`) |
| `MainView.swift` | Primary UI with calendar, meals, water, workouts, mood sections |
| `MainViewModel.swift` | Business logic coordinator using `@Observable` |
| `DayData.swift` | Core entity aggregating daily health data |
| `HealthDataRepository.swift` | Implements persistence via UserDefaults |

## Author
Gustavo Araujo Santos
