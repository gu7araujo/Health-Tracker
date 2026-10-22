#!/usr/bin/env bash
# Prints the number of failed test cases in one bundle of an
# `xcrun xcresulttool get test-results tests` report. Prints nothing (unmeasured)
# when the bundle never ran, or failed without a failing test case (e.g. a crash).
#
# Usage: test-failures.sh <tests.json> <bundle>
set -uo pipefail

jq -r --arg bundle "$2" '[.testNodes[].children[]? | select(.name == $bundle)][0]
  | if . == null then empty
    else . as $node | [.. | objects | select(.nodeType? == "Test Case" and .result == "Failed")] | length
      | if . == 0 and $node.result == "Failed" then empty else . end
    end' "$1" 2>/dev/null
