#!/usr/bin/env bash
# Tests scripts/lib/test-failures.sh against a fixture `xcresulttool get test-results tests` report.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FAILURES="$ROOT/scripts/lib/test-failures.sh"
FIX="$ROOT/scripts/tests/fixtures/quality/test-results.json"
failures=0

fail() {
  printf '  FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

# expect <bundle> <expected output>
expect() {
  local out
  out="$("$FAILURES" "$FIX" "$1" 2>&1)"
  [ "$out" = "$2" ] || fail "$1: expected [$2], got [$out]"
}

expect HealthTrackerTests 0
expect HealthTrackerUITests 3
expect MissingTests ""     # bundle never ran: unmeasured
expect CrashedTests ""     # bundle failed without a failing case (crash): unmeasured

# --list names each failed case (its nodeIdentifier, or suite/name) with its first failure message
# at any depth (a parameterized case nests it under Arguments), kept on one line.
out="$("$FAILURES" "$FIX" HealthTrackerUITests --list 2>&1)"
expected="MainViewUITests/testAddMeal(): MainViewUITests.swift:42: XCTAssertTrue failed
MainViewUITests/testAddWater(): MainViewUITests.swift:60: first line second line
MainViewUITests/testParameterized(_:): MainViewUITests.swift:70: nested failure"
[ "$out" = "$expected" ] || fail "--list: expected [$expected], got [$out]"
out="$("$FAILURES" "$FIX" HealthTrackerTests --list 2>&1)"
[ -z "$out" ] || fail "--list of a passing bundle should print nothing, got [$out]"

# --system lists only the failed cases in a "System Failures" suite, the test runner's own errors
# (#111: "Failed to establish communication with the test runner"), in --list's format.
RUNNER="$ROOT/scripts/tests/fixtures/quality/test-results-runner-error.json"
out="$("$FAILURES" "$RUNNER" HealthTrackerUITests --system 2>&1)"
expected="HealthTrackerUITests-Runner encountered an error: Failed to establish communication with the test runner. (Underlying Error: Channel disconnected)"
[ "$out" = "$expected" ] || fail "--system: expected [$expected], got [$out]"
[ "$("$FAILURES" "$RUNNER" MixedTests)" = 2 ] || fail "a runner error should count as a failed case"
out="$("$FAILURES" "$RUNNER" MixedTests --system 2>&1)"
[ "$out" = "MixedTests-Runner encountered an error: Failed to establish communication with the test runner. (Underlying Error: Channel disconnected)" ] ||
  fail "--system should leave out a test's own crash, got [$out]"
out="$("$FAILURES" "$FIX" HealthTrackerUITests --system 2>&1)"
[ -z "$out" ] || fail "--system of a bundle without runner errors should print nothing, got [$out]"

# Under -retry-tests-on-failure (#136) a case that failed, then passed on its retry, is a passed case
# with a failed "Repetition" child: not a failure, but listed by --retried with its first run's message.
RETRIED="$ROOT/scripts/tests/fixtures/quality/test-results-retried.json"
[ "$("$FAILURES" "$RETRIED" HealthTrackerUITests)" = 0 ] || fail "a case that passed on retry should count as passed"
out="$("$FAILURES" "$RETRIED" HealthTrackerUITests --retried 2>&1)"
expected="MainViewUITests/testAddMeal(): MainViewUITests.swift:42: Timed out while evaluating UI query"
[ "$out" = "$expected" ] || fail "--retried: expected [$expected], got [$out]"
[ "$("$FAILURES" "$RETRIED" MixedTests)" = 1 ] || fail "a case that failed its retry too should count as failed"
out="$("$FAILURES" "$RETRIED" MixedTests --retried 2>&1)"
[ "$out" = "MixedSuite/testFlaky(): MixedSuite.swift:10: flaked" ] ||
  fail "--retried should leave out a case that failed its retry too, got [$out]"
out="$("$FAILURES" "$RETRIED" MixedTests --list 2>&1)"
[ "$out" = "MixedSuite/testBroken(): MixedSuite.swift:20: broken" ] ||
  fail "--list should leave out a case that passed on retry, got [$out]"
out="$("$FAILURES" "$FIX" HealthTrackerUITests --retried 2>&1)"
[ -z "$out" ] || fail "--retried of a bundle without retries should print nothing, got [$out]"

out="$("$FAILURES" /nonexistent HealthTrackerTests 2>/dev/null)"
[ -z "$out" ] || fail "missing report should print nothing, got [$out]"

[ "$failures" -eq 0 ]
