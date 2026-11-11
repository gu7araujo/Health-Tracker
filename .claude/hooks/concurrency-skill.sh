#!/usr/bin/env bash
# Claude Code PostToolUse and PostToolUseFailure hook on Bash and the Xcode MCP build tools: when a
# build's output (or a failed build's error) holds a Swift concurrency diagnostic, tells the agent
# to call the swift-concurrency skill before fixing it. Bash counts only when a simple command in
# it builds or prints a build log (xcodebuild, swift build/test, scripts/quality, git push and its
# pre-push gate, gh run view/watch), so reading code or a diff that quotes a diagnostic stays
# silent. Once per session and agent.
set -uo pipefail
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"

if [ "$(field .tool_name)" = Bash ]; then
  awk '/^([^ \t]*\/)?(xcodebuild|quality)([ \t]|$)/ || /^swift[ \t]+(build|test)/ ||
    /^git[ \t]+push([ \t]|$)/ || /^gh[ \t]+run[ \t]+(view|watch)/ { found = 1 }
    END { exit !found }' <<<"$(simple_commands)" || exit 0
fi
output="$(field '([.tool_response, .error] | map(select(. != null) | if type == "string" then . else tojson end) | join("\n"))')"
# Swift 6 wording: "<x> actor-isolated", "global actor 'X'-isolated", "non-Sendable", "'Sendable'
# protocol", "not concurrency-safe", "concurrently-executing code", "risks causing data races".
grep -qiE "actor-isolated|'-isolated|non-sendable|'sendable'|concurrency-safe|concurrently-executing|data race" <<<"$output" || exit 0

first_time concurrency || exit 0
context "$(field .hook_event_name)" 'That output has a Swift concurrency diagnostic: call Skill("swift-concurrency:swift-concurrency") before fixing it, and fix every call site that shares the cause.'
