#!/usr/bin/env bash
# Prints the region coverage (%) of HealthTracker/Domain/ and then HealthTracker/Data/, one per
# line, from a test run's profile. Prints nothing (unmeasured) when the profdata or binary is
# missing or llvm-cov fails.
#
# Usage: region-coverage.sh <Coverage.profdata> <binary> <repo-root>
set -euo pipefail

PROFDATA="$1"
BINARY="$2"
REPO_ROOT="${3%/}"

[ -f "$PROFDATA" ] && [ -f "$BINARY" ] || exit 1
export_json="$(xcrun llvm-cov export -summary-only -instr-profile "$PROFDATA" "$BINARY")"
jq -r --arg root "$REPO_ROOT/HealthTracker/" '.data[0].files as $files | ("Domain/", "Data/")
  | . as $layer | [$files[] | select(.filename | startswith($root + $layer)) | .summary.regions]
  | (map(.covered) | add) * 100 / (map(.count) | add)' <<<"$export_json"
