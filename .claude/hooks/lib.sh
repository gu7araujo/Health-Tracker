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

# simple_commands: the Bash call's command as one simple command per line, each starting at its
# command word. Continued lines are joined; heredoc bodies (up to their terminator), VAR=value
# prefixes and wrappers (env, time, xcrun, exec, nohup, if/then/else, do/while/until, !) are
# dropped, and so are quoted strings, even across lines, except that one naming a .swift file
# becomes that path with its blanks and shell operators turned to _. A heuristic for the routing hooks, not a shell
# parser.
simple_commands() {
  local command
  command="$(field .tool_input.command)"
  command="${command//\\$'\n'/ }"
  awk -v q="'" '
    skip { line = $0; if (tabs) sub(/^\t+/, "", line); if (line == delim) skip = 0; next }
    { print; line = $0; gsub(/<<</, "", line) }
    match(line, "<<-?[ \t]*[\"" q "]?[A-Za-z_][A-Za-z0-9_]*") {
      delim = substr(line, RSTART, RLENGTH)
      tabs = delim ~ /^<<-/
      sub("^<<-?[ \t]*[\"" q "]?", "", delim)
      skip = 1
    }' <<<"$command" |
    perl -0777 -pe 's{(\x27[^\x27]*\x27|"(?:[^"\\]|\\.)*")}{
      my $m = $1; $m =~ /\.swift["\x27]\z/ ? do { (my $w = substr($m, 1, -1)) =~ s/[\s<>|;&()`{}]/_/g; $w } : "" }gse' |
    tr ';&|(){}`' '\n' |
    awk '{
      sub(/^[ \t]+/, "")
      while (match($0, /^([A-Za-z_][A-Za-z0-9_]*=[^ \t]*|env|time|xcrun|exec|nohup|if|then|else|do|while|until|!)([ \t]+|$)/))
        $0 = substr($0, RLENGTH + 1)
      if ($0 != "") print
    }'
}

# context <event> <text>: prints the hook output that adds <text> to the agent's context.
context() {
  jq -n --arg event "$1" --arg text "$2" '{hookSpecificOutput: {hookEventName: $event, additionalContext: $text}}'
}
