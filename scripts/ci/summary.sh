#!/usr/bin/env bash
# Renders scripts/quality's JSON report as GitHub-flavoured Markdown for $GITHUB_STEP_SUMMARY.
#
# Usage: scripts/ci/summary.sh <build/quality.json> >>"$GITHUB_STEP_SUMMARY"
# Always exits 0: the quality step itself fails the job.
set -uo pipefail

if [ ! -f "$1" ]; then
  echo "## ❌ Quality gate: no report"
  echo
  echo "\`$1\` was not written; scripts/quality stopped early. See the job log."
  exit 0
fi

jq -r '
  def unit: if .comparator == ">=" then "%" else "" end;
  def mark: if .passed then "✅" else "❌" end;
  "## \(mark) Quality gate (\(.mode)): \(if .passed then "passed" else "failed" end)",
  "",
  "| Gate | Value | Threshold | Result |",
  "|---|---|---|---|",
  (.gates[] | "| \(.name) | \(if .value == null then "n/a" else "\(.value)\(unit)" end) | \(.comparator) \(.threshold)\(unit) | \(mark) |")
' "$1"
