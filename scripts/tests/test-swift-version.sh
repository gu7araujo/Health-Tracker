#!/usr/bin/env bash
# Tests HealthTracker.xcodeproj: every target builds in Swift 6 language mode,
# so no target (app or tests) can drift back to Swift 5.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PBXPROJ="${1:-$ROOT/HealthTracker.xcodeproj/project.pbxproj}"

versions="$(grep -E '^[[:space:]]*SWIFT_VERSION = ' "$PBXPROJ")"
if [ -z "$versions" ]; then
  printf '  FAIL: no SWIFT_VERSION found in %s\n' "$PBXPROJ"
  exit 1
fi

# Every target build configuration (the ones with a bundle identifier) must set it: a missing line
# falls back to Xcode's default language mode.
targets="$(grep -cE '^[[:space:]]*PRODUCT_BUNDLE_IDENTIFIER = ' "$PBXPROJ")"
set_count="$(grep -cE '^[[:space:]]*SWIFT_VERSION = ' "$PBXPROJ")"
if [ "$set_count" -ne "$targets" ]; then
  printf '  FAIL: %s target build configurations but %s SWIFT_VERSION settings\n' "$targets" "$set_count"
  exit 1
fi

stale="$(grep -nE '^[[:space:]]*SWIFT_VERSION = ' "$PBXPROJ" | grep -vE 'SWIFT_VERSION = 6\.0;$')"
if [ -n "$stale" ]; then
  printf '  FAIL: SWIFT_VERSION must be 6.0:\n%s\n' "$stale"
  exit 1
fi
