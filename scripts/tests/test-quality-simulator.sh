#!/usr/bin/env bash
# Tests scripts/lib/simulator.sh against a stubbed `xcrun simctl`.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SIMULATOR="$ROOT/scripts/lib/simulator.sh"
FIX="$ROOT/scripts/tests/fixtures/quality"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
failures=0

fail() {
  printf '  FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

# Stub xcrun: `simctl list ...` prints $SIM_FIXTURE; `simctl clone <src> <name>` logs and prints a new udid;
# `simctl delete <udid>` logs.
mkdir -p "$TMP/bin"
cat >"$TMP/bin/xcrun" <<'EOF'
#!/bin/sh
case "$2" in
  list) cat "$SIM_FIXTURE" ;;
  clone) echo "$3 $4" >>"$CLONE_LOG"; echo "CLONED" ;;
  delete) echo "delete $3" >>"$CLONE_LOG" ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$TMP/bin/xcrun"

# The fixtures pin "iPhone 17"; they need updating if SIMULATOR_DEVICE changes.
# shellcheck source=../tool-versions.env
source "$ROOT/scripts/tool-versions.env"
[ "$SIMULATOR_DEVICE" = "iPhone 17" ] || fail "fixtures expect SIMULATOR_DEVICE=\"iPhone 17\", got: $SIMULATOR_DEVICE"

# pick <fixture> <name> [<min-ios-major>] -> sets out, err, code. <fixture> is relative to $FIX, or absolute.
pick() {
  : >"$TMP/clones"
  local fixture="$1"
  [[ "$fixture" == /* ]] || fixture="$FIX/$fixture"
  out="$(PATH="$TMP/bin:$PATH" SIM_FIXTURE="$fixture" CLONE_LOG="$TMP/clones" "$SIMULATOR" "${@:2}" 2>"$TMP/err")"
  code=$?
  err="$(cat "$TMP/err")"
}

# No HT-<branch> yet: clone a shut-down pinned iPhone 17 from the newest iOS 26.x runtime, not the
# iPhone 17 Pro listed before it.
pick simulators.json HT-feature-x
[ "$code" -eq 0 ] || fail "clone should exit 0 (got $code)"
[ "$out" = "CLONED" ] || fail "should print the clone's udid, got: $out"
[ "$(cat "$TMP/clones")" = "SOURCE HT-feature-x" ] || fail "should clone SOURCE as HT-feature-x, got: $(cat "$TMP/clones")"
[[ "$err" != *warning* ]] || fail "a pinned clone should not warn, got: $err"

# The newest runtime has only an iPhone Duo (the xcode-27 CI image's iOS 27.1): skip it for the
# runtime that has the pinned iPhone 17.
pick simulators-duo.json HT-feature-x
[ "$(cat "$TMP/clones")" = "IPHONE-17 HT-feature-x" ] ||
  fail "should skip the Duo-only runtime for iOS 27.0's iPhone 17, got: $(cat "$TMP/clones")"

# No runtime has the pinned device: fall back to the first iPhone on the preferred runtime, and warn.
pick simulators-no-pin.json HT-other
[ "$code" -eq 0 ] || fail "fallback clone should exit 0 (got $code)"
[ "$(cat "$TMP/clones")" = "FALLBACK HT-other" ] ||
  fail "should fall back to the first iPhone on iOS 26.5, got: $(cat "$TMP/clones")"
[[ "$err" == *"warning: "*"iPhone 17"*"SIMULATOR_DEVICE"* ]] || fail "should warn naming the pin, got: $err"
[ "$(grep -c warning <<<"$err")" -eq 1 ] || fail "should warn in one line, got: $err"

# HT-<branch> exists and is the pinned model: reuse it, no clone.
pick simulators-existing.json HT-feature-x
[ "$code" -eq 0 ] || fail "reuse should exit 0 (got $code)"
[ "$out" = "EXISTING" ] || fail "should reuse EXISTING, got: $out"
[ ! -s "$TMP/clones" ] || fail "should not clone when the simulator exists"

# HT-<branch> exists as another model (cloned before the pin): delete it and clone the pinned one.
pick simulators-existing-other-model.json HT-feature-x
[ "$code" -eq 0 ] || fail "re-clone should exit 0 (got $code)"
[ "$out" = "CLONED" ] || fail "should print the new clone's udid, got: $out"
[ "$(cat "$TMP/clones")" = "$(printf 'delete EXISTING\nSOURCE HT-feature-x')" ] ||
  fail "should delete EXISTING, then clone SOURCE, got: $(cat "$TMP/clones")"

# HT-<branch> exists as another model but is booted (someone's session): keep it, and warn.
jq '.devices[][0].state = "Booted"' "$FIX/simulators-existing-other-model.json" >"$TMP/booted-other.json"
pick "$TMP/booted-other.json" HT-feature-x
[ "$out" = "EXISTING" ] || fail "should reuse a booted EXISTING of another model, got: $out"
[ ! -s "$TMP/clones" ] || fail "should not delete a booted clone, got: $(cat "$TMP/clones")"
[[ "$err" == *"warning: "*"Booted"*"iPhone 17"* ]] || fail "should warn that the booted clone is kept, got: $err"

# HT-<branch> exists and no runtime has the pinned device: keep it.
pick simulators-no-pin.json HT-feature-x
[ "$out" = "KEPT" ] || fail "should reuse KEPT when nothing matches the pin, got: $out"
[ ! -s "$TMP/clones" ] || fail "should not delete or clone without a pinned device, got: $(cat "$TMP/clones")"

# No iOS 26 runtime (e.g. a CI image with only iOS 27): fall back to the newest iOS runtime.
cat >"$TMP/only27.json" <<'EOF'
{"devices":{"com.apple.CoreSimulator.SimRuntime.iOS-27-0":[{"name":"iPhone 17","udid":"IOS27","state":"Shutdown"}]}}
EOF
: >"$TMP/clones"
out="$(PATH="$TMP/bin:$PATH" SIM_FIXTURE="$TMP/only27.json" CLONE_LOG="$TMP/clones" "$SIMULATOR" HT-x 2>/dev/null)"
[ "$(cat "$TMP/clones")" = "IOS27 HT-x" ] || fail "should fall back to the iOS 27 iPhone, got: $(cat "$TMP/clones")"

# No iOS iPhone at all: fail.
echo '{"devices":{}}' >"$TMP/empty.json"
: >"$TMP/clones"
out="$(PATH="$TMP/bin:$PATH" SIM_FIXTURE="$TMP/empty.json" CLONE_LOG="$TMP/clones" "$SIMULATOR" HT-x 2>/dev/null)"
[ $? -ne 0 ] || fail "no source iPhone should exit non-zero"

# A minimum iOS major (HealthTrackerIntentsUITests needs iOS 27): only runtimes from that major up
# qualify, so the iOS 27.0 iPhone 17 wins over the iOS 26.5 one the default prefers.
pick simulators.json HT-feature-x-ios27 27
[ "$code" -eq 0 ] || fail "a minimum-major clone should exit 0 (got $code)"
[ "$(cat "$TMP/clones")" = "IOS-27 HT-feature-x-ios27" ] ||
  fail "should clone iOS 27.0's iPhone 17, got: $(cat "$TMP/clones")"

# Among qualifying runtimes the newest wins (no iOS 26.x preference), still skipping a Duo-only one.
jq '.devices["com.apple.CoreSimulator.SimRuntime.iOS-28-0"] = [{"name":"iPhone 17","udid":"IOS-28","state":"Shutdown","deviceTypeIdentifier":"com.apple.CoreSimulator.SimDeviceType.iPhone-17"}]' \
  "$FIX/simulators.json" >"$TMP/with28.json"
pick "$TMP/with28.json" HT-x 27
[ "$(cat "$TMP/clones")" = "IOS-28 HT-x" ] || fail "should clone the newest qualifying runtime's iPhone 17, got: $(cat "$TMP/clones")"
pick simulators-duo.json HT-x 27
[ "$(cat "$TMP/clones")" = "IPHONE-17 HT-x" ] || fail "should skip the Duo-only iOS 27.1 for iOS 27.0, got: $(cat "$TMP/clones")"

# No pinned model from that major up: fall back to the first iPhone there, never one on iOS 26.
pick simulators-no-pin.json HT-other 27
[ "$(cat "$TMP/clones")" = "DUO HT-other" ] || fail "should fall back to iOS 27.1's iPhone, got: $(cat "$TMP/clones")"
[[ "$err" == *"warning: "*"iPhone 17"* ]] || fail "the fallback should warn naming the pin, got: $err"

# No runtime from that major up: fail without cloning, naming the major.
pick simulators-existing.json HT-x 27
[ "$code" -ne 0 ] || fail "no iOS 27+ iPhone should exit non-zero"
[ ! -s "$TMP/clones" ] || fail "should not clone or delete without an iOS 27+ iPhone, got: $(cat "$TMP/clones")"
[[ "$err" == *"error: "*"iOS 27"* ]] || fail "should name the minimum iOS major, got: $err"

# A major.minor minimum (scripts/quality passes the iphonesimulator SDK's version: Xcode 27.2's
# AppIntentsTesting needs iOS 27.2 symbols), compared numerically: 27.0 and 27.1 fall short, and
# 27.10 is newer than 27.2.
iphone() { printf '{"name":"%s","udid":"%s","state":"%s","deviceTypeIdentifier":"com.apple.CoreSimulator.SimDeviceType.%s"}' \
  "$1" "$2" "${3:-Shutdown}" "${4:-iPhone-17}"; }
cat >"$TMP/minor.json" <<EOF
{"devices":{
 "com.apple.CoreSimulator.SimRuntime.iOS-27-0":[$(iphone "iPhone 17" IOS-27-0)],
 "com.apple.CoreSimulator.SimRuntime.iOS-27-2":[$(iphone "iPhone 17" IOS-27-2)],
 "com.apple.CoreSimulator.SimRuntime.iOS-27-2-iPhone19-4":[$(iphone "iPhone Duo" DUO-27-2 Shutdown iPhone-Duo)]}}
EOF
pick "$TMP/minor.json" HT-x-ios27 27.2
[ "$code" -eq 0 ] || fail "a major.minor minimum should exit 0 (got $code): $err"
[ "$(cat "$TMP/clones")" = "IOS-27-2 HT-x-ios27" ] || fail "should clone iOS 27.2's iPhone 17, got: $(cat "$TMP/clones")"
jq '.devices["com.apple.CoreSimulator.SimRuntime.iOS-27-10"] = [{"name":"iPhone 17","udid":"IOS-27-10","state":"Shutdown","deviceTypeIdentifier":"com.apple.CoreSimulator.SimDeviceType.iPhone-17"}]' \
  "$TMP/minor.json" >"$TMP/minor10.json"
pick "$TMP/minor10.json" HT-x-ios27 27.2
[ "$(cat "$TMP/clones")" = "IOS-27-10 HT-x-ios27" ] || fail "27.10 should rank above 27.2, got: $(cat "$TMP/clones")"
pick simulators-duo.json HT-x-ios27 27.2
[ "$code" -ne 0 ] || fail "no iOS 27.2+ iPhone should exit non-zero"
[ ! -s "$TMP/clones" ] || fail "should not clone below the minimum, got: $(cat "$TMP/clones")"
[[ "$err" == *"error: "*"iOS 27.2"* ]] || fail "should name the minimum iOS version, got: $err"

# An existing <name> on a runtime below the minimum (cloned before the SDK moved on) is deleted and
# re-cloned; one at or above it is reused, and a major-only minimum still accepts any minor.
jq --argjson d "$(iphone HT-x-ios27 EXISTING)" '.devices["com.apple.CoreSimulator.SimRuntime.iOS-27-0"] += [$d]' \
  "$TMP/minor.json" >"$TMP/stale.json"
pick "$TMP/stale.json" HT-x-ios27 27.2
[ "$code" -eq 0 ] || fail "re-cloning a stale runtime should exit 0 (got $code): $err"
[ "$out" = "CLONED" ] || fail "should print the new clone's udid, got: $out"
[ "$(cat "$TMP/clones")" = "$(printf 'delete EXISTING\nIOS-27-2 HT-x-ios27')" ] ||
  fail "should delete the iOS 27.0 EXISTING, then clone iOS 27.2's iPhone 17, got: $(cat "$TMP/clones")"
[[ "$err" == *"Deleting simulator HT-x-ios27: "*"iOS 27.0"*"iOS 27.2"* ]] ||
  fail "should say it deletes the clone for its runtime, got: $err"
pick "$TMP/stale.json" HT-x-ios27 27
[ "$out" = "EXISTING" ] || fail "a major-only minimum should reuse the iOS 27.0 EXISTING, got: $out"
[ ! -s "$TMP/clones" ] || fail "should not delete or clone a qualifying clone, got: $(cat "$TMP/clones")"
jq --argjson d "$(iphone HT-x-ios27 EXISTING)" '.devices["com.apple.CoreSimulator.SimRuntime.iOS-27-2"] += [$d]' \
  "$TMP/minor.json" >"$TMP/current.json"
pick "$TMP/current.json" HT-x-ios27 27.2
[ "$out" = "EXISTING" ] || fail "should reuse an EXISTING on iOS 27.2, got: $out"
[ ! -s "$TMP/clones" ] || fail "should not delete or clone a clone on the minimum, got: $(cat "$TMP/clones")"
# Booted below the minimum (someone's session): keep it, and warn.
jq --argjson d "$(iphone HT-x-ios27 EXISTING Booted)" '.devices["com.apple.CoreSimulator.SimRuntime.iOS-27-0"] += [$d]' \
  "$TMP/minor.json" >"$TMP/stale-booted.json"
pick "$TMP/stale-booted.json" HT-x-ios27 27.2
[ "$out" = "EXISTING" ] || fail "should keep a booted EXISTING below the minimum, got: $out"
[ ! -s "$TMP/clones" ] || fail "should not delete a booted clone, got: $(cat "$TMP/clones")"
[[ "$err" == *"warning: "*"Booted"*"iOS 27.0"*"iOS 27.2"* ]] || fail "should warn that the booted clone is kept, got: $err"

[ "$failures" -eq 0 ]
