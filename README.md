# HealthTracker

An iOS 26 app (SwiftUI, Swift 6) for tracking daily habits: meals, water, workouts and mood. It follows Clean Architecture with Domain, Data and Presentation layers.

This README is for people. Agents get the same rules from [`AGENTS.md`](AGENTS.md) and the layer `AGENTS.md` files it links to; read those for architecture and coding conventions.

- [Setup](#setup)
- [Day-to-day workflow](#day-to-day-workflow)
- [The quality gate: `scripts/quality`](#the-quality-gate-scriptsquality)
- [Git hooks](#git-hooks)
- [Thresholds, the ratchet and exceptions](#thresholds-the-ratchet-and-exceptions)
- [Tool versions: `scripts/doctor`](#tool-versions-scriptsdoctor)
- [Testing the scripts themselves](#testing-the-scripts-themselves)
- [Working with AI agents](#working-with-ai-agents)
- [Troubleshooting](#troubleshooting)

## Setup

1. Install Xcode **27.1** and the command-line tools:

   ```bash
   brew install swiftlint swiftformat xcbeautify jq
   ```

2. Once per clone, enable the git hooks and check tool versions:

   ```bash
   scripts/bootstrap
   ```

   This sets `core.hooksPath=.githooks`. The setting is relative, so every worktree of the clone uses its own `.githooks/`. If an older `core.hooksPath` was set, bootstrap prints the value it replaced. It is safe to re-run.

3. Open `HealthTracker.xcodeproj` and build. The build runs SwiftLint in **lint-only** mode, so violations show up as Xcode warnings and your files are never rewritten during a build.

## Day-to-day workflow

```bash
git switch -c feat/my-change      # never work on main: the hooks refuse it
# … edit, writing a failing test first (red → green, see AGENTS.md → Workflow) …
scripts/quality --fast            # ~2 min: format, lint, unit tests, Domain/Data coverage
git commit -m "…"                 # pre-commit formats + lints the staged Swift files
scripts/quality --full            # ~8 min: adds UI tests and app-wide coverage
git push -u origin feat/my-change # pre-push refuses main and runs --fast again
gh pr create --draft              # mark ready for review once --full is green
```

A change is **done** when `scripts/quality --full` exits 0. Paste its table into the PR description.

## The quality gate: `scripts/quality`

A single command runs every check and prints a pass/fail table. It exits `0` only when every gate passes.

```text
scripts/quality [--fast|--full] [--json] [--simulator <udid>] [--update-baseline]
```

| Gate | `--fast` (default) | `--full` | Passes when |
|---|---|---|---|
| Format | ✓ | ✓ | `swiftformat --lint` reports 0 files to format |
| Lint | ✓ | ✓ | `swiftlint lint --strict` reports 0 violations |
| Unit tests (`HealthTrackerTests`) | ✓ | ✓ | 0 failures |
| UI tests (`HealthTrackerUITests`) | | ✓ | 0 failures |
| Domain unit line coverage | ✓ | | ≥ `DOMAIN_UNIT_MIN` |
| Data unit line coverage | ✓ | | ≥ `DATA_UNIT_MIN` |
| App line coverage (unit + UI) | | ✓ | ≥ `APP_LINE_MIN` (90%) |
| Per-file floor | | ✓ | every non-View file ≥ `FILE_FLOOR` (80%) |

Example output:

```text
Format                               0  <= 0       ✓
Lint                                 0  <= 0       ✓
Unit tests                           0  <= 0       ✓
UI tests                             0  <= 0       ✓
App line coverage               94.17%  >= 90.0%   ✓
Per-file floor                  88.36%  >= 80.0%   ✓

6/6 gates passed.
```

**Why two kinds of coverage.** UI tests run every view without checking much, which inflates app-wide coverage. So `--fast` measures Domain and Data with **unit tests only**: business rules must be unit-tested. The per-file floor stops one well-tested file from hiding a new file with no tests. Views are left out of the floor because UI tests cover them.

**Outputs.**

| Path | What it holds |
|---|---|
| stdout | The gate table |
| stderr | Details: lint/format violations with file and line, and `below floor: <path> <pct>%` lines |
| `build/xcodebuild.log` | The full test log |
| `build/Test.xcresult` | The result bundle: open it in Xcode, or query it with `xcrun xccov` |
| `build/quality.json` | With `--json`: one entry per gate (`name`, `value`, `threshold`, `comparator`, `passed`) |

`build/` is gitignored.

**Which simulator it uses.** By default it reuses or clones a simulator named `HT-<branch>` (with `/` replaced by `-`). The clone comes from a shut-down iPhone on the newest iOS 26 runtime, or the newest iOS runtime if no iOS 26 is installed. Each worktree gets its own device, so parallel runs don't fight over Xcode's shared simulator pool. An exported `SIMULATOR_ID` is ignored on purpose; pass `--simulator <udid>` to pick a device. Delete a branch's clone when you're done with the branch:

```bash
xcrun simctl delete "HT-feat-my-change"
```

**Useful one-liners.**

```bash
# Which gates are red?
jq -r '.gates[] | select(.passed | not) | "\(.name): \(.value) (needs \(.comparator) \(.threshold))"' build/quality.json

# The 10 least-covered app files from the last run
xcrun xccov view --report --json build/Test.xcresult | jq -r '.targets[]
  | select(.name == "HealthTracker.app") | .files | sort_by(.lineCoverage) | .[:10][]
  | "\(.lineCoverage * 100 | floor)%\t\(.path | sub(".*/HealthTracker/"; "HealthTracker/"))"'

# Uncovered lines of one file
xcrun xccov view --archive --file "$PWD/HealthTracker/Data/Migration/DataMigration.swift" build/Test.xcresult | grep -E ': 0$'
```

To run a single test instead of the whole gate, see [`.agents/skills/cli-test/SKILL.md`](.agents/skills/cli-test/SKILL.md).

## Git hooks

These live in `.githooks/` and are enabled by `scripts/bootstrap`.

**`pre-commit`** takes a few seconds:
- refuses commits on `main`;
- refuses a staged `.swift` file that also has unstaged edits, because re-staging it after formatting would sweep those edits into the commit (stage or stash them first);
- runs SwiftFormat on the staged `.swift` files and re-stages them;
- lints them with `swiftlint --strict`, and any violation blocks the commit.

**`pre-push`**:
- refuses pushes to `main`;
- runs `scripts/quality --fast`, and a red gate blocks the push.

**Emergency bypass**: `SKIP_QUALITY=1 git push` skips the gate and prints a warning. Use it sparingly. There is no CI on GitHub yet (it's Phase 2 of the plan), so for now nothing else re-checks the branch.

`main` is not protected on GitHub (the repo is private on GitHub Free), so these hooks and PR review are what keep it clean. Every PR is approved and merged by hand; nothing auto-merges.

## Thresholds, the ratchet and exceptions

All three files are committed, so any change to them shows up as a reviewable diff.

| File | Contents |
|---|---|
| [`scripts/quality-thresholds.env`](scripts/quality-thresholds.env) | `APP_LINE_MIN`, `FILE_FLOOR`, `DOMAIN_UNIT_MIN`, `DATA_UNIT_MIN` |
| [`scripts/coverage-exceptions.txt`](scripts/coverage-exceptions.txt) | Files allowed below the per-file floor (grandfathered when the gate was introduced). Remove an entry once its file is covered. |
| [`scripts/tool-versions.env`](scripts/tool-versions.env) | The pinned SwiftLint, SwiftFormat and Xcode versions |

**The ratchet.** The Domain and Data minimums start at the coverage measured when the gate was introduced and aim for 95%. After you add unit tests that raise them, lock in the gain:

```bash
scripts/quality --fast --update-baseline
```

This raises `DOMAIN_UNIT_MIN` / `DATA_UNIT_MIN` to the measured value, rounded down to one decimal. It never lowers them, and it only writes after a fully green run. Commit the changed thresholds file together with the tests that earned it.

**Lowering a threshold, adding an exception, or adding `// swiftlint:disable`** is a deliberate decision. Make it its own line in the PR description, with the reason.

## Tool versions: `scripts/doctor`

`scripts/doctor` compares your installed SwiftLint, SwiftFormat and Xcode with the pins, and checks that `xcbeautify` and `jq` exist. Each mismatch comes with a suggested fix command.

- **Locally** it only warns. `scripts/quality`, the hooks and `scripts/bootstrap` run it for you.
- **With `CI=true`** it fails.

Pinning matters: different SwiftFormat versions disagree about what is "formatted", and `.swiftformat`'s `--minversion` refuses older binaries. To upgrade a tool, bump its pin, run `swiftformat . --swift-version 6`, and commit the reformatted files in the same PR.

## Testing the scripts themselves

The gate is code too. Every script has bash tests under `scripts/tests/`. They run in throwaway repos with stubbed tools, so they take seconds and never touch a simulator.

```bash
scripts/tests/run                 # all test files
scripts/tests/test-hooks.sh       # just one
```

Change a script by adding a failing test first, the same red → green rule as the app code.

## Working with AI agents

The repo is set up so coding agents (Claude Code, Codex) work under the same gate you do:

- **[`AGENTS.md`](AGENTS.md)** tells agents that done means `scripts/quality --full` exits 0, and to report the gate table. The `quality-gate` skill ([`.agents/skills/quality-gate/SKILL.md`](.agents/skills/quality-gate/SKILL.md)) explains how to act on a red gate.
- **`.claude/settings.json`**:
  - denies bypasses: `--no-verify`, `git commit -n`, `git -c core.hooksPath`, `SKIP_QUALITY=`, pushes to `main`, force-push;
  - denies `gh pr merge`, so agents stop at a ready PR and you merge.
  - The deny rules match command patterns, so they occasionally block a harmless command with the same shape.
- **`.claude/hooks/format-swift.sh`** runs after every agent edit to a `.swift` file. It formats the file and feeds lint violations straight back to the agent.
- **Parallel agents** each work in their own worktree under `.claude/worktrees/`, and the gate's per-worktree simulator keeps their test runs apart. See [`AGENTS.md` → Parallel agents](AGENTS.md#parallel-agents).

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| A gate shows `n/a` | The metric couldn't be measured: the build failed or a test bundle crashed. Read `build/xcodebuild.log`. |
| Every test fails with "Application failed preflight checks" | The simulator was still booting. The gate waits with `simctl bootstatus`; if it persists, delete the `HT-<branch>` clone and re-run. |
| `warning: SwiftFormat … installed, pinned …` | Version drift. Install the pinned version (`scripts/doctor` prints how) before trusting the Format gate. |
| Hooks don't run | Run `scripts/bootstrap`, then check `git config core.hooksPath` prints `.githooks`. |
| Commit refused: "staged Swift files also have unstaged changes" | Stage the rest (`git add <file>`) or stash it, then commit. |
| `git push` from an agent times out | The pre-push gate takes ~2 min; agents run `git push` with a 10-minute timeout (see `AGENTS.md`). |
| Old `HT-*` simulators piling up | `xcrun simctl list devices \| grep HT-`, then `xcrun simctl delete <udid>`. |
