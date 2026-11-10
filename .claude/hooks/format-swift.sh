#!/usr/bin/env bash
# Claude Code PostToolUse hook: formats the edited Swift file with SwiftFormat,
# then lints it. Violations, and any tool that fails to run, go to stderr with
# exit 2 so the agent sees them.
#
# Edit/Write name the file by absolute path (`file_path`). The Xcode MCP write
# tools pass `filePath`, a project-structure path (`<project name>/<path inside
# the checkout>`), so the checkout comes from an absolute `workspaceIdentifier`,
# or else from the session's `cwd`. A path that resolves to no file is skipped.
# An opaque identifier (`workspace-…`) can't be mapped to a checkout from here:
# when it names another checkout than `cwd`'s, the hook checks `cwd`'s file of
# the same path instead of the one written.
set -uo pipefail

input="$(cat)"
field() { jq -r "$1 // empty" <<<"$input"; }

file="$(field .tool_input.file_path)"
if [ -z "$file" ]; then
  xcode_path="$(field .tool_input.filePath)"
  workspace="$(field .tool_input.workspaceIdentifier)"
  if [[ "$workspace" == /* ]]; then
    checkout="$(dirname "$workspace")"
  else
    checkout="$(git -C "$(field .cwd)" rev-parse --show-toplevel 2>/dev/null)"
  fi
  [[ -n "$xcode_path" && -n "$checkout" ]] || exit 0
  file="$checkout/${xcode_path#*/}"
fi
[[ "$file" == *.swift && -f "$file" ]] || exit 0

# Run from the repo root so SwiftLint picks up .swiftlint.yml.
cd "$(dirname "$0")/../.." || exit 1
# scripts/lib/tools-path.sh: the pinned tools in build/tools/bin run before those on PATH.
# shellcheck source=../../scripts/lib/tools-path.sh
source scripts/lib/tools-path.sh || exit 2
prepend_tools_path "$PWD"

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
