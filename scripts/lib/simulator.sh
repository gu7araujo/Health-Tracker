#!/usr/bin/env bash
# Prints the udid of the simulator named <name>, cloning one if it does not exist yet, so test runs
# never touch Xcode's shared clone pool. Runtimes are preferred newest iOS 26.x first, then newest
# iOS. The clone comes from a shut-down SIMULATOR_DEVICE (scripts/tool-versions.env) on the first
# runtime that has one; with none anywhere, from the first shut-down iPhone on the preferred runtime,
# with a warning. An existing <name> of another model than that device is deleted and re-cloned,
# unless it is booted.
#
# Usage: simulator.sh <name>
set -euo pipefail

# shellcheck source=../tool-versions.env
source "$(dirname "$0")/../tool-versions.env"

NAME="$1"
devices="$(xcrun simctl list devices available -j)"

# first <filter>: "udid<TAB>deviceTypeIdentifier" of the first shut-down device matching <filter>,
# walking the runtimes in preference order.
first() {
  jq -r --arg pin "$SIMULATOR_DEVICE" '.devices | to_entries
    | map(select(.key | test("\\.iOS-")) | .version = (.key | capture("iOS-(?<v>[0-9-]+)$").v | split("-") | map(tonumber)))
    | sort_by([(.version[0] == 26), .version]) | reverse
    | [.[].value[] | select(.state == "Shutdown") | select('"$1"')][0] // empty
    | [.udid, .deviceTypeIdentifier] | @tsv' <<<"$devices"
}
IFS=$'\t' read -r pinned pinned_type < <(first '.name == $pin') || true

IFS=$'\t' read -r existing existing_type existing_state < <(jq -r --arg name "$NAME" \
  '[.devices[][] | select(.name == $name)][0] // empty | [.udid, .deviceTypeIdentifier, .state] | @tsv' <<<"$devices") || true
if [ -n "${existing:-}" ]; then
  if [ -z "${pinned:-}" ] || [ "$existing_type" = "$pinned_type" ]; then
    echo "$existing"
    exit 0
  fi
  # A booted clone is someone's session (see scripts/quality): keep it rather than tear it down.
  if [ "$existing_state" = "Booted" ]; then
    echo "warning: simulator $NAME is Booted, so it is kept although its model is not $SIMULATOR_DEVICE (SIMULATOR_DEVICE in scripts/tool-versions.env)" >&2
    echo "$existing"
    exit 0
  fi
  echo "Deleting simulator $NAME: its model is not $SIMULATOR_DEVICE (SIMULATOR_DEVICE in scripts/tool-versions.env)" >&2
  xcrun simctl delete "$existing"
fi

source="${pinned:-}"
if [ -z "$source" ]; then
  IFS=$'\t' read -r source _ < <(first '.name | startswith("iPhone")') || true
  if [ -z "${source:-}" ]; then
    echo "error: no shut-down iPhone on an iOS runtime to clone as $NAME" >&2
    exit 1
  fi
  echo "warning: no shut-down $SIMULATOR_DEVICE (SIMULATOR_DEVICE in scripts/tool-versions.env) on any iOS runtime; cloning $NAME from the first iPhone instead" >&2
fi

echo "Cloning simulator $NAME from $source" >&2
xcrun simctl clone "$source" "$NAME"
