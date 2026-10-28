#!/usr/bin/env bash
# Tests scripts/tests/run: it runs the test files with the repo's build/tools/bin (where
# scripts/bootstrap installs the pinned tools) first on PATH, and with plain PATH without it.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
failures=0

fail() {
  printf '  FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

# Runs a copy of scripts/tests/run beside a single test file that records which swiftlint it sees,
# so this checkout's own test files and build/tools/bin stay out of it.
mkdir -p "$TMP/repo/scripts/tests" "$TMP/path-bin"
cp "$ROOT/scripts/tests/run" "$TMP/repo/scripts/tests/run"
printf '#!/usr/bin/env bash\ncommand -v swiftlint >"%s"\n' "$TMP/seen" >"$TMP/repo/scripts/tests/test-probe.sh"
printf '#!/bin/sh\n' >"$TMP/path-bin/swiftlint"
chmod +x "$TMP/repo/scripts/tests/test-probe.sh" "$TMP/path-bin/swiftlint"

# No build/tools/bin: the tests see the swiftlint on PATH.
PATH="$TMP/path-bin:$PATH" "$TMP/repo/scripts/tests/run" >/dev/null 2>&1 || fail "run should pass without build/tools/bin"
[ "$(cat "$TMP/seen" 2>/dev/null)" = "$TMP/path-bin/swiftlint" ] ||
  fail "without build/tools/bin the tests should see PATH's swiftlint, saw: $(cat "$TMP/seen" 2>/dev/null)"

# build/tools/bin: its swiftlint runs before the one on PATH.
mkdir -p "$TMP/repo/build/tools/bin"
cp "$TMP/path-bin/swiftlint" "$TMP/repo/build/tools/bin/swiftlint"
PATH="$TMP/path-bin:$PATH" "$TMP/repo/scripts/tests/run" >/dev/null 2>&1 || fail "run should pass with build/tools/bin"
[ "$(cat "$TMP/seen" 2>/dev/null)" = "$TMP/repo/build/tools/bin/swiftlint" ] ||
  fail "the tests should see build/tools/bin/swiftlint first, saw: $(cat "$TMP/seen" 2>/dev/null)"

[ "$failures" -eq 0 ]
