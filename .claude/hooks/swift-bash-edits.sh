#!/usr/bin/env bash
# Claude Code PreToolUse hook on Bash: refuses a command that writes a .swift file in the session's
# checkout (sed -i, perl -i, a > or >> redirect, tee), so every Swift edit goes through Edit/Write,
# where format-swift.sh formats and lints it. A relative target counts as in the checkout; an
# absolute one outside it (a /tmp scratch file) or one behind a variable passes. A heuristic: a
# script that writes files itself (python, swift) passes too.
set -uo pipefail
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"

checkout="$(git -C "$(field .cwd)" rev-parse --show-toplevel 2>/dev/null)"
targets="$(awk '{
  n = split($0, w, /[ \t]+/)
  if ((w[1] ~ /^(sed|perl)$/ && / -([A-Za-z]*i|-in-place)([ \t=.]|$)/) || w[1] == "tee")
    for (i = 2; i <= n; i++) if (w[i] ~ /\.swift$/) print w[i]
  s = $0
  while (match(s, />>?[ \t]*[^ \t>&]*\.swift([ \t]|$)/)) {
    t = substr(s, RSTART, RLENGTH); gsub(/^>>?[ \t]*|[ \t]$/, "", t); print t
    s = substr(s, RSTART + RLENGTH)
  }
}' <<<"$(simple_commands)")"

denied=""
while IFS= read -r target; do
  case "$target" in
    '') ;;
    /*) [[ -n "$checkout" && "$target" == "$checkout"/* ]] && denied="$target" ;;
    \~* | \$*) ;;
    *) denied="$target" ;;
  esac
done <<<"$targets"
[ -n "$denied" ] || exit 0

jq -n --arg file "$denied" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason:
  ("This command writes " + $file + " from Bash, which skips the format hook. Make the change with the Edit or Write tool (one call per file) instead.")}}'
