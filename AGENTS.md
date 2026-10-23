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
4. Run `scripts/quality --full` and iterate until it exits 0 — that's the bar for a task being done (see [Quality Gates](#quality-gates)).

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
    - **Running** unit/UI tests: `cli-test` skill. Coverage: `quality-gate` skill.

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
4. **Run UI tests through the MCP from one agent at a time** — `HealthTrackerUITests`, and `RunAllTests`, which includes them. Concurrent runs share Xcode's simulator-clone pool: when one run finishes, the other's clones get torn down and rebuilt, stretching a ~4 min suite past 15 min or stalling it outright, even with each worktree on its own run destination. Iterate on unit tests; run the full suite once at the end.
5. **Read results from the tool response** (pass/fail counts, errors) or `GetBuildLog` with your `workspaceIdentifier`. The artifact files it points to (`fullLogPath`, test console logs, `.xcresult`) are named by timestamp and overwritten when two runs finish in the same second.
6. **On the `xcodebuild` fallback, test on a simulator of your own** — the `cli-test` skill's parallel setup. Isolated from the shared clone pool, UI tests can run in parallel there; for ad-hoc `xcodebuild` runs leave `-derivedDataPath` at its default, which already separates worktrees by path (`scripts/quality` always builds into its own `build/DerivedData`).
7. **Stop what you abandon:** a run keeps going inside Xcode after its caller gives up and blocks the next one ("There is already a test running"). `StopProject` with your `workspaceIdentifier` clears it; do the same for a test run with no result after ~15 min.

## Quality Gates

`scripts/quality` is the one gate: it prints a pass/fail table and exits 0 only when every gate passes. Reading its output, chasing coverage, and fixing a red gate: `quality-gate` skill.

- Run `scripts/bootstrap` once per clone: it installs the git hooks and checks tool versions.
- Iterate with `scripts/quality --fast` (format, lint, fitness, unit tests, unused code, Domain/Data line and region coverage).
- The Domain/Data ratchets measure line and region coverage. A region is a code path inside a line (the default of `?? 0`, one side of `&&`), so a line counts as covered while one of its regions never ran. Lowering any ratchet is the user's call (below).
- The Unused code gate runs Periphery (`.periphery.yml`, strict, no baseline) on the index of the gate's own test build (`build/DerivedData`) and fails on any unused declaration.
- The Fitness gate (`scripts/fitness/run`) checks the cross-file rules linked from the layer `AGENTS.md` files (localization parity, test mirror, UI-test accessibility IDs); pre-commit and CI `lint` run it too.
- A task is **done** when `scripts/quality --full` exits 0. Paste its gate table in your final report and PR.
- Fix a red gate in code or tests. Lowering a threshold, editing `scripts/coverage-exceptions.txt` or `scripts/fitness/test-mirror-exceptions.txt`, or adding a `swiftlint:disable` or `// periphery:ignore` is a decision for the user: call each one out explicitly in the report and PR.
- Lint enforces size/complexity limits and the layer rules as SwiftLint rules (all in `.swiftlint.yml`). `.swiftlint-baseline.json` freezes the pre-existing violations, so only new ones fail. Regenerating the baseline to absorb a new violation is the user's call, like lowering a threshold. Burning one down is fixing it and regenerating the baseline in the same commit, from the repo root (the `jq` keeps paths repo-relative):

  ```bash
  swiftlint lint --quiet --write-baseline .swiftlint-baseline.json
  tmp=$(mktemp) && jq --arg p "file://$PWD/" 'map(.violation.location.file |= ltrimstr($p))' .swiftlint-baseline.json > "$tmp" && mv "$tmp" .swiftlint-baseline.json
  ```
- Each `.swift` file you edit or write is formatted in place and linted by a Claude Code hook; fix the violations it reports.
- The git hooks refuse commits and pushes to `main` and run `--fast` before every push. Let them run: no `--no-verify`, no `SKIP_QUALITY`. The push takes ~2 min, past the Bash tool's 120 s default, so run `git push` with a 600000 ms timeout.
- Open PRs as **draft**. Mark one ready only after a green local `scripts/quality --full`: push, wait until `gh run list --commit "$(git rev-parse HEAD)"` shows the push's run (a push and `gh pr ready` in the same second cancelled the ready run once; a PR touching only docs or agent config gets no run, so stop with the link), then `gh pr ready <n>` and `gh pr checks <n> --watch`. Green: stop there with the link; the user approves and merges every PR. Red: follow the `quality-gate` skill's CI section. Each ready run costs ~11 macOS min, so a PR gets at most **two ready runs** without the user's go-ahead.

**CI** (GitHub Actions, ~200 macOS min/month on the Free plan). The Linux `lint` job runs format, lint, fitness, ShellCheck and actionlint on every PR and push that touches more than docs or agent config. Draft and Dependabot PRs run only `lint`. Ready PRs also run `test` (`scripts/quality --full` on `runs-on: xcode-27`), pushes to `main` run `--fast`, and the weekly schedule runs `--full`. A red check is read and reproduced through the `quality-gate` skill's CI section.

## Data Migrations

- Any change that alters the persisted JSON structure (renaming/removing/retyping a field, changing an encoding format, restructuring `DayData`/`Meal`/`Workout`/`Mood` or `DayDataContainer`) must consider adding a migration in `HealthTracker/Data/Migration/DataMigration.swift`.
- Follow the existing pattern: a private migration function guarded by its own `UserDefaults` completion flag, called from `migrateIfNeeded()`.
- The goal is that existing users' JSON files on disk/iCloud upgrade cleanly without data loss or breaking the app on launch.
- `scripts/fitness/persisted-shape-guard.sh` warns in pre-push and on PRs when a persisted type's shape changes without `Data/Migration/` or `DataMigrationTests` changing. Answer it with a migration, or say in the PR why none is needed.

## Committing

- The pre-push hook runs `scripts/quality --fast`; run `scripts/quality --full` before marking a PR ready. Never push a broken build or failing tests.
- Branch first (`git switch -c <type>/<name>`): the hooks refuse commits on `main`.
- Use the `gh` CLI for GitHub work — pull requests, issues, reviews, checks, releases, API calls.
