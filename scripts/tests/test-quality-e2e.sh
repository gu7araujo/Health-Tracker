#!/usr/bin/env bash
# Runs scripts/quality end to end in a throwaway repo copy, with stubbed
# swiftformat/swiftlint/periphery/xcrun/xcodebuild on PATH (no simulator, no real build).
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
# thresholds [data-region-min]: the region-export fixture measures Domain 95% and Data 65%.
thresholds() {
  printf 'APP_LINE_MIN=90.0\nFILE_FLOOR=80.0\nDOMAIN_UNIT_MIN=96.0\nDATA_UNIT_MIN=70.0\n' >"$REPO/scripts/quality-thresholds.env"
  printf 'DOMAIN_REGION_UNIT_MIN=90.0\nDATA_REGION_UNIT_MIN=%s\n' "${1:-60.0}" >>"$REPO/scripts/quality-thresholds.env"
}
thresholds
sed "s|/repo/|$REPO/|g" "$FIX/unit-baseline.json" >"$TMP/coverage.json"
sed "s|/repo/|$REPO/|g" "$FIX/region-export.json" >"$TMP/regions.json"
cat >"$TMP/simulators.json" <<'EOF'
{"devices":{"com.apple.CoreSimulator.SimRuntime.iOS-26-5":[
  {"name":"HT-feat-x","udid":"WORKTREE-UDID","state":"Shutdown","deviceTypeIdentifier":"com.apple.CoreSimulator.SimDeviceType.iPhone-17"},
  {"name":"iPhone 17 Pro","udid":"SHARED-UDID","state":"Shutdown","deviceTypeIdentifier":"com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro"}],
 "com.apple.CoreSimulator.SimRuntime.iOS-27-0":[
  {"name":"iPhone 17","udid":"IOS27-UDID","state":"Shutdown","deviceTypeIdentifier":"com.apple.CoreSimulator.SimDeviceType.iPhone-17"}],
 "com.apple.CoreSimulator.SimRuntime.iOS-27-1":[
  {"name":"iPhone Duo","udid":"DUO-UDID","state":"Shutdown","deviceTypeIdentifier":"com.apple.CoreSimulator.SimDeviceType.iPhone-Duo"}]}}
EOF
printf '{"testNodes":[{"name":"HealthTracker","nodeType":"Test Plan","result":"Passed","children":[{"name":"HealthTrackerTests","nodeType":"Unit test bundle","result":"Passed","children":[]},{"name":"HealthTrackerUITests","nodeType":"UI test bundle","result":"Passed","children":[]},{"name":"HealthTrackerIntentsUITests","nodeType":"UI test bundle","result":"Passed","children":[]}]}]}\n' >"$TMP/tests.json"

mkdir -p "$TMP/bin"
cat >"$TMP/bin/xcrun" <<EOF
#!/bin/sh
case "\$1 \$2" in
  "simctl list") cat "$TMP/simulators.json" ;;
  "--sdk iphonesimulator") echo "\${SDK_VERSION:-27.0}" ;;
  "xccov view") cat "$TMP/coverage.json" ;;
  "llvm-cov export") echo "\$*" >>"$TMP/llvm-cov.calls" && cat "$TMP/regions.json" ;;
  "xcresulttool get") cat "$TMP/tests.json" ;;
  "simctl shutdown") echo "\$*" >>"$TMP/simctl.calls" ;;
  "simctl clone") echo "\$*" >>"$TMP/clone.calls" && echo CLONED-UDID ;;
  "simctl bootstatus") echo "\$*" >>"$TMP/boot.calls" ;;
  "xcresulttool merge") echo "\$*" >>"$TMP/merge.calls" ;;
  *) exit 0 ;;
esac
EOF
# xcodebuild: the unit run writes the profile and the app binary ($APP_BINARY, unless $NO_PROFILE);
# the UI run replaces the profile, so the region rows must read it in between.
cat >"$TMP/bin/xcodebuild" <<EOF
#!/bin/sh
echo "\$*" >>"$TMP/xcodebuild.calls"
app=build/DerivedData/Build/Products/Debug-iphonesimulator/HealthTracker.app
case "\$*" in
  *-only-testing:HealthTrackerTests*)
    [ -n "\$NO_PROFILE" ] && exit 0
    rm -rf "\$app" && mkdir -p build/DerivedData/Build/ProfileData/RUN "\$app"
    touch build/DerivedData/Build/ProfileData/RUN/Coverage.profdata "\$app/\${APP_BINARY:-HealthTracker.debug.dylib}" ;;
  *-only-testing:HealthTrackerUITests*) rm -rf build/DerivedData/Build/ProfileData ;;
esac
[ -z "\$INTERRUPT" ] || kill -TERM "\$PPID"
EOF
printf '#!/bin/sh\necho "$*" >>"%s"\ncat >/dev/null\n' "$TMP/xcbeautify.calls" >"$TMP/bin/xcbeautify"
printf '#!/bin/sh\necho "0/1 files require formatting."\n' >"$TMP/bin/swiftformat"
chmod +x "$TMP/bin/"*

# fitness_stub <exit> [lines...]: scripts/fitness/run prints the lines and exits <exit>. The copied
# repo has no app sources for the real checks to read, so every run_quality uses a stub.
fitness_stub() {
  local code="$1"
  shift
  { printf '#!/bin/sh\n'; printf "echo '%s'\n" "$@"; printf 'exit %s\n' "$code"; } >"$REPO/scripts/fitness/run"
  chmod +x "$REPO/scripts/fitness/run"
}
fitness_stub 0 '0 violation(s)'

# periphery_stub <exit> [lines...]: periphery logs its args, prints the lines and exits <exit>.
periphery_stub() {
  printf '%s\n' "${@:2}" >"$TMP/periphery.out"
  printf '#!/bin/sh\necho "$*" >>"%s"\ncat "%s"\nexit %s\n' "$TMP/periphery.calls" "$TMP/periphery.out" "$1" \
    >"$TMP/bin/periphery"
  chmod +x "$TMP/bin/periphery"
}
periphery_stub 0

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

# A first run on the xcode-27 CI image, whose newest runtime (iOS 27.1) has only an iPhone Duo,
# clones the pinned iPhone 17 from iOS 27.0.
cp "$TMP/simulators.json" "$TMP/simulators.json.orig"
cp "$FIX/simulators-duo.json" "$TMP/simulators.json"
run_quality '[]' --fast
[ "$(cat "$TMP/clone.calls")" = "simctl clone IPHONE-17 HT-feat-x" ] ||
  fail "should clone iOS 27.0's iPhone 17 as HT-feat-x, got: $(cat "$TMP/clone.calls" 2>/dev/null)"
[[ "$out" == *"on simulator CLONED-UDID"* ]] || fail "should test on the new clone, got: $out"
mv "$TMP/simulators.json.orig" "$TMP/simulators.json"

# The log names the device model and iOS runtime, so a CI log shows which iOS the tests ran on.
run_quality '[]' --fast
[[ "$out" == *"on simulator WORKTREE-UDID (iPhone 17, iOS 26.5) "* ]] ||
  fail "should log the simulator's model and runtime, got: $out"
run_quality '[]' --fast --simulator DUO-UDID
[[ "$out" == *"on simulator DUO-UDID (iPhone Duo, iOS 27.1) "* ]] ||
  fail "should log --simulator's model and runtime, got: $out"

# A simulator scripts/quality booted itself is shut down when it exits (green, red or interrupted),
# so booted HT-<branch> clones never pile up; the clone itself is kept for reuse.
for case in green red interrupted; do
  : >"$TMP/simctl.calls"
  lint='[]'
  [ "$case" = red ] && lint='[{"file":"A.swift","line":1,"severity":"Error","reason":"r","rule_id":"x"}]'
  INTERRUPT="$([ "$case" = interrupted ] && echo 1)" run_quality "$lint" --fast
  [ "$(cat "$TMP/simctl.calls")" = "simctl shutdown WORKTREE-UDID" ] ||
    fail "a $case run should shut down the simulator it booted, got: $(cat "$TMP/simctl.calls")"
done
[ "$code" -ne 0 ] || fail "an interrupted run should exit non-zero"
# One the caller chose, or one already booted (a session in use), is left running.
: >"$TMP/simctl.calls"
run_quality '[]' --fast --simulator EXPLICIT-UDID
[ ! -s "$TMP/simctl.calls" ] || fail "--simulator's device should stay booted, got: $(cat "$TMP/simctl.calls")"
sim_state() { sed -i.bak "s/\"WORKTREE-UDID\",\"state\":\"[A-Za-z ]*\"/\"WORKTREE-UDID\",\"state\":\"$1\"/" "$TMP/simulators.json"; }
sim_state Booted
: >"$TMP/simctl.calls"
run_quality '[]' --fast
[[ "$out" == *"on simulator WORKTREE-UDID"* ]] || fail "should still test on an already booted simulator, got: $out"
[ ! -s "$TMP/simctl.calls" ] || fail "an already booted simulator should stay booted, got: $(cat "$TMP/simctl.calls")"
# simctl states can hold a space ("Shutting Down"); the log still names the model and runtime.
sim_state "Shutting Down"
run_quality '[]' --fast
[[ "$out" == *"on simulator WORKTREE-UDID (iPhone 17, iOS 26.5) "* ]] ||
  fail "a two-word state should not garble the simulator's model and runtime, got: $out"
sim_state Shutdown

# --update-baseline must not lock in coverage from a red run.
before="$(cat "$REPO/scripts/quality-thresholds.env")"
run_quality '[{"file":"A.swift","line":1,"severity":"Error","reason":"r","rule_id":"x"}]' --fast --update-baseline
[ "$code" -eq 1 ] || fail "a lint violation should fail the gate (got $code)"
[ "$(cat "$REPO/scripts/quality-thresholds.env")" = "$before" ] || fail "--update-baseline raised thresholds on a red run"

run_quality '[]' --fast --update-baseline
[ "$(cat "$REPO/scripts/quality-thresholds.env")" != "$before" ] || fail "--update-baseline should raise thresholds on a green run: $out"
grep -qx 'DOMAIN_REGION_UNIT_MIN=95.0' "$REPO/scripts/quality-thresholds.env" &&
  grep -qx 'DATA_REGION_UNIT_MIN=65.0' "$REPO/scripts/quality-thresholds.env" ||
  fail "--update-baseline should raise the region ratchets: $(cat "$REPO/scripts/quality-thresholds.env")"
thresholds

# Fitness: a "<= 0" gate on the cross-file checks' violation count, right after Lint, whose
# violations go to the terminal like lint's.
run_quality '[]' --fast
[ "$code" -eq 0 ] || fail "a clean fitness run should pass the gate (got $code): $out"
grep -qE '^Fitness +0  <= 0 +✓$' <<<"$out" || fail "--fast should report a passing Fitness row, got: $out"
[ "$(grep -E '^(Lint|Fitness) ' <<<"$out" | cut -d' ' -f1 | tr '\n' ' ')" = "Lint Fitness " ] ||
  fail "the Fitness row should come right after Lint, got: $out"
fitness_stub 1 'localization-parity: pt-BR.lproj/Localizable.strings: missing key "k" (present in en.lproj)' \
  'test-mirror: HealthTracker/Domain/A.swift: no HealthTrackerTests/**/ATests.swift' '2 violation(s)'
run_quality '[]' --fast
[ "$code" -eq 1 ] || fail "fitness violations should fail the gate (got $code)"
grep -qE '^Fitness +2  <= 0 +✗$' <<<"$out" || fail "--fast should report a failing Fitness row of 2, got: $out"
[[ "$out" == *'missing key "k"'*"no HealthTrackerTests/**/ATests.swift"* ]] ||
  fail "fitness violations should be printed, got: $out"
fitness_stub 2 'boom'
run_quality '[]' --fast
grep -qE '^Fitness +n/a  <= 0 +✗$' <<<"$out" || fail "a fitness run without a count should report n/a, got: $out"
fitness_stub 0 '0 violation(s)'

# --full is a superset of --fast: it also checks the Domain/Data unit ratchets, measured on a
# unit-only run, beside the app coverage and per-file floor measured on the merged runs.
: >"$TMP/xcodebuild.calls"
run_quality '[]' --full
for gate in "Fitness" "Unit tests" "UI tests" "Domain unit line coverage" "Data unit line coverage" \
  "Domain unit region coverage" "Data unit region coverage" "App line coverage" "Per-file floor"; do
  [[ "$out" == *"$gate "* ]] || fail "--full should report '$gate', got: $out"
done
[ "$(grep -c -- '-only-testing:HealthTrackerTests' "$TMP/xcodebuild.calls")" -eq 1 ] &&
  [ "$(grep -c -- '-only-testing:HealthTrackerUITests' "$TMP/xcodebuild.calls")" -eq 1 ] &&
  ! grep -q -- '-only-testing:HealthTrackerTests.*-only-testing:HealthTrackerUITests' "$TMP/xcodebuild.calls" ||
  fail "--full should run unit and UI tests as separate xcodebuild runs, got: $(cat "$TMP/xcodebuild.calls")"

# --full also runs HealthTrackerIntentsUITests, which needs iOS 27 (AppIntentsTesting), into its own
# bundle and an "Intents UI tests" row right after "UI tests". The gate's iOS 26.5 simulator cannot
# load it, so a second clone, HT-<branch>-ios27, is fetched, booted first, and shut down on exit.
: >"$TMP/xcodebuild.calls"
: >"$TMP/clone.calls"
: >"$TMP/boot.calls"
: >"$TMP/simctl.calls"
: >"$TMP/merge.calls"
run_quality '[]' --full
grep -qE '^Intents UI tests +0  <= 0 +✓$' <<<"$out" || fail "--full should report a passing Intents UI tests row, got: $out"
[ "$(grep -E '^(UI tests|Intents UI tests|Unused code) ' <<<"$out" | cut -c1-11 | tr '\n' '|')" = \
  "UI tests   |Intents UI |Unused code|" ] || fail "the Intents UI tests row should come right after UI tests, got: $out"
[ "$(cat "$TMP/clone.calls")" = "simctl clone IOS27-UDID HT-feat-x-ios27" ] ||
  fail "should clone iOS 27.0's iPhone 17 as HT-feat-x-ios27, got: $(cat "$TMP/clone.calls")"
grep -q -- '-destination platform=iOS Simulator,id=CLONED-UDID -only-testing:HealthTrackerIntentsUITests .*-resultBundlePath build/Intents.xcresult' \
  "$TMP/xcodebuild.calls" || fail "should run the intents bundle on the iOS 27 clone, got: $(cat "$TMP/xcodebuild.calls")"
! grep -q -- 'id=CLONED-UDID -only-testing:HealthTracker\(UI\)\{0,1\}Tests ' "$TMP/xcodebuild.calls" ||
  fail "unit and UI tests should stay on the gate's simulator, got: $(cat "$TMP/xcodebuild.calls")"
grep -q 'bootstatus CLONED-UDID -b' "$TMP/boot.calls" || fail "should boot the iOS 27 clone first, got: $(cat "$TMP/boot.calls")"
[ "$(sort "$TMP/simctl.calls" | tr '\n' '|')" = "simctl shutdown CLONED-UDID|simctl shutdown WORKTREE-UDID|" ] ||
  fail "should shut down both simulators it booted, got: $(cat "$TMP/simctl.calls")"
grep -q -- '--output-path build/Test.xcresult build/Unit.xcresult build/UI.xcresult build/Intents.xcresult$' "$TMP/merge.calls" ||
  fail "app coverage should merge the unit, UI and intents runs, got: $(cat "$TMP/merge.calls")"
[[ "$out" == *"HealthTrackerIntentsUITests on simulator CLONED-UDID"* ]] ||
  fail "should log the simulator the intents run uses, got: $out"
# --fast never needs it.
: >"$TMP/clone.calls"
run_quality '[]' --fast
[ ! -s "$TMP/clone.calls" ] || fail "--fast should not clone an iOS 27 simulator, got: $(cat "$TMP/clone.calls")"
! grep -q 'Intents UI tests' <<<"$out" || fail "--fast should not report an Intents UI tests row, got: $out"

# A gate simulator already on iOS 27+ runs the intents bundle too: no second clone.
: >"$TMP/xcodebuild.calls"
: >"$TMP/clone.calls"
run_quality '[]' --full --simulator DUO-UDID
[ ! -s "$TMP/clone.calls" ] || fail "an iOS 27 --simulator should not need a clone, got: $(cat "$TMP/clone.calls")"
grep -q -- 'id=DUO-UDID -only-testing:HealthTrackerIntentsUITests ' "$TMP/xcodebuild.calls" ||
  fail "should run the intents bundle on the iOS 27 --simulator, got: $(cat "$TMP/xcodebuild.calls")"

# An iOS 26 --simulator still gets the iOS 27 clone; only the clone this run booted is shut down.
: >"$TMP/xcodebuild.calls"
: >"$TMP/clone.calls"
: >"$TMP/simctl.calls"
run_quality '[]' --full --simulator WORKTREE-UDID
[ "$(cat "$TMP/clone.calls")" = "simctl clone IOS27-UDID HT-feat-x-ios27" ] ||
  fail "an iOS 26 --simulator should still fetch the iOS 27 clone, got: $(cat "$TMP/clone.calls")"
grep -q -- 'id=CLONED-UDID -only-testing:HealthTrackerIntentsUITests ' "$TMP/xcodebuild.calls" ||
  fail "should run the intents bundle on the iOS 27 clone, got: $(cat "$TMP/xcodebuild.calls")"
[ "$(cat "$TMP/simctl.calls")" = "simctl shutdown CLONED-UDID" ] ||
  fail "should shut down only the clone it booted, got: $(cat "$TMP/simctl.calls")"

# An iOS 27 clone already booted (someone's session) stays up.
cp "$TMP/simulators.json" "$TMP/simulators.json.orig"
jq '.devices["com.apple.CoreSimulator.SimRuntime.iOS-27-0"] += [{"name":"HT-feat-x-ios27","udid":"IOS27-CLONE","state":"Booted","deviceTypeIdentifier":"com.apple.CoreSimulator.SimDeviceType.iPhone-17"}]' \
  "$TMP/simulators.json.orig" >"$TMP/simulators.json"
: >"$TMP/simctl.calls"
run_quality '[]' --full
grep -q -- 'id=IOS27-CLONE -only-testing:HealthTrackerIntentsUITests ' "$TMP/xcodebuild.calls" ||
  fail "should reuse the existing HT-feat-x-ios27, got: $(cat "$TMP/xcodebuild.calls")"
[ "$(cat "$TMP/simctl.calls")" = "simctl shutdown WORKTREE-UDID" ] ||
  fail "an already booted iOS 27 clone should stay booted, got: $(cat "$TMP/simctl.calls")"

# No iOS 27+ iPhone at all: the gate fails with an n/a row and says why, rather than skipping it.
jq '.devices |= with_entries(select(.key | test("iOS-27") | not))' "$TMP/simulators.json.orig" >"$TMP/simulators.json"
: >"$TMP/xcodebuild.calls"
run_quality '[]' --full
[ "$code" -eq 1 ] || fail "--full without an iOS 27 simulator should fail the gate (got $code)"
grep -qE '^Intents UI tests +n/a  <= 0 +✗$' <<<"$out" || fail "should report an n/a Intents UI tests row, got: $out"
[[ "$out" == *"error: "*"HealthTrackerIntentsUITests"*"iOS 27"* ]] || fail "should say the intents run needs iOS 27, got: $out"
! grep -q 'HealthTrackerIntentsUITests' "$TMP/xcodebuild.calls" ||
  fail "should not run the intents bundle without a simulator, got: $(cat "$TMP/xcodebuild.calls")"
mv "$TMP/simulators.json.orig" "$TMP/simulators.json"

# The intents run needs a runtime at least the iphonesimulator SDK's version, not just iOS 27:
# Xcode 27.2's AppIntentsTesting fails to load on iOS 27.0 (missing iOS 27.2 symbols).
cp "$TMP/simulators.json" "$TMP/simulators.json.orig"
jq '.devices["com.apple.CoreSimulator.SimRuntime.iOS-27-2"] = [{"name":"iPhone 17","udid":"IOS272-UDID","state":"Shutdown","deviceTypeIdentifier":"com.apple.CoreSimulator.SimDeviceType.iPhone-17"}]' \
  "$TMP/simulators.json.orig" >"$TMP/simulators.json"
: >"$TMP/xcodebuild.calls"
: >"$TMP/clone.calls"
SDK_VERSION=27.2 run_quality '[]' --full
[ "$(cat "$TMP/clone.calls")" = "simctl clone IOS272-UDID HT-feat-x-ios27" ] ||
  fail "with the 27.2 SDK, should clone iOS 27.2's iPhone 17, got: $(cat "$TMP/clone.calls")"
grep -q -- 'id=CLONED-UDID -only-testing:HealthTrackerIntentsUITests ' "$TMP/xcodebuild.calls" ||
  fail "should run the intents bundle on the iOS 27.2 clone, got: $(cat "$TMP/xcodebuild.calls")"
# An iOS 27.1 --simulator is iOS 27+ but below the 27.2 SDK: the intents run gets the clone instead.
: >"$TMP/xcodebuild.calls"
: >"$TMP/clone.calls"
SDK_VERSION=27.2 run_quality '[]' --full --simulator DUO-UDID
[ "$(cat "$TMP/clone.calls")" = "simctl clone IOS272-UDID HT-feat-x-ios27" ] ||
  fail "an iOS 27.1 --simulator should not run the 27.2 SDK's intents bundle, got: $(cat "$TMP/clone.calls")"
grep -q -- 'id=CLONED-UDID -only-testing:HealthTrackerIntentsUITests ' "$TMP/xcodebuild.calls" ||
  fail "should run the intents bundle on the iOS 27.2 clone, got: $(cat "$TMP/xcodebuild.calls")"
grep -q -- 'id=DUO-UDID -only-testing:HealthTrackerUITests ' "$TMP/xcodebuild.calls" ||
  fail "UI tests should stay on --simulator, got: $(cat "$TMP/xcodebuild.calls")"
# One on the SDK's version is reused, and versions compare numerically (27.10 >= 27.2).
: >"$TMP/xcodebuild.calls"
: >"$TMP/clone.calls"
SDK_VERSION=27.2 run_quality '[]' --full --simulator IOS272-UDID
[ ! -s "$TMP/clone.calls" ] || fail "an iOS 27.2 --simulator should not need a clone, got: $(cat "$TMP/clone.calls")"
grep -q -- 'id=IOS272-UDID -only-testing:HealthTrackerIntentsUITests ' "$TMP/xcodebuild.calls" ||
  fail "should run the intents bundle on the iOS 27.2 --simulator, got: $(cat "$TMP/xcodebuild.calls")"
jq '.devices["com.apple.CoreSimulator.SimRuntime.iOS-27-10"] = [{"name":"iPhone 17","udid":"IOS2710-UDID","state":"Shutdown","deviceTypeIdentifier":"com.apple.CoreSimulator.SimDeviceType.iPhone-17"}]' \
  "$TMP/simulators.json.orig" >"$TMP/simulators.json"
: >"$TMP/xcodebuild.calls"
: >"$TMP/clone.calls"
SDK_VERSION=27.2 run_quality '[]' --full --simulator IOS2710-UDID
[ ! -s "$TMP/clone.calls" ] || fail "an iOS 27.10 --simulator meets the 27.2 SDK, got: $(cat "$TMP/clone.calls")"
# A booted HT-<branch>-ios27 below the SDK's version is kept by simulator.sh, but not used.
jq '.devices["com.apple.CoreSimulator.SimRuntime.iOS-27-0"] += [{"name":"HT-feat-x-ios27","udid":"STALE-CLONE","state":"Booted","deviceTypeIdentifier":"com.apple.CoreSimulator.SimDeviceType.iPhone-17"}]' \
  "$TMP/simulators.json.orig" >"$TMP/simulators.json"
: >"$TMP/xcodebuild.calls"
SDK_VERSION=27.2 run_quality '[]' --full
grep -qE '^Intents UI tests +n/a  <= 0 +✗$' <<<"$out" || fail "a booted iOS 27.0 clone should give an n/a row, got: $out"
! grep -q 'HealthTrackerIntentsUITests' "$TMP/xcodebuild.calls" ||
  fail "should not run the intents bundle on an iOS 27.0 clone, got: $(cat "$TMP/xcodebuild.calls")"
# No iPhone on iOS 27.2+: fail with n/a, naming the version needed and how to install it.
cp "$TMP/simulators.json.orig" "$TMP/simulators.json"
: >"$TMP/xcodebuild.calls"
SDK_VERSION=27.2 run_quality '[]' --full
[ "$code" -eq 1 ] || fail "--full without an iOS 27.2 simulator should fail the gate (got $code)"
grep -qE '^Intents UI tests +n/a  <= 0 +✗$' <<<"$out" || fail "should report an n/a Intents UI tests row, got: $out"
[[ "$out" == *"error: HealthTrackerIntentsUITests"*"iOS 27.2"*"xcodebuild -downloadPlatform iOS"* ]] ||
  fail "should name the iOS version needed and the fix, got: $out"
! grep -q 'HealthTrackerIntentsUITests' "$TMP/xcodebuild.calls" ||
  fail "should not run the intents bundle without a simulator, got: $(cat "$TMP/xcodebuild.calls")"
mv "$TMP/simulators.json.orig" "$TMP/simulators.json"

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

# The gate builds into its own DerivedData, never the IDE's, so the index store Periphery reads
# is the one this run just wrote: build/DerivedData/Index.noindex/DataStore.
: >"$TMP/xcodebuild.calls"
run_quality '[]' --full
[ "$(grep -c -- '-derivedDataPath build/DerivedData' "$TMP/xcodebuild.calls")" -eq 3 ] ||
  fail "every xcodebuild test run should pass -derivedDataPath build/DerivedData, got: $(cat "$TMP/xcodebuild.calls")"

# Unused code: a "<= 0" gate on Periphery's findings, read from the index the unit-test run built,
# right after the test rows, in --fast and --full.
: >"$TMP/periphery.calls"
run_quality '[]' --fast
[ "$code" -eq 0 ] || fail "a clean periphery scan should pass the gate (got $code): $out"
grep -qE '^Unused code +0  <= 0 +✓$' <<<"$out" || fail "--fast should report a passing Unused code row, got: $out"
[ "$(grep -E '^(Unit tests|Unused code|Domain unit line coverage) ' <<<"$out" | cut -c1-11 | tr '\n' '|')" = \
  "Unit tests |Unused code|Domain unit|" ] || fail "the Unused code row should come right after Unit tests, got: $out"
[ "$(cat "$TMP/periphery.calls")" = "scan --skip-build --index-store-path build/DerivedData/Index.noindex/DataStore --quiet" ] ||
  fail "periphery should scan the gate's index store, got: $(cat "$TMP/periphery.calls")"
run_quality '[]' --full
grep -qE '^Unused code +0  <= 0 +✓$' <<<"$out" || fail "--full should report the Unused code row, got: $out"

periphery_stub 1 'Error: Found 2 issues.' \
  "HealthTracker/A.swift:3:10: warning: Unused function 'a()'" \
  "HealthTracker/B.swift:7:6: warning: Property 'b' is assigned, but never used"
run_quality '[]' --fast
[ "$code" -eq 1 ] || fail "unused code should fail the gate (got $code)"
grep -qE '^Unused code +2  <= 0 +✗$' <<<"$out" || fail "--fast should report a failing Unused code row of 2, got: $out"
[[ "$out" == *"A.swift:3:10: warning: Unused function"*"B.swift:7:6: warning: Property"* ]] ||
  fail "periphery findings should be printed, got: $out"

# On GitHub Actions the findings become inline PR annotations.
periphery_stub 1 'Error: Found 1 issue.' '::warning file=HealthTracker/A.swift,line=3,col=10,title=unused::Unused function'
: >"$TMP/periphery.calls"
GHA=true run_quality '[]' --fast
grep -q -- '--quiet --format github-actions$' "$TMP/periphery.calls" ||
  fail "on GitHub Actions periphery should use --format github-actions, got: $(cat "$TMP/periphery.calls")"
grep -qE '^Unused code +1  <= 0 +✗$' <<<"$out" || fail "a github-actions finding should count, got: $out"

# A scan that fails without findings (e.g. no index store) cannot be measured.
periphery_stub 1 'error: Index store path does not exist'
run_quality '[]' --fast
grep -qE '^Unused code +n/a  <= 0 +✗$' <<<"$out" || fail "a broken scan should report n/a, got: $out"
[[ "$out" == *"Index store path does not exist"* ]] || fail "a broken scan should print its output, got: $out"

# Missing periphery: n/a and a failed row (doctor has already said how to install it). Directories
# holding a real periphery (CI puts one on PATH) are dropped from PATH.
rm "$TMP/bin/periphery"
nopath="$(tr ':' '\n' <<<"$PATH" | while read -r dir; do [ -x "$dir/periphery" ] || printf '%s:' "$dir"; done)"
PATH="${nopath%:}" run_quality '[]' --fast
grep -qE '^Unused code +n/a  <= 0 +✗$' <<<"$out" || fail "a missing periphery should report n/a, got: $out"
[ "$code" -eq 1 ] || fail "a missing periphery should fail the gate (got $code)"

# build/tools/bin (where `scripts/ci/install-tools.sh build/tools/bin` installs the pinned tools)
# goes first on PATH, so a fresh clone needs no Homebrew.
mkdir -p "$REPO/build/tools/bin"
printf '#!/bin/sh\necho "$*" >>"%s"\n' "$TMP/local-periphery.calls" >"$REPO/build/tools/bin/periphery"
chmod +x "$REPO/build/tools/bin/periphery"
PATH="${nopath%:}" run_quality '[]' --fast
[ -s "$TMP/local-periphery.calls" ] || fail "scripts/quality should run tools from build/tools/bin, got: $out"
grep -qE '^Unused code +0  <= 0 +✓$' <<<"$out" || fail "build/tools/bin/periphery should pass the row, got: $out"
rm -rf "${REPO:?}/build/tools"
periphery_stub 0

# Region coverage: Domain/Data region ratchets on the unit run's profile (llvm-cov), read before the
# UI run replaces it, in --fast and --full. A stale profile from an earlier run never counts.
mkdir -p "$REPO/build/DerivedData/Build/ProfileData/AAA-STALE"
touch "$REPO/build/DerivedData/Build/ProfileData/AAA-STALE/Coverage.profdata"
: >"$TMP/llvm-cov.calls"
run_quality '[]' --fast
[ "$code" -eq 0 ] || fail "region coverage above its ratchets should pass the gate (got $code): $out"
grep -qE '^Domain unit region coverage +95.00%  >= 90.0% +✓$' <<<"$out" &&
  grep -qE '^Data unit region coverage +65.00%  >= 60.0% +✓$' <<<"$out" ||
  fail "--fast should report passing region rows, got: $out"
app=build/DerivedData/Build/Products/Debug-iphonesimulator/HealthTracker.app
[ "$(cat "$TMP/llvm-cov.calls")" = "llvm-cov export -summary-only -instr-profile \
build/DerivedData/Build/ProfileData/RUN/Coverage.profdata $app/HealthTracker.debug.dylib" ] ||
  fail "llvm-cov should read this run's profile and the app's debug dylib, got: $(cat "$TMP/llvm-cov.calls")"
# The stub UI run deletes the profile, so passing rows prove they were read after the unit run.
run_quality '[]' --full
grep -qE '^Domain unit region coverage +95.00%  >= 90.0% +✓$' <<<"$out" &&
  grep -qE '^Data unit region coverage +65.00%  >= 60.0% +✓$' <<<"$out" ||
  fail "--full should report region rows from the unit run, got: $out"

# Without a debug dylib (ENABLE_DEBUG_DYLIB=NO) the code lives in the app executable.
: >"$TMP/llvm-cov.calls"
APP_BINARY=HealthTracker run_quality '[]' --fast
[ "$(cat "$TMP/llvm-cov.calls")" = "llvm-cov export -summary-only -instr-profile \
build/DerivedData/Build/ProfileData/RUN/Coverage.profdata $app/HealthTracker" ] ||
  fail "llvm-cov should fall back to the app executable, got: $(cat "$TMP/llvm-cov.calls")"

thresholds 70.0
run_quality '[]' --fast
[ "$code" -eq 1 ] || fail "region coverage below its ratchet should fail the gate (got $code)"
grep -qE '^Data unit region coverage +65.00%  >= 70.0% +✗$' <<<"$out" || fail "should report a failing Data region row, got: $out"
thresholds

NO_PROFILE=1 run_quality '[]' --fast
[ "$code" -eq 1 ] || fail "a run without a profile should fail the gate (got $code)"
grep -qE '^Domain unit region coverage +n/a  >= 90.0% +✗$' <<<"$out" &&
  grep -qE '^Data unit region coverage +n/a  >= 60.0% +✗$' <<<"$out" ||
  fail "a run without a profile should report n/a region rows, got: $out"

[ "$failures" -eq 0 ]
