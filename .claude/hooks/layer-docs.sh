#!/usr/bin/env bash
# Claude Code PreToolUse hook on file writes and Bash: the first edit in a layer, per session and
# agent, names that layer's AGENTS.md and the skill to call; the first Bash read of its code (cat,
# sed, grep...) names the AGENTS.md only, under a marker of its own. Claude Code loads a nested
# AGENTS.md only when the Read tool opens a file under it, so an agent that reads code through Bash
# never sees it.
set -uo pipefail
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"

# layer_doc <path relative to the checkout>: sets doc and call for its layer; fails outside them.
layer_doc() {
  case "$1" in
    HealthTracker/Presentation/Intents/*)
      doc=HealthTracker/Presentation/Intents/AGENTS.md
      call='HealthTracker/Presentation/AGENTS.md too, and call Skill("app-intents-specialist") (+ app-intents-whats-new-27 for iOS 26/27 APIs)'
      ;;
    HealthTracker/Presentation/*)
      doc=HealthTracker/Presentation/AGENTS.md
      call='call Skill("swiftui-specialist") (+ swiftui-whats-new-27 for iOS 27 APIs); after a View change, RenderPreview it'
      ;;
    HealthTracker/Domain/*) doc=HealthTracker/Domain/AGENTS.md call='call Skill("tdd")' ;;
    HealthTracker/Data/*) doc=HealthTracker/Data/AGENTS.md call='call Skill("tdd")' ;;
    HealthTrackerTests/*)
      doc=HealthTrackerTests/AGENTS.md
      call='call Skill("tdd") and Skill("swift-testing-expert:swift-testing-expert")'
      ;;
    HealthTrackerUITests/*) doc=HealthTrackerUITests/AGENTS.md call='call Skill("tdd")' ;;
    HealthTrackerIntentsUITests/*)
      doc=HealthTrackerIntentsUITests/AGENTS.md
      call='HealthTrackerUITests/AGENTS.md too, and call Skill("tdd")'
      ;;
    scripts/* | .githooks/* | .github/*) doc=scripts/AGENTS.md call='write the test first in scripts/tests' ;;
    *) return 1 ;;
  esac
}

# normalized <absolute path>: the path with its . and .. segments resolved, ending in /.
normalized() {
  local segment out=""
  local -a segments
  IFS=/ read -ra segments <<<"$1"
  for segment in "${segments[@]}"; do
    case "$segment" in
      "" | .) ;;
      ..) out="${out%/*}" ;;
      *) out="$out/$segment" ;;
    esac
  done
  printf '%s/' "$out"
}

# The paths the tool touches, one per line: relative to the checkout for an edit; for a Bash read,
# the arguments of each reading command, a directory with a trailing / so it maps to its layer.
if [ "$(field .tool_name)" = Bash ]; then
  paths="$(simple_commands |
    awk '$1 ~ /^([^ \t]*\/)?(cat|head|tail|sed|nl|less|grep|rg|awk)$/ {
      for (i = 2; i <= NF; i++) if ($i !~ /^-/) print $i "/"
    }')"
  [ -n "$paths" ] || exit 0
  cwd="$(field .cwd)"
  checkout="$(own_checkout "$cwd")" || exit 0
  cwd="$(cd "$cwd" && pwd -P)" || exit 0
else
  checkout=""
  paths="$(edited_path)" || exit 0
fi

message=""
while IFS= read -r rel; do
  if [ -n "$checkout" ]; then
    [[ "$rel" == /* ]] || rel="$cwd/$rel"
    rel="$(normalized "$rel")"
    rel="${rel#"$checkout"/}"
  fi
  layer_doc "${rel#./}" || continue
  # A read keeps its own marker, so the first edit in the layer still gets the skill to call.
  if [ -n "$checkout" ]; then
    first_time "read-${doc//\//_}" || continue
    message="$message${message:+ }Reading ${doc%/AGENTS.md}: its rules are in $doc; read it before working there."
  else
    first_time "${doc//\//_}" || continue
    message="$message${message:+ }Editing ${doc%/AGENTS.md}: read $doc first ($call)."
  fi
done <<<"$paths"
[ -z "$message" ] || context PreToolUse "$message"
