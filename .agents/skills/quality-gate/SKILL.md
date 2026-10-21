---
name: quality-gate
description: Run HealthTracker's quality gate (scripts/quality) and act on its result. Use when checking whether a task is done, when a gate is red (format, lint, tests, coverage), when finding the least-covered files, or when raising coverage thresholds.
---

# Quality gate

`scripts/quality` runs every gate once and prints a table; exit 0 means all passed. Thresholds live in `scripts/quality-thresholds.env`, per-file floor exceptions in `scripts/coverage-exceptions.txt`, usage in `scripts/quality --help`.

## 1. Run it

```bash
scripts/quality --fast --json   # iterate: format, lint, unit tests, Domain/Data unit coverage (~2 min)
scripts/quality --full --json   # done: adds UI tests, app coverage, per-file floor (~8 min)
```

It tests on `--simulator <udid>` when given; otherwise it reuses or clones a simulator named `HT-<branch>`, so parallel worktrees stay isolated. An exported `SIMULATOR_ID` is ignored on purpose. Delete the clone when the branch is done: `xcrun simctl delete "HT-<branch with / replaced by ->"`.

**Done when:** `scripts/quality --full` exits 0. Paste the table it prints into the final report and PR.

## 2. Read the result

`build/quality.json` holds one entry per gate; list the red ones:

```bash
jq -r '.gates[] | select(.passed | not) | "\(.name): \(.value) (needs \(.comparator) \(.threshold))"' build/quality.json
```

A `null` value (`n/a` in the table) means the metric could not be measured: the build failed or a test bundle crashed. Read `build/xcodebuild.log`.

The gate also prints details on stderr: format and lint violations with file and line, and `below floor: <path> <pct>%` for each file under the per-file floor.

## 3. Fix a red gate

Every gate turns green through code or tests:

- **Format**: run `swiftformat . --swift-version 6`.
- **Lint**: fix each reported violation (`swiftlint --fix` handles the autocorrectable ones).
- **Unit tests / UI tests**: the failures are in `build/xcodebuild.log`; reproduce one with the `cli-test` skill's single-test command.
- **Coverage**: add tests for the least-covered files (section 4) until the measured value clears the threshold.

Lowering a threshold, adding a path to `scripts/coverage-exceptions.txt`, or adding a `swiftlint:disable` is the user's call. When one is genuinely warranted, make it a separate, explicit line in the report and PR description with the reason.

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

The Domain/Data ratchets count only unit tests, so cover `HealthTracker/Domain/` and `HealthTracker/Data/` with unit tests; UI tests don't move them.

## 5. Ratchet the baseline

After raising Domain or Data unit coverage, lock the gain in:

```bash
scripts/quality --fast --update-baseline
```

It raises `DOMAIN_UNIT_MIN` / `DATA_UNIT_MIN` in `scripts/quality-thresholds.env` to the measured value (rounded down to one decimal) and keeps any threshold the measurement doesn't beat. Commit the changed thresholds file with the tests that earned it.
