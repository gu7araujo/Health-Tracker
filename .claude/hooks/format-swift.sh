#!/usr/bin/env bash
# Claude Code PostToolUse hook: formats the edited Swift file with SwiftFormat,
# then lints it. Violations go to stderr with exit 2 so the agent sees them.
set -uo pipefail

file="$(jq -r '.tool_input.file_path // empty')"
[[ "$file" == *.swift && -f "$file" ]] || exit 0

# Run from the repo root so SwiftLint picks up .swiftlint.yml.
cd "$(dirname "$0")/../.." || exit 1

swiftformat --swift-version 6 --quiet -- "$file"
violations="$(swiftlint lint --quiet -- "$file" 2>/dev/null)"
if [ -n "$violations" ]; then
  echo "$violations" >&2
  exit 2
fi
