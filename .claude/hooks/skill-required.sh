#!/usr/bin/env bash
# Claude Code PreToolUse hook on file writes: refuses an edit to a Swift file under
# Presentation/Views or HealthTrackerTests until its skill (swiftui-specialist,
# swift-testing-expert) has been loaded in this session and agent, as recorded by skill-loaded.sh.
# Other files, non-Swift ones in those directories included, pass, and so do a plugin skill's files
# where that plugin is not installed.
set -uo pipefail
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"

rel="$(edited_path)" || exit 0
case "$rel" in
  HealthTracker/Presentation/Views/*.swift) skill=swiftui-specialist doc=HealthTracker/Presentation/AGENTS.md ;;
  HealthTrackerTests/*.swift) skill=swift-testing-expert:swift-testing-expert doc=HealthTrackerTests/AGENTS.md ;;
  *) exit 0 ;;
esac
[ ! -e "$(state_path "$(skill_marker "$skill")")" ] || exit 0
# A plugin skill can only be loaded where its plugin is installed (a cloud session may lack it).
if [[ "$skill" == *:* ]]; then
  jq -e --arg plugin "${skill%%:*}@" '.plugins | keys | any(startswith($plugin))' \
    "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/installed_plugins.json" >/dev/null 2>&1 || exit 0
fi

jq -n --arg reason "Editing $rel needs Skill(\"$skill\") loaded in this session first ($doc). Call it, then retry the edit." \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
