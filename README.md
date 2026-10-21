# HealthTracker

An iOS 26 app for tracking daily habits (meals, water, workouts, mood), built with SwiftUI and Swift 6 in a Clean Architecture split (Domain / Data / Presentation).

This README is the human guide to building, testing and the **quality gate**. AI agents get the same rules from [`AGENTS.md`](AGENTS.md) and the skills in `.agents/skills/`.

## Contents

- [Setup](#setup)
- [Daily workflow](#daily-workflow)
- [The quality gate (`scripts/quality`)](#the-quality-gate-scriptsquality)
- [Fixing a red gate](#fixing-a-red-gate)
- [Coverage thresholds and the ratchet](#coverage-thresholds-and-the-ratchet)
- [Git hooks](#git-hooks)
- [Xcode build phase](#xcode-build-phase)
- [Working with AI agents](#working-with-ai-agents)
- [Script reference](#script-reference)
- [Troubleshooting](#troubleshooting)

## Setup

**1. Install the tools.** You need Xcode 27.1 with an iOS 26 simulator runtime, plus:

```bash
brew install swiftlint swiftformat xcbeautify jq
```

The versions are pinned in `scripts/tool-versions.env` (SwiftLint 0.65.0, SwiftFormat 0.61.1, Xcode 27.1). Pinning matters because formatter and linter rules change between releases: a different version can flag code that passes on another machine.

**2. Bootstrap the clone (once):**

```bash
scripts/bootstrap
```

This does two things:
- It points git at the repo's hooks (`git config core.hooksPath .githooks`). The path is relative, so every worktree uses its own `.githooks`. If a different hooks path was set before, it tells you it replaced it.
- It runs `scripts/doctor`, which compares your installed tools with the pins and prints a fix command for each mismatch.

Running `scripts/bootstrap` again is safe.

## Daily workflow

```bash
git switch -c feat/my-change            # 1. branch: committing on main is refused
# ...edit code and tests (red → green)...
scripts/quality --fast                  # 2. iterate: ~2 min
git commit -m "..."                     # 3. pre-commit hook formats + lints staged Swift files
scripts/quality --full                  # 4. done check: ~8 min, the same bar CI uses
git push -u origin feat/my-change       # 5. pre-push hook re-runs --fast; pushing to main is refused
gh pr create --draft                    # 6. open as draft, mark ready when --full is green
```

Every PR is reviewed and merged by hand. Auto-merge is off, and agents are not allowed to merge.

## The quality gate (`scripts/quality`)

One command decides whether the code is good enough. It prints a pass/fail table and exits `0` only when every gate passes.

```bash
scripts/quality            # same as --fast
scripts/quality --fast     # format, lint, unit tests, Domain/Data unit coverage
scripts/quality --full     # format, lint, unit + UI tests, app coverage, per-file floor
scripts/quality --full --json            # also writes build/quality.json
scripts/quality --simulator <udid>       # test on a specific simulator
scripts/quality --fast --update-baseline # raise the coverage ratchets (see below)
scripts/quality --help
```

Example `--full` output:

```
Format                               0  <= 0       ✓
Lint                                 0  <= 0       ✓
Unit tests                           0  <= 0       ✓
UI tests                             0  <= 0       ✓
App line coverage               94.17%  >= 90.0%   ✓
Per-file floor                  88.36%  >= 80.0%   ✓

6/6 gates passed.
```

### What each gate checks

| Gate | Mode | Passes when |
|---|---|---|
| Format | both | `swiftformat --lint` finds no file that needs formatting |
| Lint | both | `swiftlint lint --strict` reports 0 violations (warnings count) |
| Unit tests | both | `HealthTrackerTests` has 0 failures |
| UI tests | `--full` | `HealthTrackerUITests` has 0 failures |
| Domain unit line coverage | `--fast` | Unit-test coverage of `HealthTracker/Domain/` ≥ `DOMAIN_UNIT_MIN` |
| Data unit line coverage | `--fast` | Unit-test coverage of `HealthTracker/Data/` ≥ `DATA_UNIT_MIN` |
| App line coverage | `--full` | Unit + UI coverage of the whole app ≥ `APP_LINE_MIN` (90%) |
| Per-file floor | `--full` | The least-covered file is ≥ `FILE_FLOOR` (80%). Files under `Presentation/Views/` and those listed in `scripts/coverage-exceptions.txt` don't count |

Why two kinds of coverage:
- UI tests run a lot of code without checking much of it, so app-wide coverage can look high while the business rules go untested. The `--fast` coverage gates count **unit tests only**, which keeps the rules in Domain and Data covered on their own.
- The per-file floor stops one well-tested file from hiding a new untested one.

A value of `n/a` in the table means the gate couldn't measure anything: the build failed, or a test bundle crashed. The full log is in `build/xcodebuild.log`.

### Where the output goes

All output is in `build/`, which git ignores:

| File | Contents |
|---|---|
| `build/xcodebuild.log` | Full xcodebuild output |
| `build/Test.xcresult` | Result bundle: open it in Xcode to browse failures and coverage |
| `build/quality.json` | With `--json`: one entry per gate (`name`, `value`, `threshold`, `passed`) |

Exit codes: `0` all gates passed, `1` a gate failed, `2` usage error.

### Which simulator it uses

By default each branch or worktree gets its own simulator, named `HT-<branch>` (for example `HT-feat-my-change`). The first run clones it from an iPhone on the newest iOS 26 runtime, falling back to the newest iOS runtime installed. This keeps parallel worktrees, and agents, from fighting over one device. An exported `SIMULATOR_ID` is ignored on purpose; use `--simulator <udid>` to pick a device.

Delete a branch's clone when you're done with the branch:

```bash
xcrun simctl delete "HT-feat-my-change"
```

## Fixing a red gate

Fix the code or the tests, never the threshold.

| Red gate | Fix |
|---|---|
| Format | `swiftformat . --swift-version 6` |
| Lint | Fix each violation printed above the table. `swiftlint --fix` handles the autocorrectable ones |
| Unit / UI tests | Read the failures in `build/xcodebuild.log` or open `build/Test.xcresult` in Xcode. Re-run one test with `xcodebuild test ... -only-testing:HealthTrackerTests/DayDataTests` (see the `cli-test` skill) |
| Coverage | Add tests for the least-covered files (below) |

Find the least-covered files after any run:

```bash
xcrun xccov view --report --json build/Test.xcresult | jq -r '.targets[]
  | select(.name == "HealthTracker.app") | .files | sort_by(.lineCoverage) | .[:10][]
  | "\(.lineCoverage * 100 | floor)%\t\(.path | sub(".*/HealthTracker/"; "HealthTracker/"))"'
```

List the uncovered lines of one file (execution count `0`):

```bash
xcrun xccov view --archive --file "$PWD/HealthTracker/Data/Migration/DataMigration.swift" build/Test.xcresult | grep -E ': 0$'
```

## Coverage thresholds and the ratchet

The thresholds live in `scripts/quality-thresholds.env`:

| Threshold | Value | Meaning |
|---|---|---|
| `APP_LINE_MIN` | 90.0 | App-wide unit + UI coverage |
| `FILE_FLOOR` | 80.0 | Minimum coverage for any one file (Views excluded) |
| `DOMAIN_UNIT_MIN` | ratchet | Domain unit-test coverage. Started at today's measured value, aiming for 95+ |
| `DATA_UNIT_MIN` | ratchet | Data unit-test coverage. Started at today's measured value, aiming for 95 |

**The ratchet:** after you raise Domain or Data unit coverage, lock in the gain:

```bash
scripts/quality --fast --update-baseline
```

It raises the `*_UNIT_MIN` values to the newly measured coverage, rounded down to one decimal. It never lowers a threshold, and it only runs when every gate is green. Commit the changed `scripts/quality-thresholds.env` together with the tests that earned it.

**Exceptions:** `scripts/coverage-exceptions.txt` lists files that were already below the per-file floor when the gate was introduced. Each line is a path plus a comment with its coverage. Remove a file from the list once it's covered. Adding a file to the list, or lowering a threshold, is a deliberate decision: call it out in the PR.

## Git hooks

Enabled by `scripts/bootstrap`. They live in `.githooks/`.

**pre-commit** (a few seconds):
- refuses to commit on `main`;
- refuses when a staged `.swift` file also has unstaged changes, because re-staging after formatting would sweep those changes into the commit (stage or stash them first);
- formats the staged `.swift` files with SwiftFormat and re-stages them;
- lints them with `swiftlint --strict`, and fails on any violation.

**pre-push** (~2 min):
- refuses to push to `main`;
- runs `scripts/quality --fast`, and blocks the push if a gate is red.

Emergency escape hatch, for humans only: `SKIP_QUALITY=1 git push` skips the gate (it prints a warning). Use it rarely, and run `--full` before marking the PR ready.

## Xcode build phase

The app target's **SwiftLint** build phase runs `swiftlint lint --quiet`, so violations appear as warnings in Xcode's issue navigator. It **never** rewrites your files; formatting happens in the pre-commit hook. The phase is skipped when `CI=true`.

## Working with AI agents

Agents follow [`AGENTS.md`](AGENTS.md) (Quality Gates section) and the `quality-gate` skill, so they run the same commands you do:

- "Done" means `scripts/quality --full` exits 0. Agents paste the gate table into their report and PR.
- `.claude/settings.json` stops Claude Code from bypassing the gate. It denies:
  - `--no-verify` / `-n` and `git -c core.hooksPath`;
  - `SKIP_QUALITY=`;
  - pushes to `main` and force-pushes;
  - `gh pr merge`.
- A Claude Code hook (`.claude/hooks/format-swift.sh`) formats and lints every Swift file an agent edits, so it sees violations immediately.
- Agents open PRs as **draft** and stop at "ready for review". You review and merge.

## Script reference

| Path | Purpose |
|---|---|
| `scripts/quality` | The quality gate (see above) |
| `scripts/bootstrap` | One-time setup: enables `.githooks`, runs `doctor` |
| `scripts/doctor` | Compares installed tools with the pins. Warns locally, fails when `CI=true` |
| `scripts/tool-versions.env` | Pinned SwiftLint / SwiftFormat / Xcode versions |
| `scripts/quality-thresholds.env` | Coverage thresholds and ratchets |
| `scripts/coverage-exceptions.txt` | Files grandfathered below the per-file floor |
| `scripts/lib/` | Pieces used by `scripts/quality` (coverage math, simulator picking, report table). Each has tests |
| `scripts/tests/run` | Runs every `scripts/tests/test-*.sh` (the scripts' own tests, no simulator needed) |
| `.githooks/` | pre-commit and pre-push hooks |
| `.claude/hooks/format-swift.sh` | Claude Code hook that formats and lints each edited Swift file |

If you change a script, run its tests:

```bash
scripts/tests/run
```

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| `warning: SwiftFormat X installed, pinned Y` | Your tool version differs from the pin. Install the pinned version (the warning prints how); otherwise Format/Lint results may differ from CI |
| Hooks don't run on commit or push | Run `scripts/bootstrap`, then check with `git config core.hooksPath` (should print `.githooks`) |
| Commit refused: "unstaged changes" | A staged Swift file also has unstaged edits. `git add` it fully, or stash the extra edits |
| A gate shows `n/a` | Nothing was measured: the build failed or a test bundle crashed. Read `build/xcodebuild.log` |
| Push takes ~2 min | That's the pre-push `--fast` gate building and running the unit tests |
| Too many `HT-*` simulators | `xcrun simctl list devices \| grep HT-`, then `xcrun simctl delete <name>` for branches you're done with |
| Coverage gate red after deleting tests or code | Add tests for the least-covered files (see [Fixing a red gate](#fixing-a-red-gate)). Don't lower the threshold silently |
