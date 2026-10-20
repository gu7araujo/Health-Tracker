# Project: Health Tracker iOS Mobile App

HealthTracker is a modern iOS 26.0 health tracking app built with SwiftUI and Swift 6. The app helps users monitor and analyze daily habits including meals, water intake, workouts, and mood. It uses a Clean Architecture approach with clear separation between Domain, Data, and Presentation layers.

## Repo Map

Deep maps + layer rules: `HealthTracker/Domain/AGENTS.md`, `HealthTracker/Data/AGENTS.md`,
`HealthTracker/Presentation/AGENTS.md`, `HealthTrackerTests/AGENTS.md`, `HealthTrackerUITests/AGENTS.md`

- `HealthTracker/UITestingSupport.swift` — the `-uiTesting` launch-argument hook: temp-dir repository, skips migration and permission prompts.
- `HealthTracker/Resources/` — localizable strings for `en` and `pt-BR`.

## Apple Documentation

For current, version-accurate Apple API docs (especially fast-moving iOS 26 APIs like Liquid Glass), use the Xcode MCP `DocumentationSearch` tool instead of relying on your trainning memory. Pass a `query` and optionally scope with `frameworks` (e.g. `["SwiftUI"]`); it returns ranked symbols and articles with signatures and code examples.

## Workflow

The core loop is **red → green**: write a failing test, then make it pass. Follow it always: TDD skill.

1. Before coding, state how you'll verify the change — which unit/UI test, which bash command, screenshot, skill, or tool, etc.
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
- Build, test, and preview through the Xcode MCP tools — from a worktree too (see [Worktrees](#worktrees)).
- When the Xcode MCP tools are unavailable or failing, fall back to `xcodebuild`:
    - **Building** the app or compiling the test target: `cli-build` skill.
    - **Running** unit/UI tests and reading the coverage report: `cli-test` skill.

## Validating Work

- After a UI change or adding a new UI element, validate it by rendering its SwiftUI `#Preview` with the Xcode MCP `RenderPreview` tool and reviewing the snapshot (check light/dark and a large Dynamic Type size). If the view has no `#Preview`, add one first.
- To validate logic or understand how code behaves without editing files or writing a test, run a `print`-based snippet in a source file's context with the Xcode MCP `RunCodeSnippet` tool (e.g. construct a `DayData` and print its `status`).

## Worktrees

- Create git worktrees inside `.claude/worktrees/` (e.g. `.claude/worktrees/<branch-name>`) — the one location Claude Code's worktree tools can switch a session between.
- Only create a worktree when the task clearly requires it or the user explicitly requests it

### Parallel agents

One agent per worktree; a single running Xcode serves every worktree's Xcode MCP calls concurrently, so parallel agents stay on the MCP.

1. **Open your worktree's project first:** `XcodeOpenWorkspace` with the absolute path `<worktree>/HealthTracker.xcodeproj`. Done when it returns a `workspaceIdentifier`. Xcode rejects tool calls for a project it hasn't opened ("Unknown workspace identifier"), and a new agent's first open asks the user to approve it in Xcode.
2. **Pass that `workspaceIdentifier` on every Xcode MCP call.** The main checkout and each worktree are all open as `HealthTracker.xcodeproj`; the identifier is what keeps a build or test on your branch.
3. **Build and run unit tests freely** (`BuildProject`, `RunSomeTests` on `HealthTrackerTests`): each worktree builds into its own DerivedData.
4. **Run UI tests from one agent at a time** — `HealthTrackerUITests`, and `RunAllTests`, which includes them. Concurrent runs share Xcode's simulator-clone pool: when one run finishes, the other's clones get torn down and rebuilt, stretching a ~4 min suite past 15 min or stalling it outright, even with each worktree on its own run destination. Iterate on unit tests; run the full suite once at the end.
5. **Read results from the tool response** (pass/fail counts, errors) or `GetBuildLog` with your `workspaceIdentifier`. The artifact files it points to (`fullLogPath`, test console logs, `.xcresult`) are named by timestamp and overwritten when two runs finish in the same second.
6. **Stop what you abandon:** a run keeps going inside Xcode after its caller gives up and blocks the next one ("There is already a test running"). `StopProject` with your `workspaceIdentifier` clears it; do the same for a test run with no result after ~15 min.

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

## Committing

- Run code quality (`swiftlint`, `swiftformat`) and the full test suite before every commit; never commit a broken build or failing tests.
- On `main`, branch first — commit there only when the user asks or confirms.
