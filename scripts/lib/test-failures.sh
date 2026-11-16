#!/usr/bin/env bash
# Prints the number of failed test cases in one bundle of an
# `xcrun xcresulttool get test-results tests` report. Prints nothing (unmeasured)
# when the bundle never ran, or failed without a failing test case (e.g. a crash).
# With --list, prints each failed case instead, one per line: its identifier, then its first
# failure message (at any depth) when the report has one. --system lists, the same way, only the
# failed cases in a "System Failures" suite: the test runner's own errors, not a test's.
#
# Usage: test-failures.sh <tests.json> <bundle> [--list|--system]
set -uo pipefail

if [ "${3:-}" = "--list" ] || [ "${3:-}" = "--system" ]; then
  jq -r --arg bundle "$2" --arg mode "$3" '.testNodes[].children[]? | select(.name == $bundle)
    | .. | objects | select(.nodeType? == "Test Suite")
    | select($mode == "--list" or .name == "System Failures") | .name as $suite
    | .children[]? | select(.nodeType? == "Test Case" and .result == "Failed")
    | (.nodeIdentifier // "\($suite)/\(.name)")
      + ([.children[]? | .. | objects | select(.nodeType? == "Failure Message") | ": \(.name | gsub("\n"; " "))"][0] // "")' "$1" 2>/dev/null
  exit 0
fi

jq -r --arg bundle "$2" '[.testNodes[].children[]? | select(.name == $bundle)][0]
  | if . == null then empty
    else . as $node | [.. | objects | select(.nodeType? == "Test Case" and .result == "Failed")] | length
      | if . == 0 and $node.result == "Failed" then empty else . end
    end' "$1" 2>/dev/null
