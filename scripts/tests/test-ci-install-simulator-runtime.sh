#!/usr/bin/env bash
# Tests scripts/ci/install-simulator-runtime.sh against a stubbed xcrun (SDK version, simctl
# runtimes and devices) and xcodebuild (the download, which installs $AFTER_RUNTIMES).
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$ROOT/scripts/ci/install-simulator-runtime.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
failures=0

fail() {
  printf '  FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

# shellcheck source=../tool-versions.env
source "$ROOT/scripts/tool-versions.env"

mkdir -p "$TMP/bin"
cat >"$TMP/bin/xcrun" <<EOF
#!/bin/sh
case "\$*" in
  "--sdk iphonesimulator --show-sdk-version") echo "\$SDK_VERSION" ;;
  "simctl list runtimes -j") cat "$TMP/runtimes.json" ;;
  "simctl list devices available -j") cat "$TMP/devices.json" ;;
  "simctl create "*) echo "\$*" >>"$TMP/calls" ;;
  *) echo "unexpected xcrun \$*" >&2; exit 1 ;;
esac
EOF
cat >"$TMP/bin/xcodebuild" <<EOF
#!/bin/sh
echo "xcodebuild \$*" >>"$TMP/calls"
[ -z "\$DOWNLOAD_FAILS" ] || exit 70
cp "\$AFTER_RUNTIMES" "$TMP/runtimes.json"
EOF
chmod +x "$TMP/bin/"*

# runtimes <file> <identifier:version:available>...: a `simctl list runtimes -j` listing.
runtimes() {
  local file="$1"
  shift
  printf '%s\n' "$@" | jq -R 'split(":") | {identifier: ("com.apple.CoreSimulator.SimRuntime." + .[0]), version: .[1], isAvailable: (.[2] == "true"), platform: "iOS"}' |
    jq -s '{runtimes: .}' >"$file"
}
# Before the download, as on the xcode-27 image: iOS 27.0, a device-specific 27.2 runtime (not one
# the gate clones from), and an unavailable 27.2 (e.g. a half-installed runtime).
runtimes "$TMP/before.json" iOS-26-5:26.5:true iOS-27-0:27.0:true iOS-27-2-iPhone19-4:27.2:true iOS-27-2:27.2:false
runtimes "$TMP/after.json" iOS-27-0:27.0:true iOS-27-2:27.2:true
PIN_ON_272="{\"devices\":{\"com.apple.CoreSimulator.SimRuntime.iOS-27-2\":[{\"name\":\"$SIMULATOR_DEVICE\",\"udid\":\"U\",\"state\":\"Shutdown\"}]}}"

# install <runtimes before> [<devices json>] -> sets out, code; calls logged in $TMP/calls.
install() {
  cp "$1" "$TMP/runtimes.json"
  printf '%s\n' "${2:-$PIN_ON_272}" >"$TMP/devices.json"
  : >"$TMP/calls"
  out="$(PATH="$TMP/bin:$PATH" SDK_VERSION="${SDK_VERSION:-27.2}" AFTER_RUNTIMES="${AFTER:-$TMP/after.json}" "$SCRIPT" 2>&1)"
  code=$?
}

# A runtime at the SDK's version is installed: exit 0 at once, no download.
install "$TMP/after.json"
[ "$code" -eq 0 ] || fail "an installed iOS 27.2 runtime should exit 0 (got $code): $out"
[ ! -s "$TMP/calls" ] || fail "should not download or create anything, got: $(cat "$TMP/calls")"
[[ "$out" == *"iOS-27-2"* ]] || fail "should name the runtime it found, got: $out"
# Versions compare numerically: 27.10 meets SDK 27.2.
runtimes "$TMP/ten.json" iOS-27-10:27.10:true
install "$TMP/ten.json"
[ "$code" -eq 0 ] && [ ! -s "$TMP/calls" ] || fail "an iOS 27.10 runtime should meet SDK 27.2, got $code: $(cat "$TMP/calls")"

# Missing (only older, device-specific or unavailable ones): download, check again, exit 0.
install "$TMP/before.json"
[ "$code" -eq 0 ] || fail "a successful download should exit 0 (got $code): $out"
[ "$(cat "$TMP/calls")" = "xcodebuild -downloadPlatform iOS" ] ||
  fail "should run xcodebuild -downloadPlatform iOS and nothing else, got: $(cat "$TMP/calls")"
[[ "$out" == *"27.2"* ]] || fail "should say which iOS version it downloads, got: $out"

# The new runtime has no SIMULATOR_DEVICE (scripts/lib/simulator.sh clones from one): create it.
install "$TMP/before.json" '{"devices":{"com.apple.CoreSimulator.SimRuntime.iOS-27-0":[{"name":"'"$SIMULATOR_DEVICE"'","udid":"OLD","state":"Shutdown"}]}}'
[ "$code" -eq 0 ] || fail "creating the device should exit 0 (got $code): $out"
[ "$(cat "$TMP/calls")" = "$(printf 'xcodebuild -downloadPlatform iOS\nsimctl create %s %s com.apple.CoreSimulator.SimRuntime.iOS-27-2' "$SIMULATOR_DEVICE" "$SIMULATOR_DEVICE")" ] ||
  fail "should create a $SIMULATOR_DEVICE on iOS 27.2, got: $(cat "$TMP/calls")"

# Still missing after the download (it fetched an older runtime): exit 1, naming the version.
AFTER="$TMP/before.json" install "$TMP/before.json"
[ "$code" -eq 1 ] || fail "still missing after the download should exit 1 (got $code)"
[[ "$out" == *"error: "*"27.2"* ]] || fail "should name the missing iOS version, got: $out"
[ "$(cat "$TMP/calls")" = "xcodebuild -downloadPlatform iOS" ] || fail "should not create a device, got: $(cat "$TMP/calls")"

# The download itself fails: exit 1.
DOWNLOAD_FAILS=1 install "$TMP/before.json"
[ "$code" -eq 1 ] || fail "a failed download should exit 1 (got $code)"

[ "$failures" -eq 0 ]
