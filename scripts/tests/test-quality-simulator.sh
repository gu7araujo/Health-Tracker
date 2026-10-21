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

# Stub xcrun: `simctl list ...` prints $SIM_FIXTURE; `simctl clone <src> <name>` logs and prints a new udid.
mkdir -p "$TMP/bin"
cat >"$TMP/bin/xcrun" <<'EOF'
#!/bin/sh
case "$2" in
  list) cat "$SIM_FIXTURE" ;;
  clone) echo "$3 $4" >>"$CLONE_LOG"; echo "CLONED" ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$TMP/bin/xcrun"

# pick <fixture> <name> -> sets out, code
pick() {
  : >"$TMP/clones"
  out="$(PATH="$TMP/bin:$PATH" SIM_FIXTURE="$FIX/$1" CLONE_LOG="$TMP/clones" "$SIMULATOR" "$2" 2>/dev/null)"
  code=$?
}

# No HT-<branch> yet: clone a shut-down iPhone from the newest iOS 26.x runtime.
pick simulators.json HT-feature-x
[ "$code" -eq 0 ] || fail "clone should exit 0 (got $code)"
[ "$out" = "CLONED" ] || fail "should print the clone's udid, got: $out"
[ "$(cat "$TMP/clones")" = "SOURCE HT-feature-x" ] || fail "should clone SOURCE as HT-feature-x, got: $(cat "$TMP/clones")"

# HT-<branch> exists: reuse it, no clone.
pick simulators-existing.json HT-feature-x
[ "$code" -eq 0 ] || fail "reuse should exit 0 (got $code)"
[ "$out" = "EXISTING" ] || fail "should reuse EXISTING, got: $out"
[ ! -s "$TMP/clones" ] || fail "should not clone when the simulator exists"

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
