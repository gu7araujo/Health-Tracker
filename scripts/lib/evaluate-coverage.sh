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

  excepted="$(sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$EXCEPTIONS" | jq -R . | jq -s .)"
  floored="$(app_files "$XCCOV" "$REPO_ROOT" | jq --argjson excepted "$excepted" \
    'map(select((.path | startswith("HealthTracker/Presentation/Views/") | not) and (.path | IN($excepted[]) | not))
      | .pct = .covered / .executable * 100)')"
  jq -r --argjson floor "$FILE_FLOOR" '.[] | select(.pct < $floor) | "\(.path)\t\(.pct)"' <<<"$floored" |
    while IFS=$'\t' read -r path pct; do
      printf '  below floor: %s %.2f%%\n' "$path" "$pct" >&2
    done
  # "<line>\t<path>" for every exception entry whose file meets the floor.
  stale="$(awk '{ sub(/#.*/, ""); gsub(/^[[:space:]]+|[[:space:]]+$/, "") } $0 != "" { print NR "\t" $0 }' "$EXCEPTIONS" |
    while IFS=$'\t' read -r line path; do
      app_files "$XCCOV" "$REPO_ROOT" | jq -r --arg path "$path" --arg line "$line" --argjson floor "$FILE_FLOOR" \
        '.[] | select(.path == $path) | .covered / .executable * 100 | select(. >= $floor) | "\($line)\t\($path)\t\(.)"'
    done)"
  while IFS=$'\t' read -r line path pct; do
    [ -n "$path" ] || continue
    printf '  stale exception: %s:%s: %s %.2f%% (meets the floor; remove the entry)\n' "$EXCEPTIONS" "$line" "$path" "$pct" >&2
  done <<<"$stale"
  row "Per-file floor" "$(jq 'map(.pct) | min // 100' <<<"$floored")" "$FILE_FLOOR" "$(grep -c . <<<"$stale")"
fi

exit "$failed"
