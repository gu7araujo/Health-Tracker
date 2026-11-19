#!/usr/bin/env bash
# Claude Code PreToolUse hook on file writes and Bash: the first edit in a layer, or the first Bash
# read of its code (cat, sed, grep...), per session and agent, names that layer's AGENTS.md and the
# skill to call. Claude Code loads a nested AGENTS.md only when the Read tool opens a file under it,
# so an agent that reads code through Bash never sees it.
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

# The paths the tool touches, one per line, relative to the checkout.
if [ "$(field .tool_name)" = Bash ]; then
  verb=Reading
  checkout="$(own_checkout "$(field .cwd)")" || exit 0
  # The arguments of each reading command; a directory gets a trailing / so it maps to its layer.
  paths="$(simple_commands |
    awk '$1 ~ /^([^ \t]*\/)?(cat|head|tail|sed|nl|less|grep|rg|awk)$/ {
      for (i = 2; i <= NF; i++) if ($i !~ /^-/) print $i "/"
    }')"
else
  verb=Editing
  checkout=""
  paths="$(edited_path)" || exit 0
fi

message=""
while IFS= read -r rel; do
  [ -z "$checkout" ] || rel="${rel#"$checkout"/}"
  layer_doc "${rel#./}" || continue
  first_time "${doc//\//_}" || continue
  message="$message${message:+ }$verb ${doc%/AGENTS.md}: read $doc first ($call)."
done <<<"$paths"
[ -z "$message" ] || context PreToolUse "$message"
