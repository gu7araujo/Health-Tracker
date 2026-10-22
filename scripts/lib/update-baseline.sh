#!/usr/bin/env bash
# Ratchets DOMAIN_UNIT_MIN / DATA_UNIT_MIN in <thresholds.env> up to the measured
# unit-only coverage, rounded down to one decimal. Never lowers them.
#
# Usage: update-baseline.sh <xccov.json> <repo-root> <thresholds.env>
set -euo pipefail

XCCOV="$1"
REPO_ROOT="$2"
THRESHOLDS="$3"
# shellcheck source=coverage.sh
source "$(dirname "$0")/coverage.sh"

# ratchet <KEY> <path-prefix>
ratchet() {
  local current measured
  current="$(sed -n "s/^$1=//p" "$THRESHOLDS")"
  measured="$(layer_coverage "$XCCOV" "$REPO_ROOT" "$2" | awk '{ printf "%.1f", int($1 * 10) / 10 }')"
  if awk -v m="$measured" -v c="$current" 'BEGIN { exit !(m > c) }'; then
    sed -i '' "s/^$1=.*/$1=$measured/" "$THRESHOLDS"
    printf '%s raised %s -> %s\n' "$1" "$current" "$measured"
  else
    printf '%s kept at %s (measured %s)\n' "$1" "$current" "$measured"
  fi
}

ratchet DOMAIN_UNIT_MIN HealthTracker/Domain/
ratchet DATA_UNIT_MIN HealthTracker/Data/
