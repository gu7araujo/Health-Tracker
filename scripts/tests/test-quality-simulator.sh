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

# pick <fixture> <name> -> sets out, err, code
pick() {
  : >"$TMP/clones"
  out="$(PATH="$TMP/bin:$PATH" SIM_FIXTURE="$FIX/$1" CLONE_LOG="$TMP/clones" "$SIMULATOR" "$2" 2>"$TMP/err")"
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

[ "$failures" -eq 0 ]
