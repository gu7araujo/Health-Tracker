#!/usr/bin/env bash
# Tests scripts/quality argument parsing (runs before any tool, so no xcodebuild is needed).
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
QUALITY="$ROOT/scripts/quality"
failures=0

fail() {
  printf '  FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

out="$("$QUALITY" --help 2>&1)"
[ $? -eq 0 ] || fail "--help should exit 0"
[[ "$out" == *"Usage: scripts/quality"* ]] || fail "--help should print usage: $out"

out="$("$QUALITY" --bogus 2>&1)"
[ $? -eq 2 ] || fail "unknown flag should exit 2"
[[ "$out" == *"Usage: scripts/quality"* ]] || fail "unknown flag should print usage: $out"

out="$("$QUALITY" --simulator 2>&1)"
[ $? -eq 2 ] || fail "--simulator without a udid should exit 2"

out="$("$QUALITY" --full --update-baseline 2>&1)"
[ $? -eq 2 ] || fail "--update-baseline with --full should exit 2 (ratchets are unit-only)"

[ "$failures" -eq 0 ]
