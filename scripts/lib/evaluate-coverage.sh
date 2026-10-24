#!/usr/bin/env bash
# Evaluates the coverage gates for one test run.
#
# Usage: evaluate-coverage.sh <fast|full> <xccov.json> <repo-root> <thresholds.env> <exceptions.txt>
#   fast: Domain and Data unit line coverage against DOMAIN_UNIT_MIN / DATA_UNIT_MIN.
#   full: App line coverage against APP_LINE_MIN, and every app file outside
#         HealthTracker/Presentation/Views/ and not in <exceptions.txt> against FILE_FLOOR.
#         A listed file that meets FILE_FLOOR is a stale exception and fails the floor, so the list only shrinks.
# Prints one row per gate: name<TAB>value<TAB>comparator<TAB>threshold<TAB>passed.
# Files below the floor and stale exceptions are listed on stderr. Exits 1 if any gate fails.
set -euo pipefail

MODE="$1"
XCCOV="$2"
REPO_ROOT="$3"
# shellcheck source=../quality-thresholds.env
source "$4"
EXCEPTIONS="$5"
# shellcheck source=coverage.sh
source "$(dirname "$0")/coverage.sh"

failed=0

# row <name> <value> <threshold> [stale exception count]
row() {
  local passed
  passed=$(awk -v v="$2" -v t="$3" -v s="${4:-0}" 'BEGIN { print (v >= t && s == 0) ? "true" : "false" }')
  printf '%s\t%.2f\t>=\t%s\t%s\n' "$1" "$2" "$3" "$passed"
  [ "$passed" = "true" ] || failed=1
}

if [ "$MODE" = "fast" ]; then
  row "Domain unit line coverage" "$(layer_coverage "$XCCOV" "$REPO_ROOT" HealthTracker/Domain/)" "$DOMAIN_UNIT_MIN"
  row "Data unit line coverage" "$(layer_coverage "$XCCOV" "$REPO_ROOT" HealthTracker/Data/)" "$DATA_UNIT_MIN"
else
  row "App line coverage" "$(layer_coverage "$XCCOV" "$REPO_ROOT" HealthTracker/)" "$APP_LINE_MIN"

  exception_entries="$(awk '{ sub(/#.*/, ""); gsub(/^[[:space:]]+|[[:space:]]+$/, "") } $0 != "" { print NR "\t" $0 }' "$EXCEPTIONS")"
  exception_entries_json="$(jq -Rn --arg entries "$exception_entries" \
    '$entries | split("\n") | map(select(length > 0) | split("\t") | {line: .[0] | tonumber, path: .[1]})')"
  excepted="$(jq '[.[].path]' <<<"$exception_entries_json")"
  app_coverage="$(app_files "$XCCOV" "$REPO_ROOT")"
  floored="$(jq --argjson excepted "$excepted" \
    'map(select((.path | startswith("HealthTracker/Presentation/Views/") | not) and (.path | IN($excepted[]) | not))
      | .pct = .covered / .executable * 100)' <<<"$app_coverage")"
  jq -r --argjson floor "$FILE_FLOOR" '.[] | select(.pct < $floor) | "\(.path)\t\(.pct)"' <<<"$floored" |
    while IFS=$'\t' read -r path pct; do
      printf '  below floor: %s %.2f%%\n' "$path" "$pct" >&2
    done
  # "<line>\t<path>\t<status>\t<pct>" for stale exception entries.
  stale="$(jq -r --argjson entries "$exception_entries_json" --argjson floor "$FILE_FLOOR" '
    . as $files |
    $entries[] |
    . as $entry |
    ([$files[] | select(.path == $entry.path)] | first) as $file |
    if $file == null then
      "\($entry.line)\t\($entry.path)\tabsent"
    elif ($file.covered / $file.executable * 100) >= $floor then
      "\($entry.line)\t\($entry.path)\tcovered\t\($file.covered / $file.executable * 100)"
    else empty end
  ' <<<"$app_coverage")"
  while IFS=$'\t' read -r line path status pct; do
    [ -n "$path" ] || continue
    if [ "$status" = "absent" ]; then
      printf '  stale exception: %s:%s: %s absent from coverage (remove the entry)\n' "$EXCEPTIONS" "$line" "$path" >&2
    else
      printf '  stale exception: %s:%s: %s %.2f%% (meets the floor; remove the entry)\n' "$EXCEPTIONS" "$line" "$path" "$pct" >&2
    fi
  done <<<"$stale"
  row "Per-file floor" "$(jq 'map(.pct) | min // 100' <<<"$floored")" "$FILE_FLOOR" "$(grep -c . <<<"$stale")"
fi

exit "$failed"
