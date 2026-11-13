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
# A plugin skill can only be loaded where its plugin is installed, for the user or for this project
# (a worktree shares its main checkout's install), and enabled by the merged settings (local over
# project over user). A cloud session or another clone may lack it.
if [[ "$skill" == *:* ]]; then
  config="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
  project="${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}"
  main="$(git -C "$project" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || exit 0
  id="$(jq -r --arg prefix "${skill%%:*}@" --arg main "${main%/.git}" 'first(.plugins | to_entries[]
    | select((.key | startswith($prefix)) and any(.value[]; .scope == "user" or .projectPath == $main)) | .key) // empty' \
    "$config/plugins/installed_plugins.json" 2>/dev/null)"
  [ -n "$id" ] || exit 0
  settings=()
  for file in "$config/settings.json" "$project/.claude/settings.json" "$project/.claude/settings.local.json"; do
    [ ! -f "$file" ] || settings+=("$file")
  done
  [ "${#settings[@]}" -gt 0 ] && jq -e -s --arg id "$id" 'map(.enabledPlugins // {} | select(has($id)) | .[$id]) | last == true' \
    "${settings[@]}" >/dev/null 2>&1 || exit 0
fi

jq -n --arg reason "Editing $rel needs Skill(\"$skill\") loaded in this session first ($doc). Call it, then retry the edit." \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
