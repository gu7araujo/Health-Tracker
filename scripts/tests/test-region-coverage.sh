#!/usr/bin/env bash
# Tests scripts/lib/region-coverage.sh against a fixture `llvm-cov export -summary-only` report,
# with a stubbed xcrun on PATH.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REGIONS="$ROOT/scripts/lib/region-coverage.sh"
FIX="$ROOT/scripts/tests/fixtures/quality/region-export.json"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
failures=0

fail() {
  printf '  FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

mkdir -p "$TMP/bin"
printf '#!/bin/sh\necho "$*" >>"%s"\ncat "%s"\n' "$TMP/xcrun.calls" "$FIX" >"$TMP/bin/xcrun"
chmod +x "$TMP/bin/xcrun"
touch "$TMP/Coverage.profdata" "$TMP/HealthTracker.debug.dylib"

# regions <profdata> <binary> -> sets out, code
regions() {
  out="$(PATH="$TMP/bin:$PATH" "$REGIONS" "$1" "$2" /repo 2>/dev/null)"
  code=$?
}

# Domain: (29 + 9) / (30 + 10) regions; Data: (7 + 6) / (14 + 6). Presentation, generated
# sources and files outside <repo-root> never count.
regions "$TMP/Coverage.profdata" "$TMP/HealthTracker.debug.dylib"
[ "$code" -eq 0 ] || fail "should exit 0 (got $code)"
[ "$(awk '{ printf "%.2f|", $1 }' <<<"$out")" = "95.00|65.00|" ] ||
  fail "should print Domain then Data region coverage, got [$out]"
[ "$(cat "$TMP/xcrun.calls" 2>/dev/null)" = \
  "llvm-cov export -summary-only -instr-profile $TMP/Coverage.profdata $TMP/HealthTracker.debug.dylib" ] ||
  fail "should export the profdata's summary for the binary, got: $(cat "$TMP/xcrun.calls" 2>/dev/null)"

# Unmeasurable: n/a (no output).
regions "$TMP/missing.profdata" "$TMP/HealthTracker.debug.dylib"
[ -z "$out" ] || fail "a missing profdata should print nothing, got [$out]"
regions "$TMP/Coverage.profdata" "$TMP/missing"
[ -z "$out" ] || fail "a missing binary should print nothing, got [$out]"
printf '#!/bin/sh\necho "error: no coverage data found" >&2\nexit 1\n' >"$TMP/bin/xcrun"
regions "$TMP/Coverage.profdata" "$TMP/HealthTracker.debug.dylib"
[ -z "$out" ] || fail "a failed llvm-cov export should print nothing, got [$out]"

[ "$failures" -eq 0 ]
