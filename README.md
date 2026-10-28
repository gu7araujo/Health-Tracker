# HealthTracker

An iOS 26 app for tracking daily habits (meals, water, workouts, mood), built with SwiftUI and Swift 6 in a Clean Architecture split (Domain / Data / Presentation).

This README is the human guide to building, testing and the **quality gate**. AI agents get the same rules from [`AGENTS.md`](AGENTS.md) and the skills in `.agents/skills/`.

## Contents

- [Setup](#setup)
- [Daily workflow](#daily-workflow)
- [The quality gate (`scripts/quality`)](#the-quality-gate-scriptsquality)
- [Fixing a red gate](#fixing-a-red-gate)
- [Coverage thresholds and the ratchet](#coverage-thresholds-and-the-ratchet)
- [Unused code](#unused-code)
- [Lint rules](#lint-rules)
- [Fitness functions](#fitness-functions)
- [Git hooks](#git-hooks)
- [Xcode build phase](#xcode-build-phase)
- [Continuous integration](#continuous-integration)
- [Working with AI agents](#working-with-ai-agents)
- [Script reference](#script-reference)
- [Troubleshooting](#troubleshooting)

## Setup

**1. Install the tools.** You need Xcode 27.1 with an iOS 26 simulator runtime, plus:

```bash
brew install swiftlint swiftformat xcbeautify jq
```

and the pinned [Periphery](https://github.com/peripheryapp/periphery) binary for the Unused code gate, which `scripts/bootstrap` (step 2) installs.

The versions are pinned in `scripts/tool-versions.env` (SwiftLint 0.65.0, SwiftFormat 0.61.1, Periphery 3.8.0, Xcode 27.1). Pinning matters because formatter and linter rules change between releases: a different version can flag code that passes on another machine.

**2. Bootstrap the clone (once per clone or worktree):**

```bash
scripts/bootstrap
```

This does three things:
- It points git at the repo's hooks (`git config core.hooksPath .githooks`). The path is relative, so every worktree uses its own `.githooks`. If a different hooks path was set before, it tells you it replaced it.
- It runs `scripts/ci/install-tools.sh build/tools/bin`, which downloads the pinned Periphery, SwiftLint and SwiftFormat (each release zip sha256-checked) into `build/tools/bin`. The gate, `doctor`, the hooks and the script tests run tools from there before `PATH`. A fresh worktree has no `build/tools/bin`, so bootstrap it before its first push: without Periphery the pre-push gate fails.
- It runs `scripts/doctor`, which compares your installed tools with the pins and prints a fix command for each mismatch.

Running `scripts/bootstrap` again is safe.

## Daily workflow

```bash
git switch -c feat/my-change            # 1. branch: committing on main is refused
# ...edit code and tests (red → green)...
scripts/quality --fast                  # 2. iterate: ~2 min
git commit -m "..."                     # 3. pre-commit hook formats + lints staged Swift files, runs fitness checks
CI=true scripts/quality --full          # 4. ready check: ~8 min, the same bar CI uses
git push -u origin feat/my-change       # 5. pre-push hook re-runs --fast; pushing to main is refused
gh pr create --draft                    # 6. open as draft, mark ready when step 4 is green
```

Every PR is reviewed and merged by hand. Auto-merge is off, and agents are not allowed to merge.

## The quality gate (`scripts/quality`)

One command decides whether the code is good enough. It prints a pass/fail table and exits `0` only when every gate passes.

```bash
scripts/quality            # same as --fast
scripts/quality --fast     # format, lint, fitness checks, unit tests, unused code, Domain/Data unit line + region coverage
scripts/quality --full     # everything in --fast, plus UI tests, app coverage, per-file floor
scripts/quality --full --json            # also writes build/quality.json
scripts/quality --simulator <udid>       # test on a specific simulator
scripts/quality --fast --update-baseline # raise the coverage ratchets (see below)
scripts/quality --help
```

Each row prints the gate, its measured value, the threshold and ✓ or ✗; run it for the current table. `scripts/quality --help` lists what each mode runs.

### What each gate checks

| Gate | Mode | Passes when |
|---|---|---|
| Format | both | `swiftformat --lint` finds no file that needs formatting |
| Lint | both | `swiftlint lint --strict` reports 0 violations outside the [baseline](#lint-rules) (warnings count) |
| Fitness | both | `scripts/fitness/run` reports 0 [cross-file violations](#fitness-functions) |
| Unit tests | both | `HealthTrackerTests` has 0 failures |
| UI tests | `--full` | `HealthTrackerUITests` has 0 failures |
| Unused code | both | `periphery scan` reports 0 unused declarations (see [Unused code](#unused-code)) |
| Domain / Data unit line and region coverage | both | Unit-test line and region coverage of `HealthTracker/Domain/` and `HealthTracker/Data/` ≥ their `*_UNIT_MIN` ratchet |
| App line coverage | `--full` | Unit + UI coverage of the whole app ≥ `APP_LINE_MIN` |
| Per-file floor | `--full` | The least-covered file is ≥ `FILE_FLOOR`. Files under `Presentation/Views/` and those listed in `scripts/coverage-exceptions.txt` don't count |

Why two kinds of coverage:
- UI tests run a lot of code without checking much of it, so app-wide coverage can look high while the business rules go untested. The Domain and Data gates count **unit tests only**, which keeps the rules in those layers covered on their own. To measure that, `--full` runs the unit tests and the UI tests as two separate runs, then merges them into `build/Test.xcresult` for the app-wide numbers.
- The per-file floor stops one well-tested file from hiding a new untested one.

Line vs region coverage: a line counts as covered once any part of it runs. A **region** is a single code path, and one line can hold several: in `let amount = water ?? 0` the `?? 0` default is its own region, and so is each side of `&&` or `?:`. A test that only ever passes a non-nil `water` covers the line but leaves the default region at 0. The region rows catch those gaps. `scripts/lib/region-coverage.sh` reads them with `xcrun llvm-cov export` from the unit run's `Coverage.profdata`, before the UI run replaces it. (Swift reports no branch coverage, so regions are the finest measure available.)

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
| Lint | Fix each violation printed above the table. `swiftlint --fix` handles the autocorrectable ones. The rules and the baseline: [Lint rules](#lint-rules) |
| Fitness | Fix each violation printed above the table: [Fitness functions](#fitness-functions) |
| Unit / UI tests | Read the failures in `build/xcodebuild.log` or open `build/Test.xcresult` in Xcode. Re-run one test with `xcodebuild test ... -only-testing:HealthTrackerTests/DayDataTests` (see the `cli-test` skill) |
| Unused code | Delete each declaration printed above the table (`<file>:<line>:<col>: warning: Unused ...`), with any mock member or test that only exercises it. See [Unused code](#unused-code) for false positives |
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

For a red region row, the `llvm-cov report` / `llvm-cov show` commands that list each file's missed regions are in the `quality-gate` skill (`.agents/skills/quality-gate/SKILL.md`, section 4).

## Coverage thresholds and the ratchet

The thresholds live in `scripts/quality-thresholds.env`, the source of truth for their values. `APP_LINE_MIN` (app-wide unit + UI coverage) and `FILE_FLOOR` (any one file, Views excluded) are fixed; the four `*_UNIT_MIN` values (Domain and Data, line and region, unit tests only) are ratchets.

**The ratchet:** after you raise Domain or Data unit line or region coverage, lock in the gain:

```bash
scripts/quality --fast --update-baseline
```

It raises the four `*_UNIT_MIN` values (line and region) to the newly measured coverage, rounded down to one decimal. It never lowers a threshold, and it only runs when every gate is green. Commit the changed `scripts/quality-thresholds.env` together with the tests that earned it.

**Exceptions:** `scripts/coverage-exceptions.txt` lists files that were already below the per-file floor when the gate was introduced. Each line is a path plus a comment with its coverage. Remove a file from the list once it's covered: the floor fails on an entry whose file now meets `FILE_FLOOR`. Adding a file to the list, or lowering a threshold, is a deliberate decision: call it out in the PR.

## Unused code

The Unused code gate runs [Periphery](https://github.com/peripheryapp/periphery) after the tests, so unused declarations (what AI agents tend to leave behind) fail the gate. `scripts/quality` builds into its own `build/DerivedData`, and Periphery scans that build's index store (`--skip-build`; Periphery's own build mode fails on Xcode 27.1). `.periphery.yml` sets `strict: true` and there is no baseline file: the count must be 0.

Re-scan by hand after a gate run (it reads that run's index, so rebuild with `scripts/quality` after editing):

```bash
periphery scan --skip-build --index-store-path build/DerivedData/Index.noindex/DataStore
```

**False positives.** Periphery can't see a use that only generated code makes. The known case: an iOS 27 `@State` property used only through its `$binding` (the `@State` macro hides the use). Mark it `// periphery:ignore - <reason>` (see `MainView.swift`). The UI-test catalogs `AccessibilityID.swift` and `EnglishLabel.swift` are kept complete on purpose, with a file-level `// periphery:ignore:all`, which also hides any entry that goes dead later. Adding an ignore is a deliberate decision, like a `swiftlint:disable`: call it out in the PR.

**Evaluated and skipped** (2026-10-23):
- **Mutation testing (Muter):** no release since 2023; master inserts no mutants, and with the regression reverted it silently drops nested mutants and reports them as survivors. It would also cost ~25–35 macOS minutes a run. Revisit when upstream fixes it.
- **Branch coverage:** Swift 6.4 emits no branch regions (`llvm-cov` reports 0/0 for every file), so there is nothing to measure. The region coverage gates take its place.

## Lint rules

All SwiftLint rules live in the root `.swiftlint.yml`. The Lint gate runs with `--strict`, so a warning fails it too.

**Size and complexity limits** (warning / error):

| Rule | Limit |
|---|---|
| `cyclomatic_complexity` | 8 / 12 |
| `function_body_length` | 40 / 60 lines |
| `closure_body_length` | 30 / 50 lines (forces SwiftUI subview extraction) |
| `type_body_length` | 250 / 350 lines |
| `file_length` | 400 / 500 lines, comment-only lines ignored |
| `function_parameter_count` | 5 / 7 |

Also opted in: `force_unwrapping`, `implicitly_unwrapped_optional`, `fatal_error_message`, `first_where`, `contains_over_filter_count`, `empty_count`. `HealthTrackerTests/` and `HealthTrackerUITests/` each have a nested `.swiftlint.yml` that turns off `force_unwrapping` and `implicitly_unwrapped_optional`.

**Architecture rules** (`custom_rules`, severity error, scoped by path). Each message names the `AGENTS.md` rule it enforces:

| Rule | Scope | Fails on | Enforces |
|---|---|---|---|
| `domain_no_ui_frameworks` | `HealthTracker/Domain/` | `import SwiftUI`, `UIKit`, `UserNotifications` or `CloudKit`. `DayStatus.swift` and `Mood.swift` are allowlisted for their `color`/`localizedName` affordances | `Domain/AGENTS.md` rule_3 |
| `presentation_no_data_layer` | `HealthTracker/Presentation/` | Constructing `HealthDataRepository`, `ICloudDriveDataSource`, `UserDefaultsDataSource` or `NotificationService`. The `MainViewModel` convenience init (the composition root) opts out with `swiftlint:disable:next` | `Presentation/AGENTS.md` data flow |
| `no_hardcoded_locale` | `HealthTracker/` | `Locale(identifier:` or `TimeZone(identifier:` | `Presentation/AGENTS.md` localization |
| `unit_tests_use_swift_testing` | `HealthTrackerTests/` | `import XCTest` | `HealthTrackerTests/AGENTS.md` rule_1 |
| `ui_tests_no_testable_import` | `HealthTrackerUITests/` | `@testable import` | `HealthTrackerUITests/AGENTS.md` rule_1 |
| `ui_tests_no_sleep` | `HealthTrackerUITests/` | `sleep(`, `usleep(`, `Thread.sleep(` | `HealthTrackerUITests/AGENTS.md` rule_3 |
| `no_print` | everywhere | `print(` (warning) | use the logger |

Custom rules need SourceKit, which Linux SwiftLint lacks, so the Linux `lint` CI job skips them. The macOS `test` job enforces them through `scripts/quality`, as do the pre-commit hook, the Claude Code hook and the Xcode build phase.

**The baseline.** `.swiftlint-baseline.json` freezes the violations that existed when the limits were introduced, so only new violations fail. SwiftLint matches an entry by file, rule, the line's text and the message, not by line number: code moving around a baselined violation is fine, but making the baselined closure or function longer or more complex brings the violation back.

The backlog to burn down (12 violations):

| File | Line(s) | Rule |
|---|---|---|
| `HealthTracker/Domain/Entities/Workout.swift` | 103 | `cyclomatic_complexity` (9 > 8) |
| `HealthTracker/Presentation/Views/AddEditModal.swift` | 69, 70, 145 | `closure_body_length` |
| `HealthTracker/Presentation/Views/Components/CalendarStrip.swift` | 30, 31 | `closure_body_length` |
| `HealthTracker/Presentation/Views/MainView.swift` | 18 | `closure_body_length` |
| `HealthTracker/Presentation/Views/MealsSectionView.swift` | 15, 23 | `closure_body_length` |
| `HealthTracker/Presentation/Views/WaterSectionView.swift` | 14 | `closure_body_length` |
| `HealthTracker/Presentation/Views/WorkoutsSectionView.swift` | 15, 23 | `closure_body_length` |

To burn one down, fix it (refactor `Workout.swift:103`, extract SwiftUI subviews), then regenerate the baseline from the repo root and commit both together. The `jq` step strips the absolute `file://` prefix SwiftLint writes, so the baseline also matches in CI's checkout:

```bash
swiftlint lint --quiet --write-baseline .swiftlint-baseline.json
tmp=$(mktemp) && jq --arg p "file://$PWD/" 'map(.violation.location.file |= ltrimstr($p))' .swiftlint-baseline.json > "$tmp" && mv "$tmp" .swiftlint-baseline.json
```

Regenerating the baseline to make a new violation pass is a deliberate decision, like lowering a threshold: call it out in the PR. When the backlog is empty, delete the file and the `baseline:` line in `.swiftlint.yml`.

## Fitness functions

Some rules span several files, which SwiftLint can't see. Small bash scripts in `scripts/fitness/` check them; each has fixture tests in `scripts/tests/test-fitness-*.sh`.

| Check | Fails when | Enforces |
|---|---|---|
| `localization-parity.sh` | A `.strings` file, or a key in one, exists in `en.lproj` but not `pt-BR.lproj`, or the reverse | `Presentation/AGENTS.md` localization |
| `test-mirror.sh` | A Domain/Data `.swift` file has no `HealthTrackerTests/**/<Name>Tests.swift`. Protocol-only files don't count. A name shared with another app file needs its test at the mirrored path, `HealthTrackerTests/<dirs>/<Name>Tests.swift` | `HealthTrackerTests/AGENTS.md` (mirrors the production tree) |
| `accessibility-ids.sh` | An ID in `HealthTrackerUITests/Support/AccessibilityID.swift` isn't declared in `HealthTracker/Presentation/AccessibilityID.swift` | `HealthTrackerUITests/AGENTS.md` rule_2 |
| `persisted-shape-guard.sh` (warns only) | A `Codable` member of `DayData`, `RecordedDayData`, `Meal`, `Workout`, `Mood` or `DayDataContainer` changed, but neither `HealthTracker/Data/Migration/` nor `DataMigrationTests` did | `AGENTS.md` Data Migrations |

`scripts/fitness/run` runs the first three, prints one `<check>: <file>[:<line>]: <message>` line per violation and then `N violation(s)`, and exits 1 if N > 0.

**Exceptions:** `scripts/fitness/test-mirror-exceptions.txt` lists the Domain/Data files allowed to have no mirrored test, one path per line with a reason. The check reports an entry as stale once its file has a test or is gone. Adding an entry is a deliberate decision, like adding a coverage exception: call it out in the PR.

**Where they run:**
- `scripts/fitness/run`: the Fitness gate of `scripts/quality` (both modes), the pre-commit hook (when a `.swift` or `.strings` file is staged), and the CI `lint` job.
- `persisted-shape-guard.sh <base-ref>`: the pre-push hook (against `origin/main`) and the CI `lint` job on PRs (against the PR's base, as `::warning` annotations). It never blocks. Answer a warning with a migration, or explain in the PR why none is needed.

## Git hooks

Enabled by `scripts/bootstrap`. They live in `.githooks/`.

**pre-commit** (a few seconds):
- refuses to commit on `main`;
- refuses when a staged `.swift` file also has unstaged changes, because re-staging after formatting would sweep those changes into the commit (stage or stash them first);
- formats the staged `.swift` files with SwiftFormat and re-stages them;
- lints them with `swiftlint --strict`, and fails on any violation;
- when a `.swift` or `.strings` file is staged, runs `scripts/fitness/run` on the staged snapshot (unstaged or `git add -N` tests and translations don't count), and fails on any violation.

**pre-push** (~2 min):
- refuses to push to `main`;
- runs `scripts/fitness/persisted-shape-guard.sh origin/main`, which only warns (also with `SKIP_QUALITY=1`);
- runs `scripts/quality --fast`, and blocks the push if a gate is red.

Emergency escape hatch, for humans only: `SKIP_QUALITY=1 git push` skips the gate (it prints a warning). CI still runs the gate on every push to the PR, drafts included. Use it rarely, and run `--full` before marking the PR ready.

## Xcode build phase

The app target's **SwiftLint** build phase runs `swiftlint lint --quiet`, so violations appear in Xcode's issue navigator: error-severity violations (the architecture rules, and metrics past their error limit) fail the build; the rest show as warnings. It **never** rewrites your files; formatting happens in the pre-commit hook. The phase is skipped when `CI=true`.

## Continuous integration

GitHub Actions re-runs the gate on GitHub's runners with the pinned tools, so a pass doesn't depend on one Mac's setup.

| Trigger | `lint` (Linux) | `test` (macOS) |
|---|---|---|
| PR, draft or ready (opened, pushed, reopened, or marked ready) | ✅ | `scripts/quality --full` |
| Push to `main` (a merge) | ✅ | `scripts/quality --fast` |
| Weekly, Mondays 06:00 UTC (`weekly.yml`) | none | `scripts/quality --full`; a red run opens an issue "Weekly quality gate failed" (or comments on the open one) |
| Manual (**Run workflow** in the Actions tab) | ✅ (`ci.yml`) | `scripts/quality --full` |

**`lint`** runs on `ubuntu-24.04` (~1 min). It installs the pinned SwiftLint and SwiftFormat (`scripts/ci/install-tools.sh`), checks formatting, lints, and runs the [fitness checks](#fitness-functions) (on PRs also the persisted-shape guard, which only warns). SwiftLint violations show inline on the PR diff; SwiftFormat failures show in the step log. Linux SwiftLint skips the rules that need SourceKit (`custom_rules`, `statement_position`), so this job is a fast pre-filter: the full lint runs again in `test`. It also runs ShellCheck on the scripts and hooks and actionlint on the workflows.

**`test`** runs only after `lint` passes, on `runs-on: xcode-27` (macOS 26). It selects the pinned Xcode (`scripts/ci/select-xcode.sh`) and installs the pinned tools. Then it runs the scripts' own tests (`scripts/tests/run`) and `scripts/quality` with `CI=true`, so `scripts/doctor` fails on any version drift and compiler warnings fail the build (`SWIFT_TREAT_WARNINGS_AS_ERRORS`, `GCC_TREAT_WARNINGS_AS_ERRORS`; locally they stay warnings). The gate table appears in the run's summary. Compile errors and test failures are rendered as GitHub annotations (`xcbeautify --renderer github-actions`).

**Cost.** The repo is public, and GitHub Actions is free for public repositories on standard GitHub-hosted runners, macOS included (`xcode-27` is a standard-size image); only larger runners are billed. Measured run times: a PR's `--full` ~23 min, a push to `main` (`--fast`) ~10–14 min, the weekly `--full` ~23 min. To keep feedback fast:

- the macOS job waits for the Linux `lint` job;
- a new push to a PR cancels the run it replaces (runs on `main` are never cancelled);
- changes that touch only docs or agent config (the `paths-ignore` list in `ci.yml`) skip CI;
- pushes to `main` run `--fast`, since the PR already ran `--full`;
- Dependabot PRs run only `lint`.

**Reading a failure:**

```bash
gh pr checks <n>                                            # which job failed
gh run view <run-id> --log-failed                           # the failing step's log
gh run download <run-id> -n xcresult-<run-id> -D build/ci   # test results and xcodebuild.log
```

The artifact is uploaded only when `test` fails, and kept for 7 days. Open `build/ci/Test.xcresult` in Xcode, or reproduce locally with `CI=true scripts/quality --full`, which stops first on any drift from `scripts/tool-versions.env`, the versions CI uses.

The `main` ruleset requires a PR but no status checks, so look at them before you approve and merge.

**Dependabot** (`.github/dependabot.yml`) opens one grouped PR a month that bumps the GitHub Actions; it runs only the `lint` job. Actions are pinned by commit SHA, with the version in a comment. Review and merge these like any other PR.

## Working with AI agents

Agents follow [`AGENTS.md`](AGENTS.md) (Quality Gates section) and the `quality-gate` skill, so they run the same commands you do:

- "Done" means `scripts/quality --full` exits 0; for a change touching only docs or agent config (the `paths-ignore` list in `ci.yml`), `scripts/quality --fast`. Agents paste the gate table into their report and PR.
- `.claude/settings.json` stops Claude Code from bypassing the gate. It denies:
  - `--no-verify` / `-n` and `git -c core.hooksPath`;
  - `SKIP_QUALITY=`;
  - pushes to `main` and force-pushes;
  - `gh pr merge`.
- A Claude Code hook (`.claude/hooks/format-swift.sh`) formats and lints every Swift file an agent edits, so it sees violations immediately. If SwiftFormat or SwiftLint can't run, the hook reports that as an error instead of passing.
- Agents open PRs as **draft**; every push runs CI, drafts included. They run `CI=true scripts/quality --full` locally, push, mark the PR ready (which re-runs CI against the current `main`) and wait for the checks. If `test` goes red, the agent reproduces it locally, fixes it and pushes again; a failure it can't reproduce locally, or a red run after a fix that was green locally, comes to you as a report instead. You review and merge.

## Script reference

| Path | Purpose |
|---|---|
| `scripts/quality` | The quality gate (see above) |
| `scripts/bootstrap` | One-time setup per clone or worktree: enables `.githooks`, installs the pinned tools into `build/tools/bin`, runs `doctor` |
| `scripts/doctor` | Compares installed tools with the pins. Warns locally, fails when `CI=true` |
| `scripts/tool-versions.env` | Pinned SwiftLint / SwiftFormat / Periphery / Xcode versions |
| `scripts/quality-thresholds.env` | Coverage thresholds and ratchets |
| `scripts/coverage-exceptions.txt` | Files grandfathered below the per-file floor |
| `scripts/fitness/` | [Fitness functions](#fitness-functions): the cross-file checks, `run`, and `test-mirror-exceptions.txt` |
| `scripts/lib/` | Pieces used by `scripts/quality` (coverage math, simulator picking, report table). Each has tests |
| `scripts/tests/run` | Runs every `scripts/tests/test-*.sh` (the scripts' own tests, no simulator needed) |
| `scripts/ci/` | CI helpers: `install-tools.sh` (pinned SwiftLint/SwiftFormat, and Periphery on macOS), `select-xcode.sh` (pinned Xcode), `summary.sh` (gate table for the job summary) |
| `.github/workflows/` | `ci.yml` (PRs, pushes to `main`), `weekly.yml` (schedule) and `claude-code-review.yml` (AI review of non-draft PRs, on Linux) |
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
| Unused code shows `n/a` | `periphery` is missing (run `scripts/bootstrap`) or the scan failed (its output is above the table) |
| Push takes ~2 min | That's the pre-push `--fast` gate building and running the unit tests |
| Too many `HT-*` simulators | `xcrun simctl list devices \| grep HT-`, then `xcrun simctl delete <name>` for branches you're done with |
| Coverage gate red after deleting tests or code | Add tests for the least-covered files (see [Fixing a red gate](#fixing-a-red-gate)). Don't lower the threshold silently |
