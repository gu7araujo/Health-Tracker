#!/usr/bin/env bash
# Renders gate rows as a table and, optionally, as JSON.
#
# Usage: report.sh <mode> [json-out] < rows
#   rows: name<TAB>value<TAB>comparator<TAB>threshold<TAB>passed(true|false), one per gate.
#         value "n/a" means the metric could not be measured (JSON null).
#         ">=" gates are percentages, "<=" gates are counts.
# Prints the table and "N/M gates passed." to stdout. Exits 0 only if every gate passed.
set -euo pipefail

MODE="$1"
JSON_OUT="${2:-}"
rows="$(cat)"

total=0
passed=0
printf '\n'
while IFS=$'\t' read -r name value comparator threshold ok; do
  unit=""
  [ "$comparator" = ">=" ] && unit="%"
  shown="$value$unit"
  [ "$value" = "n/a" ] && shown="n/a"
  mark="✗"
  [ "$ok" = "true" ] && mark="✓" && passed=$((passed + 1))
  total=$((total + 1))
  printf '%-28s %9s  %s %-7s %s\n' "$name" "$shown" "$comparator" "$threshold$unit" "$mark"
done <<<"$rows"
printf '\n%d/%d gates passed.\n' "$passed" "$total"

if [ -n "$JSON_OUT" ]; then
  mkdir -p "$(dirname "$JSON_OUT")"
  jq -R 'split("\t") | {name: .[0], value: (.[1] | tonumber? // null), threshold: (.[3] | tonumber),
      comparator: .[2], passed: (.[4] == "true")}' <<<"$rows" |
    jq -s --arg mode "$MODE" '{mode: $mode, passed: all(.[]; .passed), gates: .}' >"$JSON_OUT"
fi

[ "$passed" -eq "$total" ]
