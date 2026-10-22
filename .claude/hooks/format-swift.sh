#!/usr/bin/env bash
# Claude Code PostToolUse hook: formats the edited Swift file with SwiftFormat,
# then lints it. Violations, and any tool that fails to run, go to stderr with
# exit 2 so the agent sees them.
set -uo pipefail

file="$(jq -r '.tool_input.file_path // empty')"
[[ "$file" == *.swift && -f "$file" ]] || exit 0

# Run from the repo root so SwiftLint picks up .swiftlint.yml.
cd "$(dirname "$0")/../.." || exit 1

for tool in swiftformat swiftlint; do
  if ! command -v "$tool" >/dev/null; then
    echo "format-swift hook: $tool is not installed, so $file was not checked (run scripts/doctor)." >&2
    exit 2
  fi
done

if ! format_err="$(swiftformat --swift-version 6 --quiet -- "$file" 2>&1 >/dev/null)"; then
  echo "format-swift hook: swiftformat failed on $file:" >&2
  echo "$format_err" >&2
  exit 2
fi

lint_err="$(mktemp)"
trap 'rm -f "$lint_err"' EXIT
violations="$(swiftlint lint --quiet -- "$file" 2>"$lint_err")"
status=$?
if [ -n "$violations" ]; then
  echo "$violations" >&2
  exit 2
fi
if [ "$status" -ne 0 ]; then
  echo "format-swift hook: swiftlint failed (exit $status) on $file:" >&2
  cat "$lint_err" >&2
  exit 2
fi
