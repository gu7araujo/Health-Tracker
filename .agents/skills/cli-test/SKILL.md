---
name: cli-test
description: Run HealthTracker's unit and/or UI tests from the command line with xcodebuild. Use when the Xcode MCP test tools are unavailable or failing and you need to validate changes or run a single test.
---

# Run HealthTracker tests from the CLI

Fallback for when the Xcode MCP test tools don't work. Pipe every command through `xcbeautify`.

## 1. Resolve a simulator id

Every `test` command needs a destination. List booted/available simulators and pick an iOS 26 one. `HealthTrackerIntentsUITests` deploys to iOS 27, so xcodebuild skips it on iOS 26 ("Cannot test target…"), and its `AppIntentsTesting` needs a runtime at the SDK's version (`xcrun --sdk iphonesimulator --show-sdk-version`; on iOS 27.0, Xcode 27.2's fails with "Symbol not found"): pick a simulator on that iOS to run it:
```bash
xcrun simctl list devices
```
Substitute its UDID for `<simulator-id>` below.

**When other agents may be testing in parallel** ([`AGENTS.md` → Parallel agents](../../../AGENTS.md#parallel-agents)), run on a simulator of your own:

```bash
xcrun simctl clone <shut-down-simulator-id> "HT-<branch-name>"   # prints the new UDID: your <simulator-id>
```

and append `-parallel-testing-enabled NO` to every `xcodebuild test` below. The scheme marks its test targets parallelizable, so by default a run spreads over clones from Xcode's shared pool, which another worktree's run tears down when it finishes. Isolated, two worktrees' full suites pass side by side, though with UI tests serialized each takes ~17 min instead of ~4, so iterate on unit tests and run the full suite once at the end. Remove the simulator when the work is done: `xcrun simctl delete "HT-<branch-name>"`.

## 2. Run the tests

Scope the run to what you changed — unit tests are fast, UI tests are slow (each launches the app on the simulator).

```bash
# All tests
xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,id=<simulator-id>' | xcbeautify

# Unit tests only (fast)
xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,id=<simulator-id>' -only-testing:HealthTrackerTests | xcbeautify

# UI tests only (slow)
xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,id=<simulator-id>' -only-testing:HealthTrackerUITests | xcbeautify

# App Intents UI tests only (needs a simulator on the SDK's iOS version, e.g. 27.2)
xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,id=<ios-27-simulator-id>' -only-testing:HealthTrackerIntentsUITests | xcbeautify

# A single file or test
xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,id=<simulator-id>' -only-testing:HealthTrackerTests/DayDataTests | xcbeautify
xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,id=<simulator-id>' -only-testing:HealthTrackerUITests/CalendarUITests/testTodaySelectedOnLaunchAndEmptyStates | xcbeautify
```

**Done when:** the run reports `Test Succeeded` with zero failures. The bar for a task being done is `scripts/quality --full` exiting 0, or `--fast` for a change touching only docs or agent config (`paths-ignore` in `.github/workflows/ci.yml`; `quality-gate` skill).

## 3. Coverage report (when you need it)

`scripts/quality` measures coverage and gates it against the thresholds: `--fast` for unit-only Domain/Data coverage, `--full` for unit + UI. Each run leaves `build/Test.xcresult` behind; finding the least-covered files and their uncovered lines from it is in the `quality-gate` skill.
