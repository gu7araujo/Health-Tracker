#!/usr/bin/env bash
# Claude Code PostToolUse hook on Bash and the Xcode MCP build tools: when the output holds a
# Swift concurrency diagnostic (actor isolation, Sendable, data race), tells the agent to call the
# swift-concurrency skill before fixing it. Once per session and agent, via a marker under
# $TMPDIR/claude-hooks.
set -uo pipefail

input="$(cat)"
field() { jq -r "$1 // empty" <<<"$input"; }

grep -qiE "actor-isolated|non-sendable|conform to the 'sendable' protocol|risks causing data races" \
  <<<"$(jq -r '.tool_response | if type == "string" then . else tojson end' <<<"$input")" || exit 0

agent="$(field .agent_id)"
marker="${TMPDIR:-/tmp}/claude-hooks/$(field .session_id)-${agent:-main}-concurrency"
[ ! -e "$marker" ] || exit 0
mkdir -p "$(dirname "$marker")" && touch "$marker"

jq -n '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext:
  "That output has a Swift concurrency diagnostic: call Skill(\"swift-concurrency:swift-concurrency\") before fixing it, and fix every call site that shares the cause."}}'
