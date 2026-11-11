# Project: Health Tracker iOS Mobile App

HealthTracker is an iOS 26.0 health tracking app built with SwiftUI and Swift 6: it logs meals, water, workouts and mood, and rates each day. Clean Architecture, with Domain, Data and Presentation layers.

## Repo Map

Each area keeps its rules in its own `AGENTS.md`. Claude Code loads it when Read first opens a file there, never through Bash; read it yourself when you plan a change there or review from a diff.

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

- `HealthTracker/UITestingSupport.swift` — the `-uiTesting` and unit-test-host startup switches; what each skips: the test targets' `AGENTS.md`.
- `HealthTracker/Resources/` — localizable strings for `en` and `pt-BR`, plus `AppShortcuts.strings` (Siri phrases).

## Workflow

The core loop is **red → green**: write a failing test, then make it pass. Follow it always: call `Skill("tdd")` first.

1. Before coding, state how you'll verify the change with something runnable: a unit or UI test, a bash command, a preview snapshot.
2. Write that test first and watch it fail (**red**). Every bug fix starts with a regression test that reproduces the bug.
3. Implement the minimum code to pass it (**green**). On app or test code, then run the `simplify` skill over the diff.
4. Run `scripts/quality --fast` and iterate until it exits 0, so review sees a diff that passes the gates.
5. Review the diff in a fresh-context subagent, never in the session that wrote it: `reviewing` skill (passes by risk tier, rounds that converge).
6. Run `scripts/quality --full` (`--fast` for a change touching only docs or agent config) and iterate until it exits 0: the bar for **done** ([Quality Gates](#quality-gates)).

**Definition of done**, in every session, interactive or workflow: the final report and PR carry the evidence, each item that applies.

1. **Red**: the failing test's name and its failing assertion line, quoted.
2. **Gate**: the table from the last `scripts/quality` run, after the last edit. A Stop hook sends the main session back, once per gate run, when Swift changed since the last green run's `build/quality.json`.
3. **Scenario**: for user-facing behaviour, the scenario checked in `en` and `pt-BR` (an AppIntentsTesting or UI test, or `device-interaction`).
4. **Previews**: for an edited View, the `RenderPreview` snapshots `HealthTracker/Presentation/AGENTS.md` asks for.
5. **Review**: each pass the `reviewing` skill's tier calls for (or why one was unavailable), with its findings and what became of each.

Aim for near-total coverage: every public function, file and edge case earns a test. Follow the plan when we have one.

Keep every change **tight**:

- **Think first.** State assumptions explicitly. When multiple interpretations or a simpler approach exist, surface them and ask.
- **Simplest thing that works.** Minimum code, nothing speculative: skip unrequested abstractions, configurability, and error handling for impossible cases. If 200 lines could be 50, rewrite.
- **Surgical.** Every changed line traces to the request. Match surrounding style, leave adjacent code alone, and remove only the orphans your own change creates. Flag unrelated dead code rather than deleting it.

### Delegating

On a task spanning several files, layers or PRs, the main session is the **orchestrator**: it keeps the plan, the decisions and the thread with the user, and hands subagents any step it needs back only as a conclusion (a broad search, a long log, a review pass, an independent slice). Work needing the user's judgement or the conversation's history stays in the main session.

- Run independent slices, or a staged pipeline (implement → review → verify), as a Workflow.
- Brief each subagent as a cold start: the goal, the files, the constraints, its done-criterion, and the shape of the report to return. Write each skill it needs as a call in its first step (`Skill("tdd")` for an implementer).
- An implementer's report schema requires the definition of done as fields: `red_evidence` (test name plus failing assertion line), `green_evidence` (the gate table), `scenario` (the en and pt-BR check, for user-facing behaviour), `previews` (snapshots, when Views changed) and `skills_loaded`. The verify stage fails an implementer whose field is empty where it applies, and the PR body's "How verified" lists the skills that ran.
- Agents working at the same time each take their own worktree in `.claude/worktrees/<branch-name>`, and at most two of them build or test at once: `parallel-agents` skill. Create a worktree only when the task requires it or the user asks.

## Building and Validating

| Where | Build and test with |
|---|---|
| Main session, inner loop | Xcode MCP `BuildProject`, `RunSomeTests` |
| Workflow subagent, any gate | `scripts/quality`, or the MCP per the `parallel-agents` skill |
| `xcodebuild` (`cli-build`, `cli-test` skills) | Only after an MCP build or test call errors, quoting that error (a device or preview tool's doesn't count). MCP disconnected: ask the user to run `/mcp` |
| Cloud session (Linux, no Xcode) | CI: push, dispatch and read it yourself (`quality-gate` skill, `CLOUD.md`); hand the user only what CI can't run |

- The project uses `PBXFileSystemSynchronizedRootGroup`: adding or deleting a source file needs no `project.pbxproj` edit. A file under `HealthTracker/` that must stay out of the app bundle (an `AGENTS.md`) needs a `membershipExceptions` entry there.
- Edit files with Edit or Write: the layer-doc and format hooks run on those.

### Skill and tool routing

A skill loads only when called: make each call below. Each layer's `AGENTS.md` names its own skills.

| When | Call |
|---|---|
| An actor-isolation or `Sendable` diagnostic | `Skill("swift-concurrency:swift-concurrency")` before fixing, then fix every call site sharing the cause |
| Checking behaviour on a device | `device-interaction`; seed data with `mock-sim-data` |
| An Apple API question | `DocumentationSearch` before training memory |
| Compile-checking one file | `XcodeRefreshCodeIssuesInFile` |
| Definitions, references | `LSP` (after `scripts/bootstrap` and one MCP `BuildProject`); its diagnostics are real |
| Trying code without a test | `RunCodeSnippet` |

## Quality Gates

`scripts/quality` is the one gate: it prints a pass/fail table and exits 0 only when every gate passes. Reading its output, fixing a red gate, chasing coverage, the lint baseline and CI: `quality-gate` skill.

- **Iterate** with `scripts/quality --fast` (format, lint, fitness, unit tests, unused code, Domain/Data coverage).
- **Done** is `scripts/quality --full` exiting 0. A change touching only docs or agent config (the `paths-ignore` paths in `.github/workflows/ci.yml`) is done when `--fast` exits 0. Paste that run's gate table in your final report and PR.
- **Fix a red gate in code or tests.** Lowering a threshold, editing `scripts/coverage-exceptions.txt` or `scripts/fitness/test-mirror-exceptions.txt`, adding a `swiftlint:disable` or `// periphery:ignore`, or regenerating `.swiftlint-baseline.json` to absorb a new violation is the user's call: propose it, and call each one out in the report and PR.
- Hooks in `.claude/hooks/` format and lint each `.swift` file you Edit or Write, refuse Bash writes to one, and name the doc, skill or runner a step needs; act on what they report.

## Data Migrations

A change to the persisted JSON shape (`DayData`, `Meal`, `Workout`, `Mood`, `DayDataContainer`: a renamed, removed or retyped field, a new encoding) must leave existing users' files loading cleanly. Before making one, read the Data Migrations policy in `HealthTracker/Data/AGENTS.md`.

## Committing

- Run `scripts/bootstrap` once per clone and per new worktree: it installs the git hooks and the pinned tools.
- Branch first (`git switch -c <type>/<name>`): the git hooks refuse commits and pushes to `main`, and run `scripts/quality --fast` before every push. Let them run.
- Use the `gh` CLI for GitHub work. Open PRs as **draft**; the user approves and merges every PR. Pushing, watching CI and marking a PR ready: `quality-gate` skill.
- A task that outlives the session becomes a GitHub issue, closed by the PR that does it: `issue-tracking` skill.
- Once a feature or batch of related PRs is merged, run the `retro` skill over the batch and report its table alongside the requested work; implementing its proposals needs the user's go-ahead.
