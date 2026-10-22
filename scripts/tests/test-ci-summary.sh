#!/usr/bin/env bash
# scripts/ci/summary.sh renders build/quality.json as Markdown for $GITHUB_STEP_SUMMARY.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$ROOT/scripts/ci/summary.sh"
FIX="$ROOT/scripts/tests/fixtures/ci"
failures=0

fail() {
  printf '  FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

# expect <output> <line>: the output must contain <line> as a whole line.
expect() {
  grep -qxF -- "$2" <<<"$1" || fail "missing line '$2' in:"$'\n'"$1"
}

out="$("$SCRIPT" "$FIX/quality-pass.json")" || fail "a passing report should exit 0"
expect "$out" "## ✅ Quality gate (full): passed"
expect "$out" "| Gate | Value | Threshold | Result |"
expect "$out" "|---|---|---|---|"
expect "$out" "| Format | 0 | <= 0 | ✅ |"
expect "$out" "| App line coverage | 91.5% | >= 90% | ✅ |"

out="$("$SCRIPT" "$FIX/quality-fail.json")" || fail "a failing report still renders and exits 0 (the gate step fails the job)"
expect "$out" "## ❌ Quality gate (fast): failed"
expect "$out" "| Lint | 3 | <= 0 | ❌ |"
expect "$out" "| Unit tests | n/a | <= 0 | ❌ |"
expect "$out" "| Domain unit line coverage | n/a | >= 95% | ❌ |"

# scripts/quality can stop before writing the report (e.g. doctor fails); say so instead of erroring.
out="$("$SCRIPT" "$FIX/missing.json")" || fail "a missing report should exit 0"
[[ "$out" == "## ❌ Quality gate: no report"* ]] || fail "a missing report should be called out, got: $out"

[ "$failures" -eq 0 ]
