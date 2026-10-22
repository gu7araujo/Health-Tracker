#!/usr/bin/env bash
# Runs scripts/quality end to end in a throwaway repo copy, with stubbed
# swiftformat/swiftlint/xcrun/xcodebuild on PATH (no simulator, no real build).
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FIX="$ROOT/scripts/tests/fixtures/quality"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
failures=0

fail() {
  printf '  FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

# A repo on branch feat/x holding a copy of scripts/, with feat/x's own simulator available.
REPO="$TMP/repo"
git init -q -b feat/x "$REPO"
git -C "$REPO" -c user.name=t -c user.email=t@example.com -c commit.gpgsign=false commit -q --allow-empty -m init
cp -R "$ROOT/scripts" "$REPO/scripts"
printf 'APP_LINE_MIN=90.0\nFILE_FLOOR=80.0\nDOMAIN_UNIT_MIN=96.0\nDATA_UNIT_MIN=70.0\n' >"$REPO/scripts/quality-thresholds.env"
sed "s|/repo/|$REPO/|g" "$FIX/unit-baseline.json" >"$TMP/coverage.json"
cat >"$TMP/simulators.json" <<'EOF'
{"devices":{"com.apple.CoreSimulator.SimRuntime.iOS-26-5":[
  {"name":"HT-feat-x","udid":"WORKTREE-UDID","state":"Shutdown"},
  {"name":"iPhone 17 Pro","udid":"SHARED-UDID","state":"Shutdown"}]}}
EOF
printf '{"testNodes":[{"name":"HealthTracker","nodeType":"Test Plan","result":"Passed","children":[{"name":"HealthTrackerTests","nodeType":"Unit test bundle","result":"Passed","children":[]},{"name":"HealthTrackerUITests","nodeType":"UI test bundle","result":"Passed","children":[]}]}]}\n' >"$TMP/tests.json"

mkdir -p "$TMP/bin"
cat >"$TMP/bin/xcrun" <<EOF
#!/bin/sh
case "\$1 \$2" in
  "simctl list") cat "$TMP/simulators.json" ;;
  "xccov view") cat "$TMP/coverage.json" ;;
  "xcresulttool get") cat "$TMP/tests.json" ;;
  *) exit 0 ;;
esac
EOF
printf '#!/bin/sh\necho "$*" >>"%s"\n' "$TMP/xcodebuild.calls" >"$TMP/bin/xcodebuild"
printf '#!/bin/sh\ncat >/dev/null\n' >"$TMP/bin/xcbeautify"
printf '#!/bin/sh\necho "0/1 files require formatting."\n' >"$TMP/bin/swiftformat"
chmod +x "$TMP/bin/"*

# run_quality <lint json> [args...] -> sets out, code
run_quality() {
  printf '#!/bin/sh\necho %s\n' "'$1'" >"$TMP/bin/swiftlint"
  chmod +x "$TMP/bin/swiftlint"
  shift
  out="$(cd "$REPO" && PATH="$TMP/bin:$PATH" SIMULATOR_ID=SHARED-UDID "$REPO/scripts/quality" "$@" 2>&1)"
  code=$?
}

# An inherited SIMULATOR_ID (e.g. exported from ~/.zshrc) must not pull every worktree onto one device.
run_quality '[]' --fast
[[ "$out" == *"on simulator WORKTREE-UDID"* ]] || fail "should test on the worktree's HT-<branch> simulator, got: $out"

run_quality '[]' --fast --simulator EXPLICIT-UDID
[[ "$out" == *"on simulator EXPLICIT-UDID"* ]] || fail "--simulator should win, got: $out"

# --update-baseline must not lock in coverage from a red run.
before="$(cat "$REPO/scripts/quality-thresholds.env")"
run_quality '[{"file":"A.swift","line":1,"severity":"Error","reason":"r","rule_id":"x"}]' --fast --update-baseline
[ "$code" -eq 1 ] || fail "a lint violation should fail the gate (got $code)"
[ "$(cat "$REPO/scripts/quality-thresholds.env")" = "$before" ] || fail "--update-baseline raised thresholds on a red run"

run_quality '[]' --fast --update-baseline
[ "$(cat "$REPO/scripts/quality-thresholds.env")" != "$before" ] || fail "--update-baseline should raise thresholds on a green run: $out"

# --full is a superset of --fast: it also checks the Domain/Data unit ratchets, measured on a
# unit-only run, beside the app coverage and per-file floor measured on the merged runs.
: >"$TMP/xcodebuild.calls"
run_quality '[]' --full
for gate in "Unit tests" "UI tests" "Domain unit line coverage" "Data unit line coverage" "App line coverage" "Per-file floor"; do
  [[ "$out" == *"$gate "* ]] || fail "--full should report '$gate', got: $out"
done
[ "$(grep -c -- '-only-testing:HealthTrackerTests' "$TMP/xcodebuild.calls")" -eq 1 ] &&
  [ "$(grep -c -- '-only-testing:HealthTrackerUITests' "$TMP/xcodebuild.calls")" -eq 1 ] &&
  ! grep -q -- '-only-testing:HealthTrackerTests.*-only-testing:HealthTrackerUITests' "$TMP/xcodebuild.calls" ||
  fail "--full should run unit and UI tests as separate xcodebuild runs, got: $(cat "$TMP/xcodebuild.calls")"

[ "$failures" -eq 0 ]
