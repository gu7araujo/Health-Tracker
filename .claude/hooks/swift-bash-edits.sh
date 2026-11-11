#!/usr/bin/env bash
# Claude Code PreToolUse hook on Bash: refuses a command that writes a .swift file (sed -i, perl -i,
# a > or >> redirect, tee), so every Swift edit goes through Edit/Write, where format-swift.sh
# formats and lints it. A heuristic: a script that writes files itself (python, swift) passes.
set -uo pipefail
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"

awk '/\.swift([ \t]|$)/ && (/^(sed|perl)[ \t]/ && /[ \t](-[A-Za-z]*i|--in-place)([ \t=]|$)/ || /^tee[ \t]/) { found = 1 }
  />>?[ \t]*[^ \t>&]*\.swift([ \t]|$)/ { found = 1 }
  END { exit !found }' <<<"$(simple_commands)" || exit 0

jq -n '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason:
  "This command writes a .swift file from Bash, which skips the format hook. Make the change with the Edit or Write tool (one call per file) instead."}}'
