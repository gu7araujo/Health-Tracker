#!/usr/bin/env bash
set -euo pipefail

SCHEME="HealthTracker"
DESTINATION="platform=iOS Simulator,id=${SIMULATOR_ID:?}"
RESULT="build/Test.xcresult"
THRESHOLD=95.0

printf 'Running quality gates...'

rm -rf "$RESULT" && xcodebuild test \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -enableCodeCoverage YES \
  -resultBundlePath "$RESULT" 2>&1 | xcbeautify > build/xcodebuild.log

JSON=$(xcrun xccov view --report --json "$RESULT")
LINE=$(echo "$JSON" | jq '.lineCoverage * 100')

passed=$(awk "BEGIN { print ($LINE >= $THRESHOLD) ? 1 : 0 }")
status="✗"
if [ "$passed" -eq 1 ]; then
  status="✓"
fi

printf '\nQuality gates result:\n\n'
printf 'Line coverage    %.1f%% >= %.1f%% %s\n' "$LINE" "$THRESHOLD" "$status"

if [ "$passed" -eq 1 ]; then
  printf '\n1/1 gates passed.\n'
  exit 0
else
  printf '\n0/1 gates passed.\n'
  exit 1
fi