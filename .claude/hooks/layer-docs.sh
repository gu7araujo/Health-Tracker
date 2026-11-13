#!/usr/bin/env bash
# Claude Code PreToolUse hook on file writes: the first edit in a layer, per session and agent,
# names that layer's AGENTS.md and the skill to call. Claude Code loads a nested AGENTS.md only
# when the Read tool opens a file under it, so an agent that reads code through Bash never sees
# it.
set -uo pipefail
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"

rel="$(edited_path)" || exit 0

case "$rel" in
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
  *) exit 0 ;;
esac

first_time "${doc//\//_}" || exit 0
context PreToolUse "Editing ${doc%/AGENTS.md}: read $doc first ($call)."
