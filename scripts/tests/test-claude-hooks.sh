#!/usr/bin/env bash
# Tests .claude/hooks/format-swift.sh (the Claude Code PostToolUse hook) by
# feeding it hook JSON for files in a temp dir. Set TEST_TMPDIR to choose where.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$ROOT/.claude/hooks/format-swift.sh"
FIXTURES="$ROOT/scripts/tests/fixtures/hooks"
WORK="$(mktemp -d "${TEST_TMPDIR:-${TMPDIR:-/tmp}}/test-claude-hooks.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
failures=0

fail() {
  printf '  FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

# run_hook <file path> -> sets out (stderr), code
run_hook() {
  out="$(jq -n --arg path "$1" '{hook_event_name: "PostToolUse", tool_name: "Edit", tool_input: {file_path: $path}}' |
    "$HOOK" 2>&1 >/dev/null)"
  code=$?
}

# A formatted, violation-free file: silent success.
cp "$FIXTURES/Formatted.swift.fixture" "$WORK/Clean.swift"
run_hook "$WORK/Clean.swift"
[ "$code" -eq 0 ] || fail "clean file should exit 0 (got $code): $out"
[ -z "$out" ] || fail "clean file should print nothing: $out"

# An unformatted file is rewritten in place.
cp "$FIXTURES/Unformatted.swift.fixture" "$WORK/Greeter.swift"
run_hook "$WORK/Greeter.swift"
[ "$code" -eq 0 ] || fail "unformatted file should exit 0 (got $code): $out"
diff -q "$WORK/Greeter.swift" "$FIXTURES/Formatted.swift.fixture" >/dev/null || fail "unformatted file was not formatted"

# A lint violation is reported on stderr with exit 2, so the agent sees it.
cp "$FIXTURES/LintViolation.swift.fixture" "$WORK/Caster.swift"
run_hook "$WORK/Caster.swift"
[ "$code" -eq 2 ] || fail "violating file should exit 2 (got $code)"
[[ "$out" == *force_cast* ]] || fail "violation should be printed to stderr: $out"

# A non-Swift file is left alone.
cp "$FIXTURES/Unformatted.swift.fixture" "$WORK/notes.txt"
run_hook "$WORK/notes.txt"
[ "$code" -eq 0 ] || fail "non-swift file should exit 0 (got $code)"
diff -q "$WORK/notes.txt" "$FIXTURES/Unformatted.swift.fixture" >/dev/null || fail "non-swift file was modified"

# A Swift path that no longer exists (e.g. deleted) is skipped.
run_hook "$WORK/Missing.swift"
[ "$code" -eq 0 ] || fail "missing file should exit 0 (got $code): $out"

# The hook must never pass silently when its tools can't run.
# bin/ holds jq plus the tool stubs; PATH keeps only system dirs besides it.
mkdir -p "$WORK/bin"
ln -s "$(command -v jq)" "$WORK/bin/jq"
ln -s "$(command -v swiftformat)" "$WORK/bin/swiftformat"
cp "$FIXTURES/Formatted.swift.fixture" "$WORK/Tool.swift"

# SwiftLint missing.
out="$(jq -n --arg path "$WORK/Tool.swift" '{tool_input: {file_path: $path}}' | PATH="$WORK/bin:/usr/bin:/bin" "$HOOK" 2>&1 >/dev/null)"
code=$?
[ "$code" -eq 2 ] || fail "missing swiftlint should exit 2 (got $code): $out"
[[ "$out" == *swiftlint* ]] || fail "missing swiftlint should be reported: $out"

# SwiftLint crashing with no violations on stdout.
printf '#!/bin/sh\necho "fatal: could not load config" >&2\nexit 1\n' >"$WORK/bin/swiftlint"
chmod +x "$WORK/bin/swiftlint"
out="$(jq -n --arg path "$WORK/Tool.swift" '{tool_input: {file_path: $path}}' | PATH="$WORK/bin:/usr/bin:/bin" "$HOOK" 2>&1 >/dev/null)"
code=$?
[ "$code" -eq 2 ] || fail "crashing swiftlint should exit 2 (got $code): $out"
[[ "$out" == *"could not load config"* ]] || fail "swiftlint's error should be shown: $out"

# SwiftFormat failing.
rm "$WORK/bin/swiftformat"
printf '#!/bin/sh\necho "error: unsupported option" >&2\nexit 70\n' >"$WORK/bin/swiftformat"
chmod +x "$WORK/bin/swiftformat"
out="$(jq -n --arg path "$WORK/Tool.swift" '{tool_input: {file_path: $path}}' | PATH="$WORK/bin:/usr/bin:/bin" "$HOOK" 2>&1 >/dev/null)"
code=$?
[ "$code" -eq 2 ] || fail "failing swiftformat should exit 2 (got $code): $out"
[[ "$out" == *"unsupported option"* ]] || fail "swiftformat's error should be shown: $out"

[ "$failures" -eq 0 ]
