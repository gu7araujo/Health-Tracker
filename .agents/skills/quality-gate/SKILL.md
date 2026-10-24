---
name: quality-gate
description: Run HealthTracker's quality gate (scripts/quality) and act on its result. Use when checking whether a task is done, when a gate or CI check is red (format, lint, fitness, tests, unused code, coverage), when finding the least-covered files, or when raising coverage thresholds.
---

# Quality gate

`scripts/quality` runs every gate once and prints a table; exit 0 means all passed. Thresholds live in `scripts/quality-thresholds.env`, per-file floor exceptions in `scripts/coverage-exceptions.txt`, usage in `scripts/quality --help`. The per-file floor fails on a `stale exception` (a listed file now at or above `FILE_FLOOR`): delete that line from the exceptions file.

## 1. Run it

```bash
scripts/quality --fast --json   # iterate: format, lint, fitness, unit tests, unused code, Domain/Data unit line + region coverage (~2 min)
scripts/quality --full --json   # done: everything in --fast, plus UI tests, app coverage, per-file floor (~8 min)
```

It tests on `--simulator <udid>` when given; otherwise it reuses or clones a simulator named `HT-<branch>`, so parallel worktrees stay isolated. An exported `SIMULATOR_ID` is ignored on purpose. Delete the clone when the branch is done: `xcrun simctl delete "HT-<branch with / replaced by ->"`.

**Done when:** `scripts/quality --full` exits 0. Paste the table it prints into the final report and PR. Before marking a PR ready, run it as `CI=true scripts/quality --full`: only `CI=true` turns compiler warnings into errors, as CI does, so a warning that passes locally fails the ready run.

## 2. Read the result

`build/quality.json` holds one entry per gate; list the red ones:

```bash
jq -r '.gates[] | select(.passed | not) | "\(.name): \(.value) (needs \(.comparator) \(.threshold))"' build/quality.json
```

A `null` value (`n/a` in the table) means the metric could not be measured: the build failed or a test bundle crashed. Read `build/xcodebuild.log`. A region row alone at `n/a` means the unit run left no `Coverage.profdata` or app binary at the section 4 paths, or `llvm-cov` failed.

The gate also prints details on stderr: format and lint violations with file and line, and `below floor: <path> <pct>%` for each file under the per-file floor.

## 3. Fix a red gate

Every gate turns green through code or tests:

- **Format**: run `swiftformat . --swift-version 6`.
- **Lint**: fix each reported violation (`swiftlint --fix` handles the autocorrectable ones). Every rule, its limits and its path scope live in the root `.swiftlint.yml`; test targets relax a few rules in their nested `.swiftlint.yml`.
  - A **custom rule** (`domain_no_ui_frameworks`, `presentation_no_data_layer`, ...) is an architecture rule: its message names the `AGENTS.md` rule it enforces. Read that rule and restructure the code to follow it.
  - A **metrics** violation (`closure_body_length`, `cyclomatic_complexity`, `function_body_length`, ...) means split the code: extract a SwiftUI subview, a helper, or a type.
  - `.swiftlint-baseline.json` freezes the pre-existing violations, matched by file, rule, line text and message, so editing a baselined closure or function can resurface its violation. Fix it then, and regenerate the baseline in the same commit with the command in `AGENTS.md` (Quality Gates).
- **Fitness**: `scripts/fitness/run` prints each violation as `<check>: <file>[:<line>]: <message>`:
  - `localization-parity`, `missing key "k"` / `missing file`: add that key (or `.strings` file) to the named locale, translated.
  - `test-mirror`, `no HealthTrackerTests/**/<Name>Tests.swift`: write that test file for the Domain/Data type. `... is not a unique name`: put the test at the mirrored path the message names. `stale exception`: delete that line from `scripts/fitness/test-mirror-exceptions.txt`.
  - `accessibility-ids`, `"<id>" not declared in HealthTracker/Presentation/AccessibilityID.swift`: make the UI tests' `AccessibilityID` match the app's (rename or remove the stale ID, or add the identifier to the app).
- **Unit tests / UI tests**: the failures are in `build/xcodebuild.log`; reproduce one with the `cli-test` skill's single-test command.
- **Unused code**: Periphery prints each finding on stderr as `<file>:<line>:<col>: warning: <finding>` (e.g. `Unused function 'name()'`, `Assign-only property`).
  - Delete the declaration, with any mock member or test that only exercises it. A protocol requirement goes from the protocol, its conformers and its mock together.
  - Used only through something Periphery cannot see (a generated `$binding` of an iOS 27 `@State` property, reflection): put `// periphery:ignore - <reason>` on the line above it and call it out (end of this section).
  - `n/a`: the scan failed (no index store, bad `.periphery.yml`) or `periphery` is missing; a failed scan prints its output above the table. Run `scripts/bootstrap`: it installs the pinned binary into `build/tools/bin`, where `scripts/quality` looks first.
  - Re-scan alone with `periphery scan --skip-build --index-store-path build/DerivedData/Index.noindex/DataStore` (`.periphery.yml` supplies the rest). It reads the index of the last gate run, so it misses edits made since; the next `scripts/quality` run rebuilds it.
- **Coverage**: add tests for the least-covered files (section 4) until the measured value clears the threshold. Deleting covered dead code (Unused code) can drop a Domain/Data ratchet below its threshold: answer with tests for the code that remains.

`persisted-shape-guard: ... warning: persisted shape changed` (pre-push, or a PR annotation) never fails a gate: add a migration (`AGENTS.md`, Data Migrations), or say in the PR why the change needs none.

Lowering a threshold, adding a path to `scripts/coverage-exceptions.txt` or `scripts/fitness/test-mirror-exceptions.txt`, adding a `swiftlint:disable` or `// periphery:ignore`, or regenerating the lint baseline to absorb a new violation is the user's call. When one is genuinely warranted, make it a separate, explicit line in the report and PR description with the reason.

## 4. Find the least-covered files

After any run, `build/Test.xcresult` holds the coverage (`--fast`: unit tests only; `--full`: unit + UI):

```bash
xcrun xccov view --report --json build/Test.xcresult | jq -r '.targets[]
  | select(.name == "HealthTracker.app") | .files | sort_by(.lineCoverage) | .[:10][]
  | "\(.lineCoverage * 100 | floor)%\t\(.executableLines - .coveredLines) uncovered\t\(.path | sub(".*/HealthTracker/"; "HealthTracker/"))"'
```

Then list a file's uncovered lines (execution count `0`; `*` is not executable):

```bash
xcrun xccov view --archive --file "$PWD/<repo-relative path>" build/Test.xcresult | grep -E ': 0$'
```

A red **region** row (`Domain unit region coverage`, `Data unit region coverage`) means some region never ran. Regions are finer than lines: they also catch a path inside a line that line coverage counts as covered, such as the default of `?? 0` or one side of `&&` / `?:`. List them from the unit run's profile (a `--full` run replaces it with the UI run's, so read it after `--fast`):

```bash
profdata=$(ls build/DerivedData/Build/ProfileData/*/Coverage.profdata)
binary=build/DerivedData/Build/Products/Debug-iphonesimulator/HealthTracker.app/HealthTracker.debug.dylib
xcrun llvm-cov report -instr-profile "$profdata" "$binary" "$PWD/HealthTracker/Domain" "$PWD/HealthTracker/Data"
xcrun llvm-cov show -show-line-counts-or-regions -instr-profile "$profdata" "$binary" "$PWD/<repo-relative path>" | grep -B1 -E '\| +0\||\^0'
```

`report` gives each file's `Missed Regions`. In `show`, a line with count `0` never ran at all, and a `^0` marker under a run line points at the column of the region inside it that never ran. Write a unit test that takes each path. A region no input can reach (a `?? 0` behind an earlier check that already returned) is dead code; report it to the user instead of testing it.

The Domain/Data ratchets count only unit tests, so cover `HealthTracker/Domain/` and `HealthTracker/Data/` with unit tests; UI tests don't move them.

## 5. Ratchet the baseline

After raising Domain or Data unit line or region coverage, lock the gain in:

```bash
scripts/quality --fast --update-baseline
```

It raises `DOMAIN_UNIT_MIN` / `DATA_UNIT_MIN` and `DOMAIN_REGION_UNIT_MIN` / `DATA_REGION_UNIT_MIN` in `scripts/quality-thresholds.env` to the measured value (rounded down to one decimal) and keeps any threshold the measurement doesn't beat. Commit the changed thresholds file with the tests that earned it.

A **new** threshold (a new gate, or a value set by hand) waits for one CI run: set it to the lower of the local and CI measurements, since CI's runner can measure less than a local run.

## 6. CI

CI (`.github/workflows/ci.yml`) runs the same gate. CI installs the pinned tools with `scripts/ci/install-tools.sh` and selects the pinned Xcode with `scripts/ci/select-xcode.sh`. A local pass only counts when `scripts/doctor` reports the same versions as `scripts/tool-versions.env`.

Read a red run:

```bash
gh pr checks <n>                  # which job is red: lint (Linux) or test (macOS)
gh run view <run-id> --log-failed # the failing step's log
```

The run's job summary shows the same gate table as `build/quality.json`. When `test` fails, the run uploads `build/*.xcresult` and `build/xcodebuild.log` as artifact `xcresult-<run-id>`:

```bash
gh run download <run-id> -n xcresult-<run-id> -D build/ci
```

Run the section 4 `xccov` commands on `build/ci/Test.xcresult`.

A red run on `main` (push or weekly): reproduce on `main` with `scripts/quality --fast` (push) or `--full` (weekly), then fix it on a branch through a PR, or report it to the user.

A red `test` on a ready PR spends a ready run (~11 macOS min; at most two per PR without the user's go-ahead):

1. `gh pr ready <n> --undo` first, so further pushes run only `lint`.
2. Reproduce locally with `CI=true scripts/quality --full`.
3. Reproduced: fix the gate as in section 3 until `--full` is green, push, and mark the PR ready once more (after the push's run starts, as in `AGENTS.md`).
4. Stop and report to the user (run link, failing step, suspected cause) when the failure does not reproduce locally (runner image, missing pinned Xcode or tool, a test flaky only on the runner), or when the second ready run is red too.

**Done when:** `gh pr checks <n>` shows every check green, or the user has the report from step 4.
