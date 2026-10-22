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
printf '#!/bin/sh\necho "$*" >>"%s"\ncat >/dev/null\n' "$TMP/xcbeautify.calls" >"$TMP/bin/xcbeautify"
printf '#!/bin/sh\necho "0/1 files require formatting."\n' >"$TMP/bin/swiftformat"
chmod +x "$TMP/bin/"*

# run_quality <lint json> [args...] -> sets out, code. CI comes from $CI_ENV (cleared by default: the
# stubs are not the pinned versions, so doctor would fail) and GITHUB_ACTIONS from $GHA, so the test
# behaves the same inside a GitHub Actions job.
run_quality() {
  printf '#!/bin/sh\necho %s\n' "'$1'" >"$TMP/bin/swiftlint"
  chmod +x "$TMP/bin/swiftlint"
  shift
  out="$(cd "$REPO" && PATH="$TMP/bin:$PATH" SIMULATOR_ID=SHARED-UDID CI="${CI_ENV:-}" GITHUB_ACTIONS="${GHA:-}" \
    "$REPO/scripts/quality" "$@" 2>&1)"
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

# Locally xcbeautify keeps its terminal renderer; on GitHub Actions it emits inline PR annotations.
: >"$TMP/xcbeautify.calls"
run_quality '[]' --fast
[ "$(cat "$TMP/xcbeautify.calls")" = "--quieter --disable-logging" ] ||
  fail "locally xcbeautify should run with --quieter only, got: $(cat "$TMP/xcbeautify.calls")"
: >"$TMP/xcbeautify.calls"
GHA=true run_quality '[]' --fast
[ "$(cat "$TMP/xcbeautify.calls")" = "--quieter --disable-logging --renderer github-actions" ] ||
  fail "on GitHub Actions xcbeautify should use the github-actions renderer, got: $(cat "$TMP/xcbeautify.calls")"

# CI fails the build on compiler warnings; locally they stay warnings.
: >"$TMP/xcodebuild.calls"
run_quality '[]' --fast
! grep -q 'TREAT_WARNINGS_AS_ERRORS' "$TMP/xcodebuild.calls" ||
  fail "locally warnings should not be errors, got: $(cat "$TMP/xcodebuild.calls")"
printf '#!/bin/sh\nexit 0\n' >"$REPO/scripts/doctor" # strict doctor would reject the stubbed tools
: >"$TMP/xcodebuild.calls"
CI_ENV=true run_quality '[]' --fast
grep -q -- 'SWIFT_TREAT_WARNINGS_AS_ERRORS=YES GCC_TREAT_WARNINGS_AS_ERRORS=YES' "$TMP/xcodebuild.calls" ||
  fail "with CI=true xcodebuild should treat warnings as errors, got: $(cat "$TMP/xcodebuild.calls")"

[ "$failures" -eq 0 ]
