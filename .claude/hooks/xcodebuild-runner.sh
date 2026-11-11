#!/usr/bin/env bash
# Claude Code PreToolUse hook on Bash: when a main session (no agent_id) runs an xcodebuild build or
# test, reminds it of the runner rule in AGENTS.md (Building and Validating). Non-blocking;
# subagents are left alone, and so are xcodebuild queries such as -version or -list.
set -uo pipefail
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"

[ -z "$(field .agent_id)" ] || exit 0
command="$(field .tool_input.command)"
# xcodebuild as a command word (after a separator, a wrapper such as xcrun/env/time, or a path),
# and a build or test action word.
grep -qE '(^|[[:space:];&|({/])xcodebuild([[:space:]]|$)' <<<"$command" || exit 0
grep -qE '[[:space:]](build|test|build-for-testing|test-without-building|analyze|archive)([[:space:];&|)}]|$)' <<<"$command" || exit 0

context PreToolUse "Main session: build and test with mcp__xcode__BuildProject / RunSomeTests. Use xcodebuild only after an MCP build or test call returned an error, and quote that error to the user; if the Xcode MCP is disconnected, ask the user to run /mcp instead."
