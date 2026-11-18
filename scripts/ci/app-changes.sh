#!/usr/bin/env bash
# Exits 0 when a changed file in a NUL-separated list on stdin can change what --full checks (the
# app, its tests, the project, the gate that runs them, or --full's own settings and pinned
# runtime), so ci.yml's test job runs --full; 1 when none can, so it runs --fast. An empty list
# exits 0 (a failed or empty diff runs the UI suites rather than skipping them).
# Usage: git diff --no-renames --name-only -z HEAD^1 HEAD | app-changes.sh
set -uo pipefail

PREFIXES=(HealthTracker/ HealthTrackerTests/ HealthTrackerUITests/ HealthTrackerIntentsUITests/
  HealthTracker.xcodeproj/ scripts/lib/)
FILES=(scripts/quality scripts/quality-thresholds.env scripts/coverage-exceptions.txt
  scripts/tool-versions.env scripts/ci/install-simulator-runtime.sh)

# is_app <file>
is_app() {
  for path in "${FILES[@]}"; do
    [ "$1" = "$path" ] && return 0
  done
  for prefix in "${PREFIXES[@]}"; do
    [[ "$1" == "$prefix"* ]] && return 0
  done
  return 1
}

# Reads the whole list, never exiting early: under pipefail, an early exit fails the writer with
# SIGPIPE on a list larger than a pipe buffer (scripts/AGENTS.md).
seen=0 app=0
while IFS= read -r -d '' file || [ -n "$file" ]; do # also an unterminated last entry
  seen=1
  is_app "$file" && app=1
done
[ "$seen" -eq 0 ] || [ "$app" -eq 1 ]
