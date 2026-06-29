# Project: Health Tracker iOS Mobile App

HealthTracker is a modern iOS 26.0 health tracking app built with SwiftUI and Swift 6. The app helps users monitor and analyze daily habits including meals, water intake, workouts, and mood with comprehensive charts, insights, and trend visualizations. It uses a Clean Architecture approach with clear separation between Domain, Data, and Presentation layers.

## Technology Stack

- **Language**: Swift 6
- **UI Framework**: SwiftUI with iOS 26+ Liquid Glass effects
- **Charts**: Swift Charts (native iOS 16+)
- **Target**: iOS 26.0+
- **Architecture**: Clean Architecture (Domain/Data/Presentation)
- **Persistence**: iCloud Drive (JSON file) with local Documents fallback; migrated from UserDefaults
- **State Management**: @Observable macro

## Repo Map

| Path | Purpose |
|------|---------|
| `HealthTracker/HealthTrackerApp.swift` | App entry point; wires dependencies and bootstraps the app |
| `HealthTracker/Domain/Entities/` | Core business models: `DayData`, `Meal`, `Workout`, `Mood`, analytics types |
| `HealthTracker/Domain/Protocols/` | Abstract interfaces for repository, notifications, and logging |
| `HealthTracker/Domain/UseCases/` | Business operations: load/save data, calculate analytics, manage notifications |
| `HealthTracker/Data/DataSources/` | Storage drivers: `ICloudDriveDataSource` (default), `UserDefaultsDataSource` (legacy) |
| `HealthTracker/Data/Repositories/` | `HealthDataRepository` — orchestrates data sources behind the domain protocol |
| `HealthTracker/Data/Models/` | DTOs: `DayDataContainer` (Codable JSON wrapper) |
| `HealthTracker/Data/Migration/` | One-time migrations: UserDefaults → iCloud, workout duration format |
| `HealthTracker/Data/Services/` | Platform services: notifications (`NotificationService`), logging (`OSLogLogger`) |
| `HealthTracker/Presentation/ViewModels/` | `MainViewModel`, `AnalyticsViewModel` — state management via `@Observable` |
| `HealthTracker/Presentation/Views/` | `MainView` (daily tracking), `AnalyticsView` (charts & insights), `AddEditModal` |
| `HealthTracker/Presentation/Views/Components/` | Reusable UI: `CardView`, `CardListView`, `CalendarStrip`, `PeriodSelector` |
| `HealthTracker/Presentation/Views/Components/Charts/` | Swift Charts views: water, workouts, mood, meals, overall health ring |
| `HealthTracker/Extensions/` | SwiftUI `View` helpers |
| `HealthTracker/Resources/` | Localizable strings for `en` and `pt-BR` |
| `HealthTrackerTests/Domain/` | Unit tests for entities and use cases |
| `HealthTrackerTests/Data/` | Tests for repository, data sources, migration, and models |
| `HealthTrackerTests/Presentation/ViewModels/` | ViewModel unit tests |
| `HealthTrackerTests/Mocks/` | Protocol-backed test doubles |
| `HealthTrackerTests/TestHelpers/` | `TestDataBuilder` — factory for test fixtures |
| `HealthTracker.xcodeproj/` | Xcode project configuration |
| `docs/` | Project documentation |

## Task Workflow Rules (You MUST follow **always**)

Before writing any code:
1. State how you will verify this change works (test, bash command, etc.)
2. Write the test on verification step first
3. Then implement the code
4. Run verification and iterate until it passes

- Always finish a task in a way that the system is not broken and able to commit
- Write tests to achieve near-total test coverage
- Every public function, code file, edge case should have a corresponding test
- Run the full test suite before considering any task complete
- All tests must pass clean. Do not commit code that breaks tests or the build
- If we have a plan, follow it accordingly

### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## Do Not

- Commit without running code quality and tests

## Code Quality

Lint Swift code and apply fixes for autocorrectable rules (run after editing)
```bash
swiftlint --fix && swiftlint
```

Format Swift code (run after editing)
```bash
swiftformat . --swift-version 6
```
