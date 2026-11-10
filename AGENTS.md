# Project: Health Tracker iOS Mobile App

HealthTracker is an iOS 26.0 health tracking app built with SwiftUI and Swift 6: it logs meals, water, workouts and mood, and rates each day. Clean Architecture, with Domain, Data and Presentation layers.

## Repo Map

Each area keeps its rules in its own `AGENTS.md`. Claude Code loads it when you first read a file in that directory; read it yourself when you plan a change there or review from a diff.

| Working in | Read |
|---|---|
| `HealthTracker/Domain/` (entities, use cases, the health-status rule) | `HealthTracker/Domain/AGENTS.md` |
| `HealthTracker/Data/` (persistence, migrations) | `HealthTracker/Data/AGENTS.md` |
| `HealthTracker/Presentation/` (SwiftUI, ViewModel, localization) | `HealthTracker/Presentation/AGENTS.md` |
| `HealthTracker/Presentation/Intents/` (App Intents, App Shortcuts) | also `HealthTracker/Presentation/Intents/AGENTS.md` |
| `HealthTrackerTests/` (unit tests, Swift Testing) | `HealthTrackerTests/AGENTS.md` |
| `HealthTrackerUITests/` (XCUITest) | `HealthTrackerUITests/AGENTS.md` |
| `HealthTrackerIntentsUITests/` (intents end to end, iOS 27) | also `HealthTrackerIntentsUITests/AGENTS.md` |
| `scripts/`, `.githooks/`, `.github/` | `scripts/AGENTS.md` |

- `HealthTracker/UITestingSupport.swift` — the `-uiTesting` launch-argument hook: temp-dir repository, skips migration and permission prompts. It also detects the unit-test host (`XCTestConfigurationFilePath`), which skips that startup and renders no `MainView`.
- `HealthTracker/Resources/` — localizable strings for `en` and `pt-BR`, plus `AppShortcuts.strings` (Siri phrases).

## Workflow

The core loop is **red → green**: write a failing test, then make it pass. Follow it always: `tdd` skill.

1. Before coding, state how you'll verify the change with something runnable: a unit or UI test, a bash command, a preview snapshot.
2. Write that test first and watch it fail (**red**). Every bug fix starts with a regression test that reproduces the bug.
3. Implement the minimum code to pass it (**green**). On app or test code, then run the `simplify` skill over the diff.
4. Run `scripts/quality --fast` and iterate until it exits 0, so reviewers only see a diff that already passes the gates.
5. Review the diff in a fresh-context subagent, never in the session that wrote it: `reviewing` skill (passes by risk tier, rounds that converge).
6. Run `scripts/quality --full` (`--fast` for a change touching only docs or agent config) and iterate until it exits 0: the bar for **done** ([Quality Gates](#quality-gates)).

Aim for near-total coverage: every public function, file and edge case earns a test. Follow the plan when we have one.

Keep every change **tight**:

- **Think first.** State assumptions explicitly. When multiple interpretations or a simpler approach exist, surface them and ask.
- **Simplest thing that works.** Minimum code, nothing speculative: skip unrequested abstractions, configurability, and error handling for impossible cases. If 200 lines could be 50, rewrite.
- **Surgical.** Every changed line traces to the request. Match surrounding style, leave adjacent code alone, and remove only the orphans your own change creates. Flag unrelated dead code rather than deleting it.

### Delegating

On a task spanning several files, layers or PRs, the main session is the **orchestrator**: it keeps the plan, the decisions and the thread with the user, and hands subagents any step whose output it needs back only as a conclusion (a broad search, a long build or test log, a review pass, an independent slice of the plan). Work that needs the user's judgement or the conversation's history stays in the main session.

- Run independent slices, or a staged pipeline (implement → review → verify), as a Workflow.
- Brief each subagent as a cold start: the goal, the files, the constraints, its done-criterion, and the shape of the report to return.
- Agents working at the same time each take their own worktree in `.claude/worktrees/<branch-name>`, and at most two of them build or test at once: `parallel-agents` skill. Create a worktree only when the task requires it or the user asks.

## Building and Validating

- Build, test and preview through the Xcode MCP tools. When they are unavailable or failing, fall back to `xcodebuild`: `cli-build` skill to build, `cli-test` skill to run tests.
- Apple API docs: use the Xcode MCP `DocumentationSearch` tool (a `query`, optionally `frameworks`) over training memory, especially for iOS 26 APIs like Liquid Glass.
- After a UI change, render the view's `#Preview` with the Xcode MCP `RenderPreview` tool and review the snapshot in light, dark and a large Dynamic Type size. Add a `#Preview` first when the view has none.
- To see how code behaves without writing a test, run a `print`-based snippet with the Xcode MCP `RunCodeSnippet` tool (e.g. construct a `DayData` and print its `status`).
- The project uses `PBXFileSystemSynchronizedRootGroup`: adding or deleting a source file needs no `project.pbxproj` edit. A file under `HealthTracker/` that must stay out of the app bundle (an `AGENTS.md`) needs a `membershipExceptions` entry there.

## Quality Gates

`scripts/quality` is the one gate: it prints a pass/fail table and exits 0 only when every gate passes. Reading its output, fixing a red gate, chasing coverage, the lint baseline and CI: `quality-gate` skill.

- **Iterate** with `scripts/quality --fast` (format, lint, fitness, unit tests, unused code, Domain/Data coverage).
- **Done** is `scripts/quality --full` exiting 0. A change touching only docs or agent config (the `paths-ignore` paths in `.github/workflows/ci.yml`) is done when `--fast` exits 0. Paste that run's gate table in your final report and PR.
- **Fix a red gate in code or tests.** Lowering a threshold, editing `scripts/coverage-exceptions.txt` or `scripts/fitness/test-mirror-exceptions.txt`, adding a `swiftlint:disable` or `// periphery:ignore`, or regenerating `.swiftlint-baseline.json` to absorb a new violation is the user's call: propose it, and call each one out in the report and PR.
- A Claude Code hook formats and lints each `.swift` file you edit; fix the violations it reports.

## Data Migrations

A change to the persisted JSON shape (`DayData`, `Meal`, `Workout`, `Mood`, `DayDataContainer`: a renamed, removed or retyped field, a new encoding) must leave existing users' files loading cleanly. Before making one, read the Data Migrations policy in `HealthTracker/Data/AGENTS.md`.

## Committing

- Run `scripts/bootstrap` once per clone and per new worktree: it installs the git hooks and the pinned tools.
- Branch first (`git switch -c <type>/<name>`): the git hooks refuse commits and pushes to `main`, and run `scripts/quality --fast` before every push. Let them run.
- Use the `gh` CLI for GitHub work. Open PRs as **draft**; the user approves and merges every PR. Pushing, watching CI and marking a PR ready: `quality-gate` skill.
- A task that outlives the session becomes a GitHub issue, closed by the PR that does it: `issue-tracking` skill.
- Once a feature or batch of related PRs is merged, run the `retro` skill over the batch and report its table alongside the requested work; implementing its proposals needs the user's go-ahead.
