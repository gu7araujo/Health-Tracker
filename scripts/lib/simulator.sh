#!/usr/bin/env bash
# Prints the udid of the simulator named <name>, cloning one if it does not exist yet.
# The clone comes from a shut-down iPhone on the newest available iOS 26.x runtime
# (else the newest iOS runtime), so test runs never touch Xcode's shared clone pool.
#
# Usage: simulator.sh <name>
set -euo pipefail

NAME="$1"
devices="$(xcrun simctl list devices available -j)"

existing="$(jq -r --arg name "$NAME" '[.devices[][] | select(.name == $name)][0].udid // empty' <<<"$devices")"
if [ -n "$existing" ]; then
  echo "$existing"
  exit 0
fi

source="$(jq -r '.devices | to_entries
  | map(select(.key | test("\\.iOS-")) | .version = (.key | capture("iOS-(?<v>[0-9-]+)$").v | split("-") | map(tonumber)))
  | sort_by([(.version[0] == 26), .version]) | reverse
  | [.[].value[] | select((.name | startswith("iPhone")) and .state == "Shutdown")][0].udid // empty' <<<"$devices")"
if [ -z "$source" ]; then
  echo "error: no shut-down iPhone on an iOS runtime to clone as $NAME" >&2
  exit 1
fi

echo "Cloning simulator $NAME from $source" >&2
xcrun simctl clone "$source" "$NAME"
