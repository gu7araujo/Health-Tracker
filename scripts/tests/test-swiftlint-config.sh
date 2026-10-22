#!/usr/bin/env bash
# Tests .swiftlint.yml: other worktrees and build output are never linted, so a
# gate run from the main checkout only counts its own code.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cp "$ROOT/.swiftlint.yml" "$ROOT/.swiftlint-baseline.json" "$TMP/"
for dir in .claude/worktrees/other .worktrees/other build; do
  mkdir -p "$TMP/$dir"
  printf 'let value = thing as! String;\n' >"$TMP/$dir/Bad.swift"
done
mkdir -p "$TMP/HealthTracker"
printf 'let value = 1\n' >"$TMP/HealthTracker/Good.swift"

out="$(cd "$TMP" && swiftlint lint --strict --quiet 2>&1)"
if [ -n "$out" ]; then
  printf '  FAIL: excluded dirs were linted:\n%s\n' "$out"
  exit 1
fi
