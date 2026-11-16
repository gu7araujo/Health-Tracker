#!/usr/bin/env bash
# Human-in-the-loop reproduction loop.
# The agent copies this file and edits the steps below. The user runs the copy:
# its prompts need a keyboard, which an agent's shell does not have.
#
# Usage (the user, in a terminal; in Claude Code, `! bash <copy>`):
#   bash <copy>.sh
#
# Two helpers:
#   step "<instruction>"          → show instruction, wait for Enter
#   capture VAR "<question>"      → show question, read response into VAR
#
# At the end, captured values are printed as KEY=VALUE for the agent to parse.
#
# `capture` prints its value back to the terminal, where the agent reads it,
# so capture observations only: never ask for a passcode or health data.

set -euo pipefail

step() {
  printf '\n>>> %s\n' "$1"
  read -r -p "    [Enter when done] " _
}

capture() {
  local var="$1" question="$2" answer
  printf '\n>>> %s\n' "$question"
  read -r -p "    > " answer
  printf -v "$var" '%s' "$answer"
}

# --- edit below ---------------------------------------------------------

step "Open HealthTracker in the Simulator and select yesterday in the calendar strip."

capture WRONG_DAY "Add a glass of water. Did it land on a different day? (y/n)"

capture SHOWN_DAY "Type the day the water shows under (or 'none'):"

# --- edit above ---------------------------------------------------------

printf '\n--- Captured ---\n'
printf 'WRONG_DAY=%s\n' "$WRONG_DAY"
printf 'SHOWN_DAY=%s\n' "$SHOWN_DAY"
