#!/usr/bin/env bash
# .periphery.yml: the scan scripts/quality runs fails on any unused code (strict), with no baseline
# file to hide findings behind.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CONFIG="$ROOT/.periphery.yml"
failures=0

fail() {
  printf '  FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

[ -f "$CONFIG" ] || {
  echo "  FAIL: no .periphery.yml at the repo root"
  exit 1
}
for line in 'project: HealthTracker.xcodeproj' 'schemes:' '  - HealthTracker' 'strict: true' \
  'relative_results: true' 'disable_update_check: true'; do
  grep -qxF -- "$line" "$CONFIG" || fail ".periphery.yml should contain '$line'"
done
! grep -qE '^(baseline|write_baseline):' "$CONFIG" || fail ".periphery.yml should not use a baseline file"

[ "$failures" -eq 0 ]
