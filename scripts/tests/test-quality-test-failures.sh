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
expect HealthTrackerUITests 2
expect MissingTests ""     # bundle never ran: unmeasured
expect CrashedTests ""     # bundle failed without a failing case (crash): unmeasured

# --list names each failed case (its nodeIdentifier, or suite/name) with its first failure message,
# kept on one line.
out="$("$FAILURES" "$FIX" HealthTrackerUITests --list 2>&1)"
expected="MainViewUITests/testAddMeal(): MainViewUITests.swift:42: XCTAssertTrue failed
MainViewUITests/testAddWater(): MainViewUITests.swift:60: first line second line"
[ "$out" = "$expected" ] || fail "--list: expected [$expected], got [$out]"
out="$("$FAILURES" "$FIX" HealthTrackerTests --list 2>&1)"
[ -z "$out" ] || fail "--list of a passing bundle should print nothing, got [$out]"

out="$("$FAILURES" /nonexistent HealthTrackerTests 2>/dev/null)"
[ -z "$out" ] || fail "missing report should print nothing, got [$out]"

[ "$failures" -eq 0 ]
