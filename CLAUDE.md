# Project: Health Tracker iOS Mobile App

HealthTracker is a modern iOS 26.0 health tracking app built with SwiftUI and Swift 6. The app helps users monitor and analyze daily habits including meals, water intake, workouts, and mood. It uses a Clean Architecture approach with clear separation between Domain, Data, and Presentation layers.

## Repo Map

| Path | Purpose |
|------|---------|
| `HealthTracker/HealthTrackerApp.swift` | App entry point; wires dependencies and bootstraps the app |
| `HealthTracker/UITestingSupport.swift` | `-uiTesting` launch-argument hook: temp-dir repository, skips migration and permission prompts |
| `HealthTracker/Domain/` | Business core: entities, repository/notification/logging protocols, use cases. Owns the health-status rules. **Deep map + rules: `HealthTracker/Domain/CLAUDE.md`** |
| `HealthTracker/Data/` | Persistence + platform services: data sources, repository, DTOs, migrations, notifications, logging. **Deep map + rules: `HealthTracker/Data/CLAUDE.md`** |
| `HealthTracker/Presentation/` | SwiftUI UI: `MainViewModel` (`@Observable` state owner), `MainView` + stateless section views, `AddEditModal`, reusable Liquid Glass components, accessibility IDs. Owns UI localization. **Deep map + rules: `HealthTracker/Presentation/CLAUDE.md`** |
| `HealthTracker/Extensions/` | SwiftUI `View` helpers |
| `HealthTracker/Resources/` | Localizable strings for `en` and `pt-BR` |
| `HealthTrackerTests/` | Swift Testing unit suite mirroring the three layers, plus shared `Mocks/` and `TestDataBuilder`. **Deep map + rules: `HealthTrackerTests/CLAUDE.md`** |
| `HealthTrackerUITests/` | XCUITest end-to-end suites driving the app on a simulator, plus the `Support/` base class, flow helpers, and mirrored identifiers. **Deep map + rules: `HealthTrackerUITests/CLAUDE.md`** |
| `HealthTracker.xcodeproj/` | Xcode project configuration |

## Apple Documentation

For current, version-accurate Apple API docs (especially fast-moving iOS 26 APIs like Liquid Glass), use the Xcode MCP `DocumentationSearch` tool instead of relying on your trainning memory. Pass a `query` and optionally scope with `frameworks` (e.g. `["SwiftUI"]`); it returns ranked symbols and articles with signatures and code examples.

## Technology Stack

- **Language**: Swift 6
- **UI Framework**: SwiftUI with iOS 26+ Liquid Glass effects
- **Target**: iOS 26.0+
- **Architecture**: Clean Architecture (Domain/Data/Presentation)
- **Persistence**: iCloud Drive (JSON file) with local Documents fallback; migrated from UserDefaults
- **State Management**: @Observable macro

## Workflow

The core loop is **red → green**: write a failing test, then make it pass. Follow it always.

1. Before coding, state how you'll verify the change — which unit/UI test, which bash command, or screenshot, etc.
2. Write that test first and watch it fail (**red**).
3. Implement the minimum code to pass it (**green**).
4. Run the full suite and iterate until it passes clean — that's the bar for a task being done.

Every bug fix starts with a regression test that reproduces the bug. Aim for near-total coverage: every public function, file, and edge case earns a test. Prefer Xcode MCP tools when they fit, and follow the plan when we have one.

Keep every change **tight**:

- **Think first.** State assumptions explicitly. When multiple interpretations or a simpler approach exist, surface them and ask — don't pick silently.
- **Simplest thing that works.** Minimum code, nothing speculative: skip unrequested abstractions, configurability, and error handling for impossible cases. If 200 lines could be 50, rewrite.
- **Surgical.** Every changed line traces to the request. Match surrounding style, leave adjacent code alone, and remove only the orphans your own change creates. Flag unrelated dead code rather than deleting it.

Leave the system committable — build green, tests passing.

## Building Systems

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

Run all Unit tests (fast)
```bash
xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,id=<simulator-id>' -only-testing:HealthTrackerTests | xcbeautify
```

Run all UI tests (slow — each test launches the app on a simulator)
```bash
xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,id=<simulator-id>' -only-testing:HealthTrackerUITests | xcbeautify
```

Run specific test file or test
```bash
xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,id=<simulator-id>' -only-testing:HealthTrackerTests/DayDataTests | xcbeautify
xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,id=<simulator-id>' -only-testing:HealthTrackerUITests/CalendarUITests/testTodaySelectedOnLaunchAndEmptyStates | xcbeautify
```

Run with coverage report
```bash
xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,id=<simulator-id>' -enableCodeCoverage YES -resultBundlePath build/Test.xcresult | xcbeautify
```

View the coverage report from the command line (after running with `-resultBundlePath`):
```bash
# Per-file line-coverage table (human-readable)
xcrun xccov view --report build/Test.xcresult

# Machine-readable JSON (per-target/per-file, for scripting)
xcrun xccov view --report --json build/Test.xcresult
```
The JSON exposes each target's `lineCoverage`, `coveredLines`, and `executableLines`, plus a per-file `files` array — sort by `lineCoverage` to find the least-covered files.

## Worktrees

- Create git worktrees at the root directory inside `.worktrees/` (e.g. `.worktrees/<branch-name>`)
- Only create a worktree when the task clearly requires it or the user explicitly requests it

## Validating Work

- After a UI change or adding a new UI element, validate it by rendering its SwiftUI `#Preview` with the Xcode MCP `RenderPreview` tool and reviewing the snapshot (check light/dark and a large Dynamic Type size). If the view has no `#Preview`, add one first.
- To validate logic or understand how code behaves without editing files or writing a test, run a `print`-based snippet in a source file's context with the Xcode MCP `RunCodeSnippet` tool (e.g. construct a `DayData` and print its `status`).

## Code Quality

Lint Swift code and apply fixes for autocorrectable rules (run after editing)
```bash
swiftlint --fix && swiftlint
```

Format Swift code (run after editing)
```bash
swiftformat . --swift-version 6
```

## Data Migrations

- Any change that alters the persisted JSON structure (renaming/removing/retyping a field, changing an encoding format, restructuring `DayData`/`Meal`/`Workout`/`Mood` or `DayDataContainer`) must consider adding a migration in `HealthTracker/Data/Migration/DataMigration.swift`.
- Follow the existing pattern: a private migration function guarded by its own `UserDefaults` completion flag, called from `migrateIfNeeded()`.
- The goal is that existing users' JSON files on disk/iCloud upgrade cleanly without data loss or breaking the app on launch.

## RocketSim Automation Notes

Findings from driving the app via the `rocketsim` CLI/skill in the Simulator. These are quirks of this app's UI + RocketSim's accessibility-tree walking, not fixable by adding `.accessibilityLabel`/`.accessibilityIdentifier` — confirmed by testing with and without explicit labels.

- **`CalendarStrip` day cells don't respond to `interact tap`.** `CalendarStripDay` uses a plain `.onTapGesture` (not a `Button`); RocketSim's synthetic tap event isn't recognized by it. Use `interact long-press --duration 0.1` (or similar short duration) on the day cell instead — it reliably selects the day where `tap` silently does nothing (`screen_changed: false`, no error).
- **Calendar day frames are only accurate for the currently-visible page.** The strip is a paged, horizontally-scrolling `LazyHStack`. Days still present in `elements` output but scrolled off-screen (e.g. last week's dates while this week is showing) report bogus/negative-x frames — tapping/long-pressing by id or label on those will miss and silently hit whatever's underneath (observed: landed on the "Monitore sua saúde" heading). Always scroll the target day into the visible viewport first, re-run `elements`, and confirm its frame looks sane (increasing x, positive) before interacting with it.
- **`screen_changed` in interact results is not reliable for this app.** It frequently reports `false` even when the UI visibly changed (day selection, scroll position). Don't gate follow-up logic on it — verify state via a fresh `elements --agent --agent-mode act` read (check for `,selected` on the target) or a screenshot instead.
- **Meal/Workout card swipe-actions (Editar/Excluir) could not be revealed via synthetic `interact swipe`** on the card, across several distances/durations tried. If you need to edit or delete an existing meal/workout entry through RocketSim, this path is currently blocked — no workaround found yet.
- **RocketSim does not expose `accessibilityIdentifier` at all** — its element schema is only `{frame, traits, state, label, value, id, role, stableKey}`, and `--label`/`--type`/`--value` selectors match against the accessibility *label* (usually inferred from visible text via `.accessibilityElement(children: .combine)`), never the identifier. This mostly works fine here since visible text doubles as a usable label, but icon-only controls with an identifier and no visible text/explicit `.accessibilityLabel` will show up with a blank label — target those by `--id` (re-resolved per snapshot) or raw coordinates instead.

## Committing

- Run code quality (`swiftlint`, `swiftformat`) and the full test suite before every commit; never commit a broken build or failing tests.
- On `main`, branch first — commit there only when the user asks or confirms.
