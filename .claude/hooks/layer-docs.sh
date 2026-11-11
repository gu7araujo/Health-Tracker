#!/usr/bin/env bash
# Claude Code PreToolUse hook on file writes: the first edit in a layer, per session and agent,
# names that layer's AGENTS.md and the skill to call. Claude Code loads a nested AGENTS.md only
# when the Read tool opens a file under it, so an agent that reads code through Bash never sees
# it. Marker files under $TMPDIR/claude-hooks keep it to one reminder per layer.
#
# Edit/Write pass an absolute `file_path`; the Xcode MCP write tools pass `filePath`,
# `<project name>/<path inside the checkout>`. Either way the path is matched by its tail.
set -uo pipefail

input="$(cat)"
field() { jq -r "$1 // empty" <<<"$input"; }

path="$(field .tool_input.file_path)"
[ -n "$path" ] || path="$(field .tool_input.filePath)"
case "/$path" in
  */HealthTracker/Presentation/Intents/*)
    doc=HealthTracker/Presentation/Intents/AGENTS.md
    call='HealthTracker/Presentation/AGENTS.md too, and call Skill("app-intents-specialist") (+ app-intents-whats-new-27 for iOS 27 APIs)'
    ;;
  */HealthTracker/Presentation/*)
    doc=HealthTracker/Presentation/AGENTS.md
    call='call Skill("swiftui-specialist") (+ swiftui-whats-new-27 for iOS 27 APIs); after a View change, RenderPreview it'
    ;;
  */HealthTracker/Domain/*) doc=HealthTracker/Domain/AGENTS.md call='call Skill("tdd")' ;;
  */HealthTracker/Data/*) doc=HealthTracker/Data/AGENTS.md call='call Skill("tdd")' ;;
  */HealthTrackerTests/*)
    doc=HealthTrackerTests/AGENTS.md
    call='call Skill("tdd") and Skill("swift-testing-expert:swift-testing-expert")'
    ;;
  */HealthTrackerUITests/*) doc=HealthTrackerUITests/AGENTS.md call='call Skill("tdd")' ;;
  */HealthTrackerIntentsUITests/*)
    doc=HealthTrackerIntentsUITests/AGENTS.md
    call='HealthTrackerUITests/AGENTS.md too, and call Skill("tdd")'
    ;;
  */scripts/* | */.githooks/* | */.github/*) doc=scripts/AGENTS.md call='write the test first in scripts/tests' ;;
  *) exit 0 ;;
esac

agent="$(field .agent_id)"
marker="${TMPDIR:-/tmp}/claude-hooks/$(field .session_id)-${agent:-main}-${doc//\//_}"
[ ! -e "$marker" ] || exit 0
mkdir -p "$(dirname "$marker")" && touch "$marker"

jq -n --arg context "Editing ${doc%/AGENTS.md}: read $doc first ($call)." \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $context}}'
