#!/usr/bin/env bash
# scripts/ci/select-xcode.sh against a fake /Applications (XCODE_APPS_DIR) with a stubbed sudo:
# it must pick the app whose xcodebuild reports the pinned Xcode version.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$ROOT/scripts/ci/select-xcode.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
failures=0

fail() {
  printf '  FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

# shellcheck source=../tool-versions.env
source "$ROOT/scripts/tool-versions.env"

mkdir -p "$TMP/stubs"
printf '#!/bin/sh\necho "$*" >>"%s"\n' "$TMP/sudo.calls" >"$TMP/stubs/sudo"
chmod +x "$TMP/stubs/sudo"

# fake_xcode <app name> <version>: an app whose xcodebuild -version reports <version>.
fake_xcode() {
  local bin="$TMP/apps/$1/Contents/Developer/usr/bin"
  mkdir -p "$bin"
  printf '#!/bin/sh\necho "Xcode %s"\necho "Build version 1A1"\n' "$2" >"$bin/xcodebuild"
  chmod +x "$bin/xcodebuild"
}

select_xcode() {
  rm -f "$TMP/sudo.calls"
  out="$(XCODE_APPS_DIR="$TMP/apps" PATH="$TMP/stubs:$PATH" "$SCRIPT" 2>&1)"
  code=$?
}

# The runner names the pinned version's app after its release stage, beside lookalike versions.
fake_xcode Xcode_27.app 27.0
fake_xcode "Xcode_${XCODE_VERSION}0.app" "${XCODE_VERSION}0"
fake_xcode "Xcode_${XCODE_VERSION}_Release_Candidate.app" "$XCODE_VERSION"
select_xcode
want="$TMP/apps/Xcode_${XCODE_VERSION}_Release_Candidate.app"
[ "$code" -eq 0 ] || fail "should select the pinned Xcode (got $code): $out"
[ "$(cat "$TMP/sudo.calls" 2>/dev/null)" = "xcode-select -s $want" ] ||
  fail "should run sudo xcode-select -s $want, got: $(cat "$TMP/sudo.calls" 2>/dev/null)"
[ "$out" = "$want" ] || fail "should print the selected app, got: $out"

# No app reports the pinned version: fail and list what is there.
rm -rf "$TMP/apps/Xcode_${XCODE_VERSION}_Release_Candidate.app"
select_xcode
[ "$code" -ne 0 ] || fail "should fail without the pinned Xcode"
[ ! -e "$TMP/sudo.calls" ] || fail "should not run xcode-select without a match"
[[ "$out" == *"Xcode $XCODE_VERSION"* && "$out" == *"Xcode_27.app"* && "$out" == *"Xcode_${XCODE_VERSION}0.app"* ]] ||
  fail "should name the pin and list the installed apps, got: $out"

[ "$failures" -eq 0 ]
