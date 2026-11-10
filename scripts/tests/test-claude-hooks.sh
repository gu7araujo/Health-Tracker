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
# Inside a git hook or `rebase --exec`, these would point the hook's checkout lookup at this repo.
unset GIT_DIR GIT_INDEX_FILE GIT_WORK_TREE

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

# .claude/settings.json wires the hook to every tool that writes a file, the Xcode MCP's included.
SETTINGS="$ROOT/.claude/settings.json"
matcher="$(jq -r '.hooks.PostToolUse[0].matcher' "$SETTINGS")"
for tool in Edit Write MultiEdit mcp__xcode__XcodeWrite mcp__xcode__XcodeUpdate; do
  [[ "$tool" =~ ^($matcher)$ ]] || fail "the PostToolUse matcher should match $tool: $matcher"
done

# The wired command is a silent no-op in a checkout without the hook script (a worktree branched
# before it existed), and still reports a violation where the script exists.
hook_command="$(jq -r '.hooks.PostToolUse[0].hooks[0].command' "$SETTINGS")"
mkdir -p "$WORK/no-hook"
out="$(CLAUDE_PROJECT_DIR="$WORK/no-hook" bash -c "$hook_command" 2>&1 </dev/null)"
code=$?
[ "$code" -eq 0 ] || fail "a missing hook script should exit 0 (got $code): $out"
[ -z "$out" ] || fail "a missing hook script should print nothing: $out"
out="$(jq -n --arg path "$WORK/Caster.swift" '{tool_input: {file_path: $path}}' |
  CLAUDE_PROJECT_DIR="$ROOT" bash -c "$hook_command" 2>&1 >/dev/null)"
code=$?
[ "$code" -eq 2 ] || fail "the wired command should keep the hook's exit 2 (got $code): $out"

# Every MCP server the allowlist names is defined in .mcp.json, and xcodebuild needs an approval.
while IFS= read -r server; do
  jq -e --arg server "${server#mcp__}" '.mcpServers | has($server)' "$ROOT/.mcp.json" >/dev/null ||
    fail "allowlist entry $server names no server in .mcp.json"
done < <(jq -r '.permissions.allow[] | select(startswith("mcp__"))' "$SETTINGS")
jq -e '.permissions.allow | any(startswith("Bash(xcodebuild"))' "$SETTINGS" >/dev/null &&
  fail "xcodebuild should not be allowlisted"

# The hook must never pass silently when its tools can't run.
# bin/ holds jq plus the tool stubs; PATH keeps only system dirs besides it. Runs a copy of the hook
# in a temp repo, so this checkout's own build/tools/bin stays out of the lookup.
mkdir -p "$WORK/repo/.claude/hooks" "$WORK/repo/scripts/lib"
cp "$HOOK" "$WORK/repo/.claude/hooks/"
cp "$ROOT/scripts/lib/tools-path.sh" "$WORK/repo/scripts/lib/"
HOOK="$WORK/repo/.claude/hooks/format-swift.sh"
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

# The pinned tools in the repo's build/tools/bin run before a different swiftformat/swiftlint
# earlier on PATH.
mkdir -p "$WORK/repo/build/tools/bin" "$WORK/path-bin"
ln -s "$(command -v jq)" "$WORK/path-bin/jq"
for tool in swiftformat swiftlint; do
  printf '#!/bin/sh\ntouch "%s"\nexit 1\n' "$WORK/path-$tool-ran" >"$WORK/path-bin/$tool"
  printf '#!/bin/sh\ntouch "%s"\n' "$WORK/pinned-$tool-ran" >"$WORK/repo/build/tools/bin/$tool"
done
chmod +x "$WORK/path-bin"/* "$WORK/repo/build/tools/bin"/*
out="$(jq -n --arg path "$WORK/Tool.swift" '{tool_input: {file_path: $path}}' |
  PATH="$WORK/path-bin:/usr/bin:/bin" "$HOOK" 2>&1 >/dev/null)"
code=$?
[ "$code" -eq 0 ] || fail "pinned tools should pass the clean file (got $code): $out"
[ ! -e "$WORK/path-swiftformat-ran" ] || fail "swiftformat from PATH ran"
[ ! -e "$WORK/path-swiftlint-ran" ] || fail "swiftlint from PATH ran"
[ -e "$WORK/pinned-swiftformat-ran" ] || fail "build/tools/bin/swiftformat not run"
[ -e "$WORK/pinned-swiftlint-ran" ] || fail "build/tools/bin/swiftlint not run"

# The Xcode MCP write tools pass `filePath`, a project-structure path: the project's name, then
# the path inside the checkout. The checkout is the one the session works in (`cwd`), which in a
# worktree is not the hook's own.
for tool in swiftformat swiftlint; do
  printf '#!/bin/sh\nprintf "%%s\\n" "$*" >"%s"\n' "$WORK/pinned-$tool-ran" >"$WORK/repo/build/tools/bin/$tool"
done
mkdir -p "$WORK/repo/Sources" "$WORK/worktree/Sources/Deep"
git -C "$WORK/worktree" init -q
cp "$FIXTURES/Formatted.swift.fixture" "$WORK/repo/Sources/Rel.swift"
cp "$FIXTURES/Formatted.swift.fixture" "$WORK/worktree/Sources/Rel.swift"
worktree="$(cd "$WORK/worktree" && pwd -P)"

# run_xcode_hook <tool_input JSON> <cwd> -> sets out, code; the stubs record their arguments.
# GIT_CEILING_DIRECTORIES keeps a repo that holds the temp dir out of the checkout lookup.
run_xcode_hook() {
  rm -f "$WORK/pinned-swiftformat-ran" "$WORK/pinned-swiftlint-ran"
  out="$(jq -n --argjson input "$1" --arg cwd "$2" '{tool_name: "mcp__xcode__XcodeUpdate", cwd: $cwd, tool_input: $input}' |
    GIT_CEILING_DIRECTORIES="$WORK" PATH="$WORK/path-bin:/usr/bin:/bin" "$HOOK" 2>&1 >/dev/null)"
  code=$?
}

run_xcode_hook '{"filePath": "Proj/Sources/Rel.swift"}' "$WORK/worktree/Sources/Deep"
[ "$code" -eq 0 ] || fail "an Xcode MCP write should exit 0 (got $code): $out"
for tool in swiftformat swiftlint; do
  grep -qF -- "$worktree/Sources/Rel.swift" "$WORK/pinned-$tool-ran" 2>/dev/null ||
    fail "$tool should run on the session checkout's file: $(cat "$WORK/pinned-$tool-ran" 2>/dev/null)"
done

# An opaque `workspaceIdentifier` says nothing about the checkout, so `cwd` still decides.
run_xcode_hook '{"filePath": "Proj/Sources/Rel.swift", "workspaceIdentifier": "workspace-abc"}' "$WORK/worktree"
grep -qF -- "$worktree/Sources/Rel.swift" "$WORK/pinned-swiftformat-ran" 2>/dev/null ||
  fail "an opaque workspaceIdentifier should fall back to cwd: $(cat "$WORK/pinned-swiftformat-ran" 2>/dev/null)"

# A cwd outside any checkout leaves nothing to resolve against.
mkdir -p "$WORK/no-repo"
run_xcode_hook '{"filePath": "Proj/Sources/Rel.swift"}' "$WORK/no-repo"
[ "$code" -eq 0 ] || fail "a cwd outside a checkout should exit 0 (got $code): $out"
[ ! -e "$WORK/pinned-swiftformat-ran" ] || fail "a cwd outside a checkout should format nothing"

# An absolute `workspaceIdentifier` names the checkout itself, whatever the session's cwd.
run_xcode_hook "$(jq -n --arg ws "$worktree/Proj.xcodeproj" '{filePath: "Proj/Sources/Rel.swift", workspaceIdentifier: $ws}')" "$WORK/repo"
grep -qF -- "$worktree/Sources/Rel.swift" "$WORK/pinned-swiftformat-ran" 2>/dev/null ||
  fail "an absolute workspaceIdentifier should pick the checkout: $(cat "$WORK/pinned-swiftformat-ran" 2>/dev/null)"

# A path that names no file in that checkout is skipped, even if the hook's own checkout has one.
rm "$WORK/worktree/Sources/Rel.swift"
run_xcode_hook '{"filePath": "Proj/Sources/Rel.swift"}' "$WORK/worktree"
[ "$code" -eq 0 ] || fail "an unresolvable Xcode path should exit 0 (got $code): $out"
[ ! -e "$WORK/pinned-swiftformat-ran" ] || fail "an unresolvable Xcode path formatted another checkout's file"

# Without scripts/lib/tools-path.sh the pinned tools can't be looked up: exit 2, even though
# passing tools are on PATH.
rm "$WORK/repo/scripts/lib/tools-path.sh"
for tool in swiftformat swiftlint; do
  printf '#!/bin/sh\n' >"$WORK/path-bin/$tool"
done
out="$(jq -n --arg path "$WORK/Tool.swift" '{tool_input: {file_path: $path}}' |
  PATH="$WORK/path-bin:/usr/bin:/bin" "$HOOK" 2>&1 >/dev/null)"
code=$?
[ "$code" -eq 2 ] || fail "a missing tools-path helper should exit 2 (got $code): $out"
[[ "$out" == *tools-path.sh* ]] || fail "the missing helper should be reported: $out"

[ "$failures" -eq 0 ]
