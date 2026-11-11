#!/usr/bin/env bash
# Claude Code PreToolUse hook on Bash: when a main session (no agent_id) runs xcodebuild, reminds
# it of the runner rule in AGENTS.md (Building and Validating). Non-blocking; subagents are left
# alone, since workflow agents build through scripts/quality.
set -uo pipefail

input="$(cat)"
[ -z "$(jq -r '.agent_id // empty' <<<"$input")" ] || exit 0
# xcodebuild in command position: at the start, or after ; & | ( and optional VAR=value prefixes.
grep -qE '(^|[;&|(])[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*xcodebuild([[:space:]]|$)' \
  <<<"$(jq -r '.tool_input.command // empty' <<<"$input")" || exit 0

jq -n '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext:
  "Main session: build and test with mcp__xcode__BuildProject / RunSomeTests. Use xcodebuild only after an MCP build or test call returned an error, and quote that error to the user; if the Xcode MCP is disconnected, ask the user to run /mcp instead."}}'
