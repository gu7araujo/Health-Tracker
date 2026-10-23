#!/usr/bin/env bash
# Tests .swiftformat: build output (the gate's build/DerivedData holds Xcode-generated Swift)
# is never formatted or linted.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cp "$ROOT/.swiftformat" "$TMP/"
mkdir -p "$TMP/build/DerivedData/Generated" "$TMP/HealthTracker"
printf 'let   value=1\n' >"$TMP/build/DerivedData/Generated/GeneratedAssetSymbols.swift"
printf 'let value = 1\n' >"$TMP/HealthTracker/Good.swift"

out="$(cd "$TMP" && swiftformat . --lint --swift-version 6 2>&1)"
if [[ "$out" != *"0/1 files require formatting"* ]]; then
  printf '  FAIL: build/ was linted:\n%s\n' "$out"
  exit 1
fi
