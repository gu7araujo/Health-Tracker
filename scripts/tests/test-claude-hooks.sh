#!/usr/bin/env bash
# Tests the Claude Code hooks in .claude/hooks (format-swift.sh, then the routing hooks:
# layer-docs.sh, skill-loaded.sh, skill-required.sh, concurrency-skill.sh, xcodebuild-runner.sh,
# bootstrap-check.sh, swift-bash-edits.sh, gate-reminder.sh) and their wiring in .claude/settings.json, by feeding each
# hook JSON for files in a temp dir. Set TEST_TMPDIR to choose where.
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

# --- Routing hooks: they point the agent at the layer doc, skill or runner the task needs. ---
HOOKS="$ROOT/.claude/hooks"
export TMPDIR="$WORK/hook-tmp"
mkdir -p "$TMPDIR"

# context <hook> <input JSON> -> sets out (the additionalContext, or stdout when not JSON), code
context() {
  local raw
  raw="$("$HOOKS/$1" <<<"$2" 2>&1)"
  code=$?
  out="$(jq -r '.hookSpecificOutput.additionalContext // empty' <<<"$raw" 2>/dev/null || printf '%s' "$raw")"
}

# hook_wired <event> <hook script> <tool name>: settings.json runs the script on that event for that tool.
hook_wired() {
  jq -e --arg event "$1" --arg script "$2" --arg tool "$3" \
    '.hooks[$event] // [] | any((.matcher // ".*") as $m | (.hooks | any(.command | contains($script))) and ($tool | test("^(" + $m + ")$")))' \
    "$SETTINGS" >/dev/null || fail "settings.json should run $2 on $1 for $3"
}

# layer-docs.sh: the first edit in a layer, per session and agent, names its AGENTS.md and skill.
edit_input() {
  jq -n --arg path "$1" --arg session "$2" --arg agent "${3:-}" \
    '{hook_event_name: "PreToolUse", tool_name: "Edit", session_id: $session, tool_input: {file_path: $path}} + (if $agent == "" then {} else {agent_id: $agent} end)'
}
context layer-docs.sh "$(edit_input "$ROOT/HealthTracker/Presentation/Sections/MealsSectionView.swift" s1)"
[ "$code" -eq 0 ] || fail "layer-docs should exit 0 (got $code): $out"
[[ "$out" == *"HealthTracker/Presentation/AGENTS.md"* && "$out" == *swiftui-specialist* ]] ||
  fail "a Presentation edit should name its AGENTS.md and swiftui-specialist: $out"
context layer-docs.sh "$(edit_input "$ROOT/HealthTracker/Presentation/MainView.swift" s1)"
[ -z "$out" ] || fail "a second Presentation edit in the session should be silent: $out"
context layer-docs.sh "$(edit_input "$ROOT/HealthTracker/Presentation/MainView.swift" s1 agent-a)"
[[ "$out" == *swiftui-specialist* ]] || fail "a subagent's first Presentation edit should be reminded: $out"
context layer-docs.sh "$(edit_input "$ROOT/HealthTracker/Presentation/MainView.swift" s2)"
[[ "$out" == *swiftui-specialist* ]] || fail "a new session's first Presentation edit should be reminded: $out"
context layer-docs.sh "$(edit_input "$ROOT/HealthTracker/Presentation/Intents/LogWaterIntent.swift" s1)"
[[ "$out" == *"Presentation/Intents/AGENTS.md"* && "$out" == *app-intents-specialist* ]] ||
  fail "an Intents edit should name its AGENTS.md and app-intents-specialist: $out"
[[ "$out" == *"iOS 26/27"* ]] || fail "the Intents reminder should scope app-intents-whats-new-27 to iOS 26/27: $out"
context layer-docs.sh "$(edit_input "$ROOT/HealthTrackerTests/Domain/DayDataTests.swift" s1)"
[[ "$out" == *"HealthTrackerTests/AGENTS.md"* && "$out" == *swift-testing-expert* ]] ||
  fail "a unit-test edit should name its AGENTS.md and swift-testing-expert: $out"
for layer in HealthTracker/Domain HealthTracker/Data HealthTrackerUITests HealthTrackerIntentsUITests scripts; do
  context layer-docs.sh "$(edit_input "$ROOT/$layer/New/Some.swift" s1)"
  [[ "$out" == *"$layer/AGENTS.md"* ]] || fail "an edit in $layer should name $layer/AGENTS.md: $out"
done
context layer-docs.sh "$(edit_input "$ROOT/README.md" s1)"
[ -z "$out" ] || fail "an edit outside the layers should be silent: $out"
# A path outside any checkout that merely contains a layer's name is not that layer, and leaves its
# marker unset.
mkdir -p "$WORK/outside/scripts"
context layer-docs.sh "$(edit_input "$WORK/outside/scripts/x.sh" s4)"
[ -z "$out" ] || fail "an edit outside the checkout should be silent: $out"
mkdir -p "$WORK/other-repo/scripts"
git -C "$WORK/other-repo" init -q
context layer-docs.sh "$(edit_input "$WORK/other-repo/scripts/build.sh" s4)"
[ -z "$out" ] || fail "an edit in another repository should be silent: $out"
context layer-docs.sh "$(edit_input "$ROOT/scripts/quality" s4)"
[[ "$out" == *scripts/AGENTS.md* ]] || fail "an outside edit should not use up the scripts reminder: $out"
context layer-docs.sh "$(jq -n '{hook_event_name: "PreToolUse", tool_name: "mcp__xcode__XcodeUpdate", session_id: "s3",
  tool_input: {filePath: "HealthTracker/HealthTracker/Domain/Entities/DayData.swift"}}')"
[[ "$out" == *"HealthTracker/Domain/AGENTS.md"* ]] || fail "an Xcode MCP write should be mapped to its layer: $out"
for tool in Edit Write MultiEdit mcp__xcode__XcodeWrite mcp__xcode__XcodeUpdate; do
  hook_wired PreToolUse layer-docs.sh "$tool"
done

# skill-loaded.sh and skill-required.sh: an edit to a View or a unit-test file is refused until its
# skill has been loaded in that session and agent.
# deny <hook> <input JSON> -> sets out (the permission decision and reason, or the raw output), code
deny() {
  local raw
  raw="$("$HOOKS/$1" <<<"$2" 2>&1)"
  code=$?
  out="$(jq -r '.hookSpecificOutput | "\(.permissionDecision) \(.permissionDecisionReason)"' <<<"$raw" 2>/dev/null || printf '%s' "$raw")"
}
skill_input() { # skill_input <skill> <session> [agent]
  jq -n --arg skill "$1" --arg session "$2" --arg agent "${3:-}" \
    '{hook_event_name: "PostToolUse", tool_name: "Skill", session_id: $session, tool_input: {skill: $skill}} + (if $agent == "" then {} else {agent_id: $agent} end)'
}
# load <skill> <session> [agent]: runs skill-loaded.sh, which must exit 0 silently.
load() {
  local raw
  raw="$("$HOOKS/skill-loaded.sh" <<<"$(skill_input "$@")" 2>&1)"
  code=$?
  [ "$code" -eq 0 ] || fail "skill-loaded should exit 0 (got $code): $raw"
  [ -z "$raw" ] || fail "skill-loaded should print nothing: $raw"
}
mkdir -p "$WORK/claude-config/plugins"
echo '{"version": 2, "plugins": {"swift-testing-expert@swift-testing-agent-skill": []}}' >"$WORK/claude-config/plugins/installed_plugins.json"
export CLAUDE_CONFIG_DIR="$WORK/claude-config"
VIEW="$ROOT/HealthTracker/Presentation/Views/MainView.swift"
deny skill-required.sh "$(edit_input "$VIEW" k1)"
[ "$code" -eq 0 ] || fail "skill-required should exit 0 (got $code): $out"
[[ "$out" == deny* && "$out" == *'Skill("swiftui-specialist")'* && "$out" == *"Presentation/AGENTS.md"* ]] ||
  fail "a View edit without swiftui-specialist should be denied, naming the skill and doc: $out"
load swiftui-specialist k1
deny skill-required.sh "$(edit_input "$VIEW" k1)"
[ -z "$out" ] || fail "a View edit after loading swiftui-specialist should pass: $out"
load swiftui-specialist k2 agent-a
deny skill-required.sh "$(edit_input "$VIEW" k2 agent-a)"
[ -z "$out" ] || fail "a subagent's own load should let its View edit pass: $out"
deny skill-required.sh "$(edit_input "$VIEW" k2)"
[[ "$out" == deny* ]] || fail "a subagent's load should not cover the main session: $out"
deny skill-required.sh "$(edit_input "$VIEW" k2 agent-b)"
[[ "$out" == deny* ]] || fail "a subagent's load should not cover another subagent: $out"
load swiftui-specialist k3
deny skill-required.sh "$(edit_input "$VIEW" k3 agent-a)"
[[ "$out" == deny* ]] || fail "a main-session load should not cover a subagent: $out"
TEST_FILE="$ROOT/HealthTrackerTests/Domain/DayDataTests.swift"
deny skill-required.sh "$(edit_input "$TEST_FILE" k4)"
[[ "$out" == deny* && "$out" == *'Skill("swift-testing-expert:swift-testing-expert")'* && "$out" == *"HealthTrackerTests/AGENTS.md"* ]] ||
  fail "a unit-test edit without swift-testing-expert should be denied, naming the skill and doc: $out"
load swiftui-specialist k4
deny skill-required.sh "$(edit_input "$TEST_FILE" k4)"
[[ "$out" == deny* ]] || fail "swiftui-specialist should not unlock a unit-test file: $out"
load swift-testing-expert:swift-testing-expert k4
deny skill-required.sh "$(edit_input "$TEST_FILE" k4)"
[ -z "$out" ] || fail "a unit-test edit after loading swift-testing-expert should pass: $out"
load swift-testing-expert:swift-testing-expert k8
deny skill-required.sh "$(edit_input "$VIEW" k8)"
[[ "$out" == deny* ]] || fail "swift-testing-expert should not unlock a View: $out"
for rel in HealthTracker/Presentation/ViewModels/MainViewModel.swift HealthTracker/Presentation/Intents/LogWaterIntent.swift \
  HealthTracker/Presentation/AccessibilityID.swift HealthTracker/Resources/en.lproj/Localizable.strings \
  HealthTrackerTests/AGENTS.md HealthTrackerUITests/Some.swift HealthTracker/Domain/Entities/Meal.swift README.md; do
  deny skill-required.sh "$(edit_input "$ROOT/$rel" k5)"
  [ "$code" -eq 0 ] && [ -z "$out" ] || fail "an edit to $rel should not need a skill (code $code): $out"
done
deny skill-required.sh "$(edit_input "$WORK/outside/HealthTracker/Presentation/Views/X.swift" k5)"
[ -z "$out" ] || fail "a View path outside the checkout should not need a skill: $out"
xcode_write() {
  jq -n --arg session "$1" '{hook_event_name: "PreToolUse", tool_name: "mcp__xcode__XcodeWrite", session_id: $session,
    tool_input: {filePath: "HealthTracker/HealthTracker/Presentation/Views/Components/CardView.swift"}}'
}
deny skill-required.sh "$(xcode_write k6)"
[[ "$out" == deny* ]] || fail "an Xcode MCP write to a View should be denied without the skill: $out"
load swiftui-specialist k6
deny skill-required.sh "$(xcode_write k6)"
[ -z "$out" ] || fail "an Xcode MCP write to a View should pass after the load: $out"
deny skill-required.sh "$(edit_input "$ROOT/HealthTracker/Presentation/Views/New/BrandNewView.swift" k7)"
[[ "$out" == deny* ]] || fail "a new View file should be denied without the skill: $out"
# A plugin skill whose plugin is not installed (a cloud session) cannot be loaded, so its files pass.
CLAUDE_CONFIG_DIR="$WORK/bare-config" deny skill-required.sh "$(edit_input "$TEST_FILE" k9)"
[ "$code" -eq 0 ] && [ -z "$out" ] || fail "a unit-test edit should pass when its plugin is not installed (code $code): $out"
CLAUDE_CONFIG_DIR="$WORK/bare-config" deny skill-required.sh "$(edit_input "$VIEW" k9)"
[[ "$out" == deny* ]] || fail "a project skill should still gate its View without plugins: $out"
hook_wired PostToolUse skill-loaded.sh Skill
for tool in Edit Write MultiEdit mcp__xcode__XcodeWrite mcp__xcode__XcodeUpdate; do
  hook_wired PreToolUse skill-required.sh "$tool"
done

# concurrency-skill.sh: a concurrency diagnostic in a build's output, or its failure, names the skill once.
build_output() {
  jq -n --arg stdout "$1" --arg session "$2" --arg command "${3:-xcodebuild build}" '{hook_event_name: "PostToolUse",
    tool_name: "Bash", session_id: $session, tool_input: {command: $command}, tool_response: {stdout: $stdout, stderr: ""}}'
}
for diagnostic in \
  "MainView.swift:12:5: error: main actor-isolated property 'days' can not be referenced from a nonisolated context" \
  "error: type 'Meal' does not conform to the 'Sendable' protocol" \
  "error: capture of 'self' with non-Sendable type 'Store' in a '@Sendable' closure" \
  "error: sending 'value' risks causing data races" \
  "error: static property 'shared' is not concurrency-safe because it is nonisolated global shared mutable state" \
  "error: mutation of captured var 'count' in concurrently-executing code" \
  "error: call to global actor 'MainActor'-isolated instance method 'load()' in a synchronous nonisolated context"; do
  context concurrency-skill.sh "$(build_output "$diagnostic" "c-$RANDOM$RANDOM")"
  [[ "$out" == *"swift-concurrency:swift-concurrency"* ]] || fail "should name swift-concurrency for: $diagnostic ($out)"
done
context concurrency-skill.sh "$(build_output "error: actor-isolated call" c1)"
context concurrency-skill.sh "$(build_output "error: actor-isolated call" c1)"
[ -z "$out" ] || fail "a repeated concurrency diagnostic in a session should be silent: $out"
context concurrency-skill.sh "$(build_output "** BUILD SUCCEEDED ** (Sendable.swift compiled)" c2)"
[ -z "$out" ] || fail "output without a concurrency diagnostic should be silent: $out"
# Reading code or a diff that mentions a diagnostic is not a build: silent, and the reminder stays available.
context concurrency-skill.sh "$(build_output "+  \"error: main actor-isolated property\"" c5 "git diff main")"
[ -z "$out" ] || fail "a non-build command's output should be silent: $out"
for command in "git log --grep xcodebuild" "sed -n 1,80p scripts/quality" "git diff main -- scripts/quality"; do
  context concurrency-skill.sh "$(build_output "error: main actor-isolated property" c5 "$command")"
  [ -z "$out" ] || fail "a command that only names a build tool should be silent: $command ($out)"
done
for command in "git push -u origin feat/x" "gh run view 123 --log-failed" "swift build"; do
  context concurrency-skill.sh "$(build_output "error: main actor-isolated property" "c-$RANDOM$RANDOM" "$command")"
  [[ "$out" == *swift-concurrency* ]] || fail "a command that builds or prints a build log should count: $command ($out)"
done
context concurrency-skill.sh "$(build_output "error: main actor-isolated property" c8 $'git commit -m "$(cat <<\'EOF\'\nfix: x\nEOF\n)" && git push')"
[[ "$out" == *swift-concurrency* ]] || fail "a git push after a heredoc commit message should count: $out"
context concurrency-skill.sh "$(build_output "error: main actor-isolated property" c5 "scripts/quality --fast")"
[[ "$out" == *swift-concurrency* ]] || fail "a gate run's diagnostic should still be reminded after a non-build match: $out"
# A failing build fires PostToolUseFailure, with its output in .error.
context concurrency-skill.sh "$(jq -n '{hook_event_name: "PostToolUseFailure", tool_name: "Bash", session_id: "c6",
  tool_input: {command: "xcodebuild build"}, error: "Exit code 65\nerror: non-Sendable type Store"}')"
[[ "$out" == *swift-concurrency* ]] || fail "a failed build's diagnostic should name swift-concurrency: $out"
[ "$(jq -r '.hookSpecificOutput.hookEventName' <<<"$("$HOOKS/concurrency-skill.sh" <<<"$(jq -n '{hook_event_name: "PostToolUseFailure",
  tool_name: "Bash", session_id: "c7", tool_input: {command: "xcodebuild build"}, error: "error: non-Sendable type"}')")")" = PostToolUseFailure ] ||
  fail "the reminder should be tagged with the event that fired it"
context concurrency-skill.sh "$(jq -n '{hook_event_name: "PostToolUse", tool_name: "mcp__xcode__BuildProject", session_id: "c3",
  tool_response: [{type: "text", text: "{\"errors\":[{\"message\":\"Main actor-isolated property cannot be referenced\"}]}"}]}')"
[[ "$out" == *swift-concurrency* ]] || fail "an Xcode MCP build's diagnostic should name swift-concurrency: $out"
for event in PostToolUse PostToolUseFailure; do
  for tool in Bash mcp__xcode__BuildProject mcp__xcode__RunSomeTests mcp__xcode__GetBuildLog mcp__xcode__XcodeRefreshCodeIssuesInFile; do
    hook_wired "$event" concurrency-skill.sh "$tool"
  done
done

# xcodebuild-runner.sh: a main session's xcodebuild build or test gets the MCP reminder; a subagent's does not.
bash_input() {
  jq -n --arg command "$1" --arg agent "${2:-}" '{hook_event_name: "PreToolUse", tool_name: "Bash", session_id: "x1",
    tool_input: {command: $command}} + (if $agent == "" then {} else {agent_id: $agent} end)'
}
for command in "xcodebuild -scheme HealthTracker build" "set -o pipefail && xcodebuild test | xcbeautify" \
  "cd /tmp; NSUnbufferedIO=YES xcodebuild build" "xcrun xcodebuild -scheme HealthTracker test" \
  "env NSUnbufferedIO=YES xcodebuild build" "time xcodebuild build-for-testing" "/usr/bin/xcodebuild build" \
  "if xcodebuild test; then :; fi" "{ xcodebuild build; }" $'grep -q x <<<"$y"\nxcodebuild build' "echo \`xcodebuild build\`" \
  $'xcodebuild -scheme HealthTracker \\\ntest'; do
  context xcodebuild-runner.sh "$(bash_input "$command")"
  [[ "$out" == *mcp__xcode__BuildProject* ]] || fail "a main-session xcodebuild should get the reminder: $command ($out)"
done
context xcodebuild-runner.sh "$(bash_input "xcodebuild test" agent-b)"
[ -z "$out" ] || fail "a subagent's xcodebuild should be silent: $out"
for command in "grep -rn xcodebuild scripts" "scripts/quality --fast" "git log --grep xcodebuild" \
  "xcodebuild -version" "xcodebuild -list -project HealthTracker.xcodeproj" 'echo "run xcodebuild build next"' \
  "xcodebuild -showBuildSettings -derivedDataPath build" $'gh pr create --body-file - <<EOF\nxcodebuild\n test\nEOF'; do
  context xcodebuild-runner.sh "$(bash_input "$command")"
  [ -z "$out" ] || fail "a command that neither builds nor tests should be silent: $command ($out)"
done
hook_wired PreToolUse xcodebuild-runner.sh Bash

# bootstrap-check.sh: a session starting in a checkout without the pinned tools is told to bootstrap.
mkdir -p "$WORK/fresh" "$WORK/ready/build/tools/bin"
git -C "$WORK/fresh" init -q
git -C "$WORK/ready" init -q
touch "$WORK/ready/build/tools/bin/swiftlint"
context bootstrap-check.sh "$(jq -n --arg cwd "$WORK/fresh" '{hook_event_name: "SessionStart", cwd: $cwd}')"
[ "$code" -eq 0 ] || fail "bootstrap-check should exit 0 (got $code): $out"
[[ "$out" == *scripts/bootstrap* ]] || fail "a checkout without build/tools/bin/swiftlint should be told to bootstrap: $out"
context bootstrap-check.sh "$(jq -n --arg cwd "$WORK/ready" '{hook_event_name: "SessionStart", cwd: $cwd}')"
[ -z "$out" ] || fail "a bootstrapped checkout should be silent: $out"
hook_wired SessionStart bootstrap-check.sh startup

# swift-bash-edits.sh: a Bash command that writes a .swift file is refused, so every Swift edit goes
# through Edit/Write and the format hook.
# decision <command> -> sets out (the permission decision and reason), code
decision() {
  deny swift-bash-edits.sh "$(jq -n --arg command "$1" --arg cwd "${2:-$ROOT}" '{hook_event_name: "PreToolUse",
    tool_name: "Bash", session_id: "w1", cwd: $cwd, tool_input: {command: $command}}')"
}
for command in "sed -i '' 's/a/b/' HealthTracker/Domain/Entities/Meal.swift" \
  "sed -Ei 's/a/b/' \"HealthTracker/My File.swift\"" "sed --in-place 's/a/b/' x.swift" \
  "perl -pi -e 's/a/b/' x.swift" "echo 'let a = 1' > HealthTracker/New.swift" "printf x >>x.swift" \
  "git show main:x.swift | tee x.swift" $'cat <<\'EOF\' > HealthTracker/New.swift\nstruct New {}\nEOF' \
  "cd HealthTracker && sed -i '' 's/a/b/' x.swift" "sed -i '' 's/a/b/' $ROOT/HealthTracker/Domain/Entities/Meal.swift" \
  $'gh pr create --body "notes" && git show HEAD:x.swift > HealthTracker/x.swift'; do
  decision "$command"
  [ "$code" -eq 0 ] || fail "swift-bash-edits should exit 0 (got $code): $out"
  [[ "$out" == deny* && "$out" == *Edit* ]] || fail "a Bash write to .swift should be denied, naming Edit: $command ($out)"
done
for command in "sed -n 1,20p x.swift" "sed 's/a/b/' x.swift > /dev/null" "cat x.swift" "grep -rn 'x > y.swift' ." \
  "swiftformat x.swift" "git mv a.swift b.swift" "sed -i '' 's/a/b/' notes.md" "xcodebuild build 2>&1 | tee build.log" \
  "echo 'write > a.swift later'" \
  $'gh pr create --title T --body "Summary\n\n- Move Old.swift -> New.swift and update callers"' \
  $'git commit -m "refactor\n\n- MealsView.swift -> MealsSectionView.swift (rename)"' \
  $'cat > /tmp/snippet.swift <<\'EOF\'\nlet x = 1\nEOF' "git show HEAD:X.swift > /tmp/old.swift" \
  'git show HEAD:X.swift > "$TMPDIR/old file.swift"'; do
  decision "$command"
  [ -z "$out" ] || fail "a command that writes no .swift file should pass: $command ($out)"
done
hook_wired PreToolUse swift-bash-edits.sh Bash

# gate-reminder.sh: a session stopping with Swift changed on the branch since the last green gate run
# (build/quality.json) is sent back to run the gate: a block whose reason Claude reads, once per
# session and gate run, and skipped when the stop already follows a Stop hook's block
# (stop_hook_active), so it can never loop.
# stop_message <repo> [PATH] [stop_hook_active] [session] -> sets out (the block's reason, or the raw
# output), code. Each call is a new session unless <session> is given.
stop_message() {
  local raw
  raw="$(jq -n --arg cwd "$1" --argjson active "${3:-false}" --arg session "${4:-g-$RANDOM$RANDOM}" '{hook_event_name: "Stop",
    session_id: $session, cwd: $cwd, stop_hook_active: $active}' | PATH="${2:-$PATH}" "$HOOKS/gate-reminder.sh" 2>&1)"
  code=$?
  out="$(jq -r 'select(.decision == "block") | .reason' <<<"$raw" 2>/dev/null || printf '%s' "$raw")"
  [ -z "$raw" ] || [ -n "$out" ] || fail "gate-reminder output should be a block with a reason: $raw"
}
GATE="$WORK/gate-repo"
git init -q -b main "$GATE"
gitc() { git -C "$GATE" -c user.name=t -c user.email=t@example.com -c commit.gpgsign=false "$@"; }
mkdir -p "$GATE/HealthTracker" "$GATE/build"
printf 'struct A {}\n' >"$GATE/HealthTracker/A.swift"
gitc add -A && gitc commit -q -m init
gitc switch -q -c feat/x
stop_message "$GATE"
[ "$code" -eq 0 ] && [ -z "$out" ] || fail "a branch without Swift changes should be silent (got $code): $out"
printf 'notes\n' >"$GATE/README.md"
stop_message "$GATE"
[ -z "$out" ] || fail "a non-Swift change should be silent: $out"
printf 'struct B {}\n' >"$GATE/HealthTracker/B.swift"
stop_message "$GATE"
[ "$code" -eq 0 ] || fail "gate-reminder should exit 0 (got $code): $out"
[[ "$out" == *scripts/quality* && "$out" == *table* ]] || fail "an untracked Swift file without a gate run should be reminded: $out"
stop_message "$GATE" "$PATH" false same
stop_message "$GATE" "$PATH" false same
[ -z "$out" ] || fail "a session already sent back for this gate run should be let through: $out"
touch -t 202601010000 "$GATE/HealthTracker/B.swift"
printf '{"passed": true}\n' >"$GATE/build/quality.json"
stop_message "$GATE"
[ -z "$out" ] || fail "a gate run newer than every Swift change should be silent: $out"
printf '{"passed": false}\n' >"$GATE/build/quality.json"
stop_message "$GATE" "$PATH" false same
[[ "$out" == *scripts/quality* ]] || fail "a red gate run should not count, and should re-arm the session's reminder: $out"
printf '{"passed": true}\n' >"$GATE/build/quality.json"
gitc add -A && gitc commit -q -m b
printf 'struct A { let a = 1 }\n' >"$GATE/HealthTracker/A.swift"
touch -t 202601010000 "$GATE/build/quality.json"
stop_message "$GATE" "$PATH" false same
[[ "$out" == *scripts/quality* ]] || fail "after a new gate run, a Swift edit newer than it should be reminded again: $out"
gitc add -A && gitc commit -q -m a
touch -t 202601010000 "$GATE/HealthTracker/A.swift" "$GATE/HealthTracker/B.swift"
stop_message "$GATE"
[ -z "$out" ] || fail "committed Swift older than the gate run should be silent: $out"
touch "$GATE/HealthTracker/B.swift"
stop_message "$GATE"
[[ "$out" == *scripts/quality* ]] || fail "a committed Swift change newer than the gate run should be reminded: $out"
rm "$GATE/HealthTracker/B.swift"
touch -t 202601010000 "$GATE/HealthTracker/A.swift"
stop_message "$GATE"
[ -z "$out" ] || fail "a deleted Swift file has no mtime to compare and should be silent: $out"
# A name find could read as an option, or that git would quote, is still compared.
for name in "-x.swift" "Ação.swift"; do
  printf 'struct C {}\n' >"$GATE/$name"
  stop_message "$GATE"
  [[ "$out" == *scripts/quality* ]] || fail "a new $name should be reminded: $out"
  rm -- "$GATE/$name"
done
gitc checkout -q -- HealthTracker/B.swift
touch "$GATE/HealthTracker/B.swift"
stop_message "$GATE" "$PATH" true
[ "$code" -eq 0 ] && [ -z "$out" ] || fail "a stop after a Stop hook's block should be let through (got $code): $out"
# A gate still running in the checkout (a live pid in build/quality.pids) will write its own table.
mkdir -p "$GATE/scripts" "$GATE/build/quality.pids"
printf '#!/bin/sh\nsleep 30\n' >"$GATE/scripts/quality"
chmod +x "$GATE/scripts/quality"
"$GATE/scripts/quality" &
gate_pid=$!
touch "$GATE/build/quality.pids/$gate_pid"
stop_message "$GATE"
[ -z "$out" ] || fail "a stop while a gate runs should be silent: $out"
kill "$gate_pid"
wait "$gate_pid" 2>/dev/null
stop_message "$GATE"
[[ "$out" == *scripts/quality* ]] || fail "a stale pid file should not silence the reminder: $out"
rm -rf "$GATE/scripts" "$GATE/build/quality.pids"
# A cloud session (no xcrun) runs the gate on CI instead, so it is never reminded.
mkdir -p "$WORK/no-xcrun-bin"
ln -sf "$(command -v jq)" "$WORK/no-xcrun-bin/jq"
for tool in git dirname find; do
  ln -sf "$(command -v "$tool")" "$WORK/no-xcrun-bin/$tool"
done
stop_message "$GATE" "$WORK/no-xcrun-bin:/bin"
[ -z "$out" ] || fail "a session without xcrun should be silent: $out"
stop_message "$WORK/no-repo"
[ "$code" -eq 0 ] && [ -z "$out" ] || fail "a cwd outside a checkout should be silent (got $code): $out"
hook_wired Stop gate-reminder.sh Stop
# Subagents (Explore, review passes) are left alone: the orchestrator's own Stop covers the branch.
jq -e '.hooks | has("SubagentStop")' "$SETTINGS" >/dev/null && fail "gate-reminder should not run on SubagentStop"

[ "$failures" -eq 0 ]
