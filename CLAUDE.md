# Project: Health Tracker iOS Mobile App

HealthTracker is a modern iOS 26.0 health tracking app built with SwiftUI and Swift 6. The app helps users monitor and analyze daily habits including meals, water intake, workouts, and mood. It uses a Clean Architecture approach with clear separation between Domain, Data, and Presentation layers.

## Technology Stack

- **Language**: Swift 6
- **UI Framework**: SwiftUI with iOS 26+ Liquid Glass effects
- **Target**: iOS 26.0+
- **Architecture**: Clean Architecture (Domain/Data/Presentation)
- **Persistence**: iCloud Drive (JSON file) with local Documents fallback; migrated from UserDefaults
- **State Management**: @Observable macro

## Build System Notes

- The project uses `PBXFileSystemSynchronizedRootGroup`, so deleting files auto-removes them from the build — no `project.pbxproj` edits needed.
- If an Xcode MCP tool fails because Xcode is not open, open the project first with `open HealthTracker.xcodeproj`, then retry the tool.

### Using CLI Commands (if Xcode MCP doesn't work)

#### Building

Build the project
```bash
xcodebuild -project HealthTracker.xcodeproj -scheme HealthTracker -configuration Debug build | xcbeautify
```

Build for testing only (compiles tests without running them):
```bash
xcodebuild build-for-testing -project HealthTracker.xcodeproj -scheme HealthTracker | xcbeautify
```

#### Running Tests

Identify possible simulator ids
```bash
xcrun simctl list devices
```

Run all tests
```bash
xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,id=<simulator-id>' | xcbeautify
```

Run specific test file or test
```bash
xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,id=<simulator-id>' -only-testing:HealthTrackerTests/DayDataTests | xcbeautify
xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,id=<simulator-id>' -only-testing:HealthTrackerUITests/CalendarUITests/testTodaySelectedOnLaunchAndEmptyStates | xcbeautify
```

Run all Unit tests (fast)
```bash
xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,id=<simulator-id>' -only-testing:HealthTrackerTests | xcbeautify
```

Run all UI tests (slow — each test launches the app on a simulator)
```bash
xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,id=<simulator-id>' -only-testing:HealthTrackerUITests | xcbeautify
```

Run with coverage report
```bash
xcodebuild test -scheme HealthTracker -enableCodeCoverage YES -derivedDataPath ./DerivedData
```
View coverage report (after running with coverage)
Open: ./DerivedData/Logs/Test/*.xcresult in Xcode

## Repo Map

| Path | Purpose |
|------|---------|
| `HealthTracker/HealthTrackerApp.swift` | App entry point; wires dependencies and bootstraps the app |
| `HealthTracker/UITestingSupport.swift` | `-uiTesting` launch-argument hook: temp-dir repository, skips migration and permission prompts |
| `HealthTracker/Domain/Entities/` | Core business models: `DayData`, `Meal`, `Workout`, `Mood` |
| `HealthTracker/Domain/Protocols/` | Abstract interfaces for repository, notifications, and logging |
| `HealthTracker/Domain/UseCases/` | Business operations: load/save data, manage notifications |
| `HealthTracker/Data/DataSources/` | Storage drivers: `ICloudDriveDataSource` (default), `UserDefaultsDataSource` (legacy) |
| `HealthTracker/Data/Repositories/` | `HealthDataRepository` — orchestrates data sources behind the domain protocol |
| `HealthTracker/Data/Models/` | DTOs: `DayDataContainer` (Codable JSON wrapper) |
| `HealthTracker/Data/Migration/` | One-time migrations: UserDefaults → iCloud, workout duration format |
| `HealthTracker/Data/Services/` | Platform services: notifications (`NotificationService`), logging (`OSLogLogger`) |
| `HealthTracker/Presentation/ViewModels/` | `MainViewModel` — state management via `@Observable` |
| `HealthTracker/Presentation/AccessibilityID.swift` | Accessibility identifiers for UI testing (source of truth; mirrored in the UITests target) |
| `HealthTracker/Presentation/Views/` | `MainView` (daily tracking), `AddEditModal` |
| `HealthTracker/Presentation/Views/Components/` | Reusable UI: `CardView`, `CardListView`, `CalendarStrip` |
| `HealthTracker/Extensions/` | SwiftUI `View` helpers |
| `HealthTracker/Resources/` | Localizable strings for `en` and `pt-BR` |
| `HealthTrackerTests/Domain/` | Unit tests for entities and use cases |
| `HealthTrackerTests/Data/` | Tests for repository, data sources, migration, and models |
| `HealthTrackerTests/Presentation/ViewModels/` | ViewModel unit tests |
| `HealthTrackerTests/Mocks/` | Protocol-backed test doubles |
| `HealthTrackerTests/TestHelpers/` | `TestDataBuilder` — factory for test fixtures |
| `HealthTrackerUITests/` | XCUITest suites: `MealFlowUITests`, `WorkoutFlowUITests`, `WaterMoodUITests`, `CalendarUITests` |
| `HealthTrackerUITests/Support/` | `HealthTrackerUITestCase` (base class + flow helpers), `AccessibilityID` mirror, `EnglishLabel` |
| `HealthTracker.xcodeproj/` | Xcode project configuration |
| `docs/` | Project documentation |

## Data Migrations

- Any change that alters the persisted JSON structure (renaming/removing/retyping a field, changing an encoding format, restructuring `DayData`/`Meal`/`Workout`/`Mood` or `DayDataContainer`) must consider adding a migration in `HealthTracker/Data/Migration/DataMigration.swift`.
- Follow the existing pattern: a private migration function guarded by its own `UserDefaults` completion flag, called from `migrateIfNeeded()`.
- The goal is that existing users' JSON files on disk/iCloud upgrade cleanly without data loss or breaking the app on launch.

## Task Workflow Rules (You MUST follow **always**)

Before writing any code:
1. State how you will verify this change works (tests, bash command, etc.)
2. Write the test on verification step first (unit tests and/or ui tests)
3. Then implement the code
4. Run verification and iterate until it passes

- Always finish a task in a way that the system is not broken and able to commit
- Write tests to achieve near-total test coverage
- Every public function, code file, edge case should have a corresponding test
- Run the full test suite before considering any task complete
- All tests must pass clean. Do not commit code that breaks tests or the build
- If we have a plan, follow it accordingly
- For every bug fix, create a regression test to ensure the same error doesn't reappear

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

## Worktrees

- Create git worktrees at the root directory inside `.worktrees/` (e.g. `.worktrees/<branch-name>`)
- Only create a worktree when the task clearly requires it or the user explicitly requests it

## Do Not

- Commit without running code quality and tests
- Commit on the `main` branch without the user asking for it or confirming first

## Code Quality

Lint Swift code and apply fixes for autocorrectable rules (run after editing)
```bash
swiftlint --fix && swiftlint
```

Format Swift code (run after editing)
```bash
swiftformat . --swift-version 6
```
