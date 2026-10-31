#!/usr/bin/env bash
# Makes sure an iOS simulator runtime at least the iphonesimulator SDK's version is installed, so
# `scripts/quality --full` can run HealthTrackerIntentsUITests: its AppIntentsTesting links the
# SDK's iOS release (Xcode 27.2's fails to load on iOS 27.0), and runner images can ship only an
# older runtime. Only available runtimes count, and only the generic ones scripts/lib/simulator.sh
# clones from (iOS-27-2, not the device-specific iOS-27-2-iPhone19-4).
# Exits 0 at once when one is installed. Otherwise runs `xcodebuild -downloadPlatform iOS` and
# checks again; a freshly installed runtime with no SIMULATOR_DEVICE (scripts/tool-versions.env)
# gets one, since simulator.sh clones from it.
# Exit codes: 0 a runtime is available, 1 the download failed or still left none.
#
# Usage: install-simulator-runtime.sh
set -uo pipefail

# shellcheck source=../tool-versions.env
source "$(dirname "$0")/../tool-versions.env"

sdk="$(xcrun --sdk iphonesimulator --show-sdk-version)" || exit 1

# runtime: the identifier of the newest qualifying runtime, or nothing.
runtime() {
  xcrun simctl list runtimes -j | jq -r --arg min "$sdk" '[.runtimes[]
    | select(.isAvailable and (.identifier | test("\\.iOS-[0-9-]+$")))
    | .v = (.version | split(".") | map(tonumber))
    | select(.v >= ($min | split(".") | map(tonumber)))]
    | max_by(.v) | .identifier // empty'
}

id="$(runtime)"
if [ -n "$id" ]; then
  echo "$id is installed (iphonesimulator SDK $sdk)"
  exit 0
fi

echo "No iOS $sdk+ simulator runtime installed; downloading it: xcodebuild -downloadPlatform iOS"
xcodebuild -downloadPlatform iOS || exit 1
id="$(runtime)"
if [ -z "$id" ]; then
  echo "error: still no available iOS $sdk+ simulator runtime after xcodebuild -downloadPlatform iOS" >&2
  exit 1
fi
if ! xcrun simctl list devices available -j |
  jq -e --arg rt "$id" --arg pin "$SIMULATOR_DEVICE" '.devices[$rt] // [] | any(.name == $pin)' >/dev/null; then
  xcrun simctl create "$SIMULATOR_DEVICE" "$SIMULATOR_DEVICE" "$id" || exit 1
fi
echo "Installed $id"
