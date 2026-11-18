#!/usr/bin/env bash
# scripts/ci/app-changes.sh exits 0 when a file in a NUL-separated list can change what --full
# checks (the app, its tests, the project, the gate that runs them, or --full's own settings and
# pinned runtime), so ci.yml's test job runs --full; 1 when none can, so it runs --fast.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$ROOT/scripts/ci/app-changes.sh"
failures=0

fail() {
  printf '  FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

# expect <status> <file>...: the script, fed those files NUL-separated, exits <status>.
expect() {
  want="$1"
  shift
  if [ $# -eq 0 ]; then "$SCRIPT" </dev/null; else printf '%s\0' "$@" | "$SCRIPT"; fi
  got=$?
  [ "$got" -eq "$want" ] || fail "expected exit $want, got $got for: $*"
}

expect 0 "HealthTracker/Presentation/My View.swift"
expect 0 HealthTracker/Resources/en.lproj/Localizable.strings
expect 0 HealthTrackerTests/DayDataTests.swift
expect 0 HealthTrackerUITests/JourneyUITests.swift
expect 0 HealthTrackerIntentsUITests/LogWaterIntentUITests.swift
expect 0 HealthTracker.xcodeproj/project.pbxproj
expect 0 scripts/quality
expect 0 scripts/lib/simulator.sh
# --full's own inputs: its coverage settings, the pinned runtime, Xcode and simulator, and the
# runtime download only a --full run makes.
expect 0 scripts/quality-thresholds.env
expect 0 scripts/coverage-exceptions.txt
expect 0 scripts/tool-versions.env
expect 0 scripts/ci/install-simulator-runtime.sh
expect 0 scripts/ci/summary.sh .github/workflows/ci.yml HealthTracker/App.swift
expect 1 scripts/ci/summary.sh
expect 1 .github/workflows/ci.yml .github/dependabot.yml
expect 1 .claude/hooks/format-swift.sh .claude/settings.json
expect 1 scripts/tests/test-ci-summary.sh scripts/fitness/run .githooks/pre-push
# Prefixes, not substrings: neighbours of the app paths stay out.
expect 1 HealthTrackerX/a.swift scripts/quality.bak scripts/libx/a.sh docs/HealthTracker/a.swift
# An empty list is a failed or empty diff: run --full rather than skip the UI suites on nothing.
expect 0
# A last entry without its trailing NUL still counts.
printf 'scripts/ci/summary.sh\0HealthTracker/App.swift' | "$SCRIPT" || fail "an unterminated last entry must still be checked"
# Under pipefail, a list larger than a pipe buffer must not fail the writer with SIGPIPE when the
# first entry is an app file: that would read as "no app change" and downgrade the run to --fast.
{ printf 'HealthTracker/App.swift\0'; for i in $(seq 5000); do printf 'scripts/ci/file-%05d.sh\0' "$i"; done; } |
  "$SCRIPT" || fail "an app file first in a list larger than a pipe buffer must still exit 0 under pipefail"

[ "$failures" -eq 0 ]
