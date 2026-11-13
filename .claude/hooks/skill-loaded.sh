#!/usr/bin/env bash
# Claude Code PostToolUse hook on Skill: records each loaded skill per session and agent, so
# skill-required.sh can refuse an edit whose skill was never called.
set -uo pipefail
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"

skill="$(field .tool_input.skill)"
[ -n "$skill" ] || exit 0
first_time "$(skill_marker "$skill")"
exit 0
