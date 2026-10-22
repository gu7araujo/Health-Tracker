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

out="$("$FAILURES" /nonexistent HealthTrackerTests 2>/dev/null)"
[ -z "$out" ] || fail "missing report should print nothing, got [$out]"

[ "$failures" -eq 0 ]
