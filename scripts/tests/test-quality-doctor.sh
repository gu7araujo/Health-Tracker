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

# A bootstrapped checkout: buildServer.json points at a DerivedData dir holding a build's log.
mkdir -p "$TMP/DerivedData/HealthTracker-abc/Logs/Build" "$TMP/DerivedData/HealthTracker-unbuilt/Logs/Build"
touch "$TMP/DerivedData/HealthTracker-abc/Logs/Build/1.xcactivitylog"
# write_build_server <build_root>: buildServer.json as `xcode-build-server config` lays it out.
write_build_server() {
  printf '{\n\t"name": "xcode build server",\n\t"build_root": "%s",\n\t"kind": "xcode"\n}' "$1" >"$TMP/repo/buildServer.json"
}
write_build_server "$TMP/DerivedData/HealthTracker-abc"

# stub <dir> <swiftlint version> <swiftformat version> <xcode version> <periphery version>
stub() {
  mkdir -p "$1"
  printf '#!/bin/sh\necho %s\n' "$2" >"$1/swiftlint"
  printf '#!/bin/sh\necho %s\n' "$3" >"$1/swiftformat"
  printf '#!/bin/sh\n[ "$1" = version ] && echo %s\n' "$5" >"$1/periphery"
  printf '#!/bin/sh\necho "Xcode %s"\necho "Build version X"\n' "$4" >"$1/xcodebuild"
  printf '#!/bin/sh\n' >"$1/xcbeautify"
  printf '#!/bin/sh\n' >"$1/jq"
  printf '#!/bin/sh\n' >"$1/xcode-build-server"
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
# The Xcode fix names no app path: installs are named Xcode.app, runners use _Release_Candidate etc.
[[ "$out" == *"install Xcode $XCODE_VERSION, then sudo xcode-select -s <path to that Xcode.app>"*"scripts/ci/select-xcode.sh"* ]] ||
  fail "should hint to install the pinned Xcode and select it: $out"
[[ "$out" != *"/Applications/Xcode_"* ]] || fail "should not guess an /Applications/Xcode_<version>.app path: $out"

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

# swift-lsp setup (local only): xcode-build-server, buildServer.json and a build behind it.
LSP="$TMP/lsp"
# The case above left a full tool set in the repo copy's build/tools/bin.
mv "$TMP/repo/build" "$TMP/build.aside"
stub "$LSP" "$SWIFTLINT_VERSION" "$SWIFTFORMAT_VERSION" "$XCODE_VERSION" "$PERIPHERY_VERSION"
run_doctor "$LSP"
[[ "$out" != *warning* ]] || fail "a bootstrapped, built checkout should not warn: $out"

mv "$TMP/repo/buildServer.json" "$TMP/buildServer.json.aside"
run_doctor "$LSP"
[ "$code" -eq 0 ] || fail "missing buildServer.json should exit 0 (got $code)"
[[ "$out" == *"warning: buildServer.json missing"*"fix: scripts/bootstrap"* ]] ||
  fail "should warn that buildServer.json is missing, with the fix: $out"
run_doctor "$LSP" true
[ "$code" -eq 0 ] || fail "missing buildServer.json should not fail CI, which runs no LSP (got $code): $out"
[[ "$out" != *buildServer.json* ]] || fail "CI should skip the swift-lsp checks: $out"

write_build_server "$TMP/DerivedData/HealthTracker-gone"
run_doctor "$LSP"
[ "$code" -eq 0 ] || fail "a missing DerivedData dir should exit 0 (got $code)"
[[ "$out" == *"warning: buildServer.json points at $TMP/DerivedData/HealthTracker-gone, which does not exist"*"fix:"*"build"* ]] ||
  fail "should warn that the DerivedData path is missing and that a build is needed: $out"
# `xcode-build-server config` creates the DerivedData dir itself, so only a build log shows a build.
write_build_server "$TMP/DerivedData/HealthTracker-unbuilt"
run_doctor "$LSP"
[ "$code" -eq 0 ] || fail "an unbuilt DerivedData dir should exit 0 (got $code)"
[[ "$out" == *"warning: buildServer.json points at $TMP/DerivedData/HealthTracker-unbuilt, which holds no build yet"*"fix:"*"build"* ]] ||
  fail "should warn that no build is behind buildServer.json: $out"
write_build_server "$TMP/DerivedData/HealthTracker-abc"

mv "$LSP/xcode-build-server" "$TMP/xcode-build-server.aside"
run_doctor "$LSP"
[[ "$out" == *"warning: xcode-build-server not installed"*"fix: scripts/bootstrap"* ]] ||
  fail "should warn that xcode-build-server is missing: $out"
run_doctor "$LSP" true
[ "$code" -eq 0 ] || fail "missing xcode-build-server should not fail CI (got $code): $out"

[ "$failures" -eq 0 ]
