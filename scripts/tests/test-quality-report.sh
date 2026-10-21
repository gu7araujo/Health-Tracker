#!/usr/bin/env bash
# Tests scripts/lib/report.sh: gate rows (TSV on stdin) -> table on stdout, optional JSON, exit code.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REPORT="$ROOT/scripts/lib/report.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
failures=0

fail() {
  printf '  FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

passing=$'Format\t0\t<=\t0\ttrue\nApp line coverage\t94.17\t>=\t90.0\ttrue'
failing=$'Format\t0\t<=\t0\ttrue\nUnit tests\tn/a\t<=\t0\tfalse\nApp line coverage\t89.50\t>=\t90.0\tfalse'

out="$("$REPORT" fast "$TMP/pass.json" <<<"$passing")"
code=$?
[ "$code" -eq 0 ] || fail "all passing should exit 0 (got $code)"
grep -qE '^App line coverage +94\.17% +>= 90\.0% +✓$' <<<"$out" || fail "coverage row should render as a percentage: $out"
grep -qE '^Format +0 +<= 0 +✓$' <<<"$out" || fail "count row should render plain: $out"
grep -qx '2/2 gates passed.' <<<"$out" || fail "should summarise 2/2: $out"
jq -e '.mode == "fast" and .passed == true and (.gates | length) == 2' "$TMP/pass.json" >/dev/null ||
  fail "pass JSON wrong: $(cat "$TMP/pass.json")"
jq -e '.gates[1] == {name: "App line coverage", value: 94.17, threshold: 90.0, comparator: ">=", passed: true}' \
  "$TMP/pass.json" >/dev/null || fail "gate JSON shape wrong: $(cat "$TMP/pass.json")"

out="$("$REPORT" full "$TMP/fail.json" <<<"$failing")"
code=$?
[ "$code" -eq 1 ] || fail "any failing gate should exit 1 (got $code)"
grep -qE '^Unit tests +n/a +<= 0 +✗$' <<<"$out" || fail "unavailable value should render n/a ✗: $out"
grep -qx '1/3 gates passed.' <<<"$out" || fail "should summarise 1/3: $out"
jq -e '.mode == "full" and .passed == false and .gates[1].value == null and .gates[2].passed == false' \
  "$TMP/fail.json" >/dev/null || fail "fail JSON wrong: $(cat "$TMP/fail.json")"

# Without a JSON path, only the table is printed.
out="$("$REPORT" fast <<<"$passing")"
[ $? -eq 0 ] || fail "report without JSON path should still exit 0"

[ "$failures" -eq 0 ]
