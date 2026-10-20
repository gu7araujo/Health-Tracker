---
name: cli-test
description: Run HealthTracker's unit and/or UI tests from the command line with xcodebuild and read the coverage report. Use when the Xcode MCP test tools are unavailable or failing and you need to validate changes or find the least-covered files.
---

# Run HealthTracker tests from the CLI

Fallback for when the Xcode MCP test tools don't work. Pipe every command through `xcbeautify`.

## 1. Resolve a simulator id

Every `test` command needs a destination. List booted/available simulators and pick an iOS 26 one:
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

# A single file or test
xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,id=<simulator-id>' -only-testing:HealthTrackerTests/DayDataTests | xcbeautify
xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,id=<simulator-id>' -only-testing:HealthTrackerUITests/CalendarUITests/testTodaySelectedOnLaunchAndEmptyStates | xcbeautify
```

**Done when:** the run reports `Test Succeeded` with zero failures. That's the bar for a task being done.

## 3. Coverage report (when you need it)

`xcodebuild` errors out if `-resultBundlePath` already exists, so delete `build/` first:
```bash
rm -rf build && xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,id=<simulator-id>' -enableCodeCoverage YES -resultBundlePath build/Test.xcresult | xcbeautify
```

Then view it:
```bash
# Per-file line-coverage table (human-readable)
xcrun xccov view --report build/Test.xcresult

# Machine-readable JSON (per-target/per-file, for scripting)
xcrun xccov view --report --json build/Test.xcresult
```
The JSON exposes each target's `lineCoverage`, `coveredLines`, and `executableLines`, plus a per-file `files` array — sort by `lineCoverage` to find the least-covered files.
