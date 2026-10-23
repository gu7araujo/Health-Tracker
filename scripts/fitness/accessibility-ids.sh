#!/usr/bin/env bash
# Every identifier the UI tests' hand-mirrored AccessibilityID declares must exist in the app's
# AccessibilityID (UI rule_2). App-only identifiers are fine: not every ID is tested.
#
# Each string literal outside // comments is an identifier:
#   - a plain literal ("addRecordButton") must equal an app literal, or start with the literal
#     prefix of an app template (the app's moodButton(_:) builds "moodButton_good");
#   - an interpolated literal ("calendarDay_\(offset)") is a template, compared by its literal
#     prefix ("calendarDay_") with the app's templates.
#
# Usage: accessibility-ids.sh [repo-root]
# Prints one line per mirror identifier missing from the app; exits 1 if any.
set -euo pipefail

REPO="${1:-$(cd "$(dirname "$0")/../.." && pwd)}"
APP=HealthTracker/Presentation/AccessibilityID.swift
MIRROR=HealthTrackerUITests/Support/AccessibilityID.swift

awk -v app="$APP" -v mirror="$MIRROR" '
  {
    sub(/\/\/.*/, "")
    rest = $0
    while (match(rest, /"[^"]*"/)) {
      literal = substr(rest, RSTART + 1, RLENGTH - 2)
      rest = substr(rest, RSTART + RLENGTH)
      template = index(literal, "\\(")
      if (FILENAME == ARGV[1]) {
        if (template) prefixes[substr(literal, 1, template - 1)] = 1
        else exact[literal] = 1
      } else if (template) {
        prefix = substr(literal, 1, template - 1)
        if (!(prefix in prefixes)) missing(prefix "\\(…)")
      } else if (!(literal in exact) && !expands(literal)) {
        missing(literal)
      }
    }
  }
  function expands(value,   prefix) {
    for (prefix in prefixes) if (prefix != "" && index(value, prefix) == 1) return 1
    return 0
  }
  function missing(id) {
    printf "accessibility-ids: %s:%d: \"%s\" not declared in %s\n", mirror, FNR, id, app
    violations++
  }
  END { exit (violations > 0) }
' "$REPO/$APP" "$REPO/$MIRROR"
