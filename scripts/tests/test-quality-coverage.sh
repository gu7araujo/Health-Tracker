#!/usr/bin/env bash
# Tests scripts/lib/evaluate-coverage.sh and scripts/lib/update-baseline.sh against fixture xccov reports.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
EVALUATE="$ROOT/scripts/lib/evaluate-coverage.sh"
UPDATE="$ROOT/scripts/lib/update-baseline.sh"
FIX="$ROOT/scripts/tests/fixtures/quality"
TAB=$'\t'

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
failures=0

fail() {
  printf '  FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

# evaluate <mode> <fixture> [exceptions] -> sets out, err, code
evaluate() {
  out="$("$EVALUATE" "$1" "$FIX/$2" /repo "$FIX/thresholds.env" "$FIX/${3:-no-exceptions.txt}" 2>"$TMP/err")"
  code=$?
  err="$(cat "$TMP/err")"
}

# expect_row <name> <value> <comparator> <threshold> <passed>
expect_row() {
  local row="$1$TAB$2$TAB$3$TAB$4$TAB$5"
  grep -qxF "$row" <<<"$out" || fail "expected row [$row] in:
$out"
}

# --fast: unit Domain/Data gates only.
evaluate fast pass.json
[ "$code" -eq 0 ] || fail "fast pass should exit 0 (got $code)"
expect_row "Domain unit line coverage" 98.00 ">=" 95.0 true
expect_row "Data unit line coverage" 90.00 ">=" 85.0 true
[ "$(wc -l <<<"$out" | tr -d ' ')" -eq 2 ] || fail "fast should emit exactly 2 rows: $out"

evaluate fast app-below-90.json
[ "$code" -eq 1 ] || fail "fast with Domain below its ratchet should exit 1 (got $code)"
expect_row "Domain unit line coverage" 85.00 ">=" 95.0 false
expect_row "Data unit line coverage" 85.00 ">=" 85.0 true

# --full: app + per-file floor. Test-bundle files and 0-line files never count.
evaluate full pass.json
[ "$code" -eq 0 ] || fail "full pass should exit 0 (got $code)"
expect_row "App line coverage" 92.00 ">=" 90.0 true
expect_row "Per-file floor" 90.00 ">=" 80.0 true
[ "$(wc -l <<<"$out" | tr -d ' ')" -eq 2 ] || fail "full should emit exactly 2 rows: $out"

evaluate full app-below-90.json
[ "$code" -eq 1 ] || fail "full with app below 90 should exit 1 (got $code)"
expect_row "App line coverage" 85.00 ">=" 90.0 false
expect_row "Per-file floor" 85.00 ">=" 80.0 true

evaluate full file-below-floor.json
[ "$code" -eq 1 ] || fail "full with a file below the floor should exit 1 (got $code)"
expect_row "App line coverage" 95.00 ">=" 90.0 true
expect_row "Per-file floor" 70.00 ">=" 80.0 false
[[ "$err" == *"HealthTracker/Data/Migration/B.swift"*"70.00%"* ]] || fail "should name the offending file: $err"

evaluate full file-below-floor.json exceptions.txt
[ "$code" -eq 0 ] || fail "excepted file should not fail the floor (got $code)"
expect_row "Per-file floor" 100.00 ">=" 80.0 true

# A listed file that now meets the floor is a stale exception: it fails the floor so the list only shrinks.
evaluate full file-below-floor.json stale-exceptions.txt
[ "$code" -eq 1 ] || fail "a stale exception should fail the floor (got $code)"
expect_row "Per-file floor" 100.00 ">=" 80.0 false
[[ "$err" == *"stale exception: "*"stale-exceptions.txt:3: HealthTracker/Domain/A.swift 100.00%"* ]] ||
  fail "should name the stale entry: $err"
[[ "$err" != *"Migration/B.swift"* ]] || fail "B is still below the floor, so its entry is not stale: $err"

evaluate full views-excluded.json
[ "$code" -eq 0 ] || fail "Presentation/Views files should be excluded from the floor (got $code)"
expect_row "App line coverage" 91.82 ">=" 90.0 true
expect_row "Per-file floor" 100.00 ">=" 80.0 true

# --update-baseline: raises *_UNIT_MIN (rounded down to 0.1), never lowers, touches nothing else.
# The region ratchets take the measured Domain/Data region coverage as arguments.
cp "$FIX/baseline-thresholds.env" "$TMP/t.env"
"$UPDATE" "$FIX/unit-baseline.json" /repo "$TMP/t.env" 95.89 65.5 >/dev/null
grep -qx 'DOMAIN_UNIT_MIN=97.0' "$TMP/t.env" || fail "Domain ratchet should rise 96.0 -> 97.0: $(cat "$TMP/t.env")"
grep -qx 'DATA_UNIT_MIN=80.0' "$TMP/t.env" || fail "Data ratchet should stay 80.0 (measured 78.46): $(cat "$TMP/t.env")"
grep -qx 'DOMAIN_REGION_UNIT_MIN=95.8' "$TMP/t.env" ||
  fail "Domain region ratchet should rise 95.0 -> 95.8 (measured 95.89): $(cat "$TMP/t.env")"
grep -qx 'DATA_REGION_UNIT_MIN=70.0' "$TMP/t.env" ||
  fail "Data region ratchet should stay 70.0 (measured 65.5): $(cat "$TMP/t.env")"
diff <(grep -v UNIT_MIN "$FIX/baseline-thresholds.env") <(grep -v UNIT_MIN "$TMP/t.env") >/dev/null ||
  fail "update-baseline should not touch other lines"

[ "$failures" -eq 0 ]
