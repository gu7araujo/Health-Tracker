# shellcheck shell=bash
# Sourced by the routing hooks in .claude/hooks: reads the hook's JSON input once, and names state
# files kept per session and agent under $TMPDIR/claude-hooks.

input="$(cat)"
field() { jq -r "$1 // empty" <<<"$input"; }

# state_path <name>: this session's and agent's (or the main session's) file for <name>.
state_path() {
  local agent
  agent="$(field .agent_id)"
  printf '%s/claude-hooks/%s-%s-%s' "${TMPDIR:-/tmp}" "$(field .session_id)" "${agent:-main}" "$1"
}

# first_time <name>: succeeds the first time it is called per session and agent, fails after.
first_time() {
  local marker
  marker="$(state_path "$1")"
  [ ! -e "$marker" ] || return 1
  mkdir -p "$(dirname "$marker")" && touch "$marker"
}

# context <event> <text>: prints the hook output that adds <text> to the agent's context.
context() {
  jq -n --arg event "$1" --arg text "$2" '{hookSpecificOutput: {hookEventName: $event, additionalContext: $text}}'
}
