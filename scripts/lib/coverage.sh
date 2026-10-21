#!/usr/bin/env bash
# Shared helpers for reading an `xccov view --report --json` report. Source, don't run.

# app_files <xccov.json> <repo-root>
# Prints the HealthTracker.app files with executable lines as a JSON array of
# {path (repo-relative), covered, executable}.
app_files() {
  jq --arg root "${2%/}/" '[.targets[] | select(.name == "HealthTracker.app") | .files[]
    | select(.executableLines > 0)
    | {path: (.path | ltrimstr($root)), covered: .coveredLines, executable: .executableLines}]' "$1"
}

# layer_coverage <xccov.json> <repo-root> <path-prefix>
# Prints the aggregate line coverage (%) of app files under <path-prefix>.
layer_coverage() {
  app_files "$1" "$2" | jq --arg prefix "$3" \
    'map(select(.path | startswith($prefix))) | (map(.covered) | add) / (map(.executable) | add) * 100'
}
