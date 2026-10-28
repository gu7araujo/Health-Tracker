#!/usr/bin/env bash
# Tests scripts/doctor against stubbed tool binaries.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=../tool-versions.env
source "$ROOT/scripts/tool-versions.env"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
# Runs a copy of scripts/, so this checkout's own build/tools/bin stays out of the lookup.
mkdir -p "$TMP/repo/scripts/lib"
cp "$ROOT/scripts/doctor" "$ROOT/scripts/tool-versions.env" "$TMP/repo/scripts/"
cp "$ROOT/scripts/lib/tools-path.sh" "$TMP/repo/scripts/lib/"
DOCTOR="$TMP/repo/scripts/doctor"
failures=0

fail() {
  printf '  FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

# stub <dir> <swiftlint version> <swiftformat version> <xcode version> <periphery version>
stub() {
  mkdir -p "$1"
  printf '#!/bin/sh\necho %s\n' "$2" >"$1/swiftlint"
  printf '#!/bin/sh\necho %s\n' "$3" >"$1/swiftformat"
  printf '#!/bin/sh\n[ "$1" = version ] && echo %s\n' "$5" >"$1/periphery"
  printf '#!/bin/sh\necho "Xcode %s"\necho "Build version X"\n' "$4" >"$1/xcodebuild"
  printf '#!/bin/sh\n' >"$1/xcbeautify"
  printf '#!/bin/sh\n' >"$1/jq"
  chmod +x "$1"/*
}

# run_doctor <stub dir> [CI value] -> sets out, code
run_doctor() {
  out="$(PATH="$1:/usr/bin:/bin" CI="${2:-}" "$DOCTOR" 2>&1)"
  code=$?
}

stub "$TMP/ok" "$SWIFTLINT_VERSION" "$SWIFTFORMAT_VERSION" "$XCODE_VERSION" "$PERIPHERY_VERSION"
stub "$TMP/drift" "0.1.0" "0.2.0" "1.0" "0.3.0"

# Matching versions: silent success, locally and in CI.
run_doctor "$TMP/ok"
[ "$code" -eq 0 ] || fail "matching versions should exit 0 (got $code)"
[[ "$out" != *warning* ]] || fail "matching versions should not warn: $out"
run_doctor "$TMP/ok" true
[ "$code" -eq 0 ] || fail "matching versions in CI should exit 0 (got $code)"

# Drift locally: warn with a fix command, exit 0.
run_doctor "$TMP/drift"
[ "$code" -eq 0 ] || fail "drift locally should exit 0 (got $code)"
[[ "$out" == *"SwiftLint 0.1.0"*"$SWIFTLINT_VERSION"* ]] || fail "should report SwiftLint drift: $out"
[[ "$out" == *"SwiftFormat 0.2.0"*"$SWIFTFORMAT_VERSION"* ]] || fail "should report SwiftFormat drift: $out"
[[ "$out" == *"Xcode 1.0"*"$XCODE_VERSION"* ]] || fail "should report Xcode drift: $out"
[[ "$out" == *"Periphery 0.3.0"*"$PERIPHERY_VERSION"* ]] || fail "should report Periphery drift: $out"
[[ "$out" == *"fix:"* ]] || fail "should print a fix command: $out"

# Drift in CI: error, exit 1.
run_doctor "$TMP/drift" true
[ "$code" -eq 1 ] || fail "drift in CI should exit 1 (got $code)"
[[ "$out" == *error* ]] || fail "drift in CI should print error: $out"

# Missing tool: reported as missing.
rm "$TMP/ok/swiftlint"
run_doctor "$TMP/ok"
[ "$code" -eq 0 ] || fail "missing tool locally should exit 0 (got $code)"
[[ "$out" == *"SwiftLint"*"not installed"* ]] || fail "should report missing SwiftLint: $out"
run_doctor "$TMP/ok" true
[ "$code" -eq 1 ] || fail "missing tool in CI should exit 1 (got $code)"

# Missing periphery: the fix points at the local install into build/tools/bin (no Homebrew).
rm "$TMP/ok/periphery"
run_doctor "$TMP/ok"
[[ "$out" == *"Periphery not installed"*"scripts/ci/install-tools.sh build/tools/bin"* ]] ||
  fail "should report missing Periphery with the local install command: $out"

# Tools only in build/tools/bin (where install-tools.sh puts them and scripts/quality looks first)
# count as installed.
stub "$TMP/repo/build/tools/bin" "$SWIFTLINT_VERSION" "$SWIFTFORMAT_VERSION" "$XCODE_VERSION" "$PERIPHERY_VERSION"
out="$(PATH="/usr/bin:/bin" CI=true "$DOCTOR" 2>&1)"
code=$?
[ "$code" -eq 0 ] || fail "tools in build/tools/bin should count as installed (got $code): $out"

[ "$failures" -eq 0 ]
