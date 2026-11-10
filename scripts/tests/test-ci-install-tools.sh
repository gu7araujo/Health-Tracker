#!/usr/bin/env bash
# scripts/ci/install-tools.sh with stubbed uname/curl/unzip/shasum on PATH (no network):
# it must fetch the pinned release asset for the OS, install the binaries (Periphery on macOS only,
# sha256-verified) and extend GITHUB_PATH.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$ROOT/scripts/ci/install-tools.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
failures=0

fail() {
  printf '  FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

# shellcheck source=../tool-versions.env
source "$ROOT/scripts/tool-versions.env"

mkdir -p "$TMP/stubs"
# uname reports $FAKE_OS / $FAKE_ARCH.
cat >"$TMP/stubs/uname" <<'EOF'
#!/bin/sh
case "$1" in -s) echo "$FAKE_OS" ;; -m) echo "$FAKE_ARCH" ;; esac
EOF
# curl logs the URL and writes the asset name as the "zip" so unzip knows what to unpack.
cat >"$TMP/stubs/curl" <<EOF
#!/bin/sh
out=""
while [ \$# -gt 1 ]; do
  [ "\$1" = "-o" ] && out="\$2"
  shift
done
echo "\$1" >>"$TMP/curl.calls"
basename "\$1" >"\$out"
EOF
# unzip unpacks each asset in its real layout: an executable that prints its pinned version.
cat >"$TMP/stubs/unzip" <<EOF
#!/bin/sh
zip=""
dir=""
while [ \$# -gt 0 ]; do
  case "\$1" in -d) dir="\$2"; shift ;; *.zip) zip="\$1" ;; esac
  shift
done
mkdir -p "\$dir"
fake() { printf '#!/bin/sh\necho %s\n' "\$2" >"\$dir/\$1"; chmod +x "\$dir/\$1"; }
case "\$(cat "\$zip")" in
  portable_swiftlint.zip) fake swiftlint "\${LINT_VERSION:-$SWIFTLINT_VERSION}"; echo license >"\$dir/LICENSE" ;;
  # The real Linux zip holds a dynamically linked swiftlint (needs libxml2/libcurl) and swiftlint-static.
  swiftlint_linux_amd64.zip) fake swiftlint dynamic; fake swiftlint-static "\${LINT_VERSION:-$SWIFTLINT_VERSION}" ;;
  swiftformat.zip) fake swiftformat "$SWIFTFORMAT_VERSION" ;;
  swiftformat_linux.zip) fake swiftformat_linux "$SWIFTFORMAT_VERSION" ;;
  # The real zip holds periphery, the libIndexStore.dylib it loads from beside itself, and LICENSE.md.
  periphery-$PERIPHERY_VERSION.zip) fake periphery "$PERIPHERY_VERSION"; echo dylib >"\$dir/libIndexStore.dylib"; echo license >"\$dir/LICENSE.md" ;;
  *) exit 9 ;;
esac
EOF
# shasum prints the asset's pinned sha256, or 0000 for the asset named in \$BAD_SHA.
cat >"$TMP/stubs/shasum" <<EOF
#!/bin/sh
for last in "\$@"; do :; done
asset="\$(cat "\$last")"
case "\$asset" in
  "\${BAD_SHA:-}") sha=0000 ;;
  portable_swiftlint.zip) sha="${SWIFTLINT_SHA256_MACOS:-}" ;;
  swiftlint_linux_amd64.zip) sha="${SWIFTLINT_SHA256_LINUX:-}" ;;
  swiftformat.zip) sha="${SWIFTFORMAT_SHA256_MACOS:-}" ;;
  swiftformat_linux.zip) sha="${SWIFTFORMAT_SHA256_LINUX:-}" ;;
  v$XCODE_BUILD_SERVER_VERSION.tar.gz) sha="$XCODE_BUILD_SERVER_SHA256" ;;
  *) sha="$PERIPHERY_SHA256" ;;
esac
echo "\$sha  \$last"
EOF
# tar unpacks the xcode-build-server source archive: the launcher and the module holding its version.
cat >"$TMP/stubs/tar" <<EOF
#!/bin/sh
dir=""
while [ \$# -gt 0 ]; do
  [ "\$1" = "-C" ] && dir="\$2"
  shift
done
printf '#!/bin/sh\necho launcher\n' >"\$dir/xcode-build-server"
chmod +x "\$dir/xcode-build-server"
printf 'import os\n\nVERSION = "%s"\n' "\${XBS_VERSION:-$XCODE_BUILD_SERVER_VERSION}" >"\$dir/misc.py"
EOF
chmod +x "$TMP/stubs/"*

# install <os> <arch> [env...] -> sets out, code
install() {
  rm -rf "${TMP:?}/bin" "${TMP:?}/libexec" "$TMP/curl.calls"
  : >"$TMP/github_path"
  out="$(env -u CI FAKE_OS="$1" FAKE_ARCH="$2" GITHUB_PATH="$TMP/github_path" PATH="$TMP/stubs:$PATH" \
    "${@:3}" "$SCRIPT" "$TMP/bin" 2>&1)"
  code=$?
}

release="https://github.com"
install Darwin arm64
[ "$code" -eq 0 ] || fail "macOS install should succeed (got $code): $out"
grep -qx "$release/realm/SwiftLint/releases/download/$SWIFTLINT_VERSION/portable_swiftlint.zip" "$TMP/curl.calls" ||
  fail "macOS should fetch portable_swiftlint.zip, got: $(cat "$TMP/curl.calls")"
grep -qx "$release/nicklockwood/SwiftFormat/releases/download/$SWIFTFORMAT_VERSION/swiftformat.zip" "$TMP/curl.calls" ||
  fail "macOS should fetch swiftformat.zip, got: $(cat "$TMP/curl.calls")"
[ "$("$TMP/bin/swiftlint")" = "$SWIFTLINT_VERSION" ] || fail "swiftlint should be installed in the bin dir"
[ "$("$TMP/bin/swiftformat")" = "$SWIFTFORMAT_VERSION" ] || fail "swiftformat should be installed in the bin dir"
[ "$(cat "$TMP/github_path")" = "$TMP/bin" ] || fail "the bin dir should be appended to GITHUB_PATH, got: $(cat "$TMP/github_path")"
[[ "$out" == *"SwiftLint $SWIFTLINT_VERSION"* && "$out" == *"SwiftFormat $SWIFTFORMAT_VERSION"* ]] ||
  fail "should print the installed versions, got: $out"
grep -qx "$release/peripheryapp/periphery/releases/download/$PERIPHERY_VERSION/periphery-$PERIPHERY_VERSION.zip" "$TMP/curl.calls" ||
  fail "macOS should fetch periphery-$PERIPHERY_VERSION.zip, got: $(cat "$TMP/curl.calls")"
[ "$("$TMP/bin/periphery")" = "$PERIPHERY_VERSION" ] || fail "periphery should be installed in the bin dir"
[ -f "$TMP/bin/libIndexStore.dylib" ] || fail "libIndexStore.dylib should be installed beside periphery"
[[ "$out" == *"Periphery $PERIPHERY_VERSION"* ]] || fail "should print the installed Periphery version, got: $out"

# xcode-build-server (macOS, local only): the pinned source archive, unpacked beside the bin dir
# with its launcher linked into it (the launcher imports the modules next to its real path).
xbs_url="$release/SolaWing/xcode-build-server/archive/refs/tags/v$XCODE_BUILD_SERVER_VERSION.tar.gz"
grep -qx "$xbs_url" "$TMP/curl.calls" || fail "macOS should fetch $xbs_url, got: $(cat "$TMP/curl.calls")"
[ -L "$TMP/bin/xcode-build-server" ] && [ "$("$TMP/bin/xcode-build-server")" = launcher ] ||
  fail "xcode-build-server should be linked into the bin dir"
[ -f "$TMP/libexec/xcode-build-server/misc.py" ] || fail "the xcode-build-server sources should sit in libexec beside the bin dir"
[[ "$out" == *"xcode-build-server $XCODE_BUILD_SERVER_VERSION"* ]] || fail "should print the installed xcode-build-server version, got: $out"

install Darwin arm64 XBS_VERSION=0.1.0
[ "$code" -ne 0 ] || fail "an xcode-build-server that is not the pinned version should fail the install"

# A symlinked bin dir (one install shared across worktrees): the link still reaches the sources.
mkdir -p "$TMP/shared/tools/bin" && ln -s "$TMP/shared/tools/bin" "$TMP/linked-bin"
out="$(env -u CI -u GITHUB_PATH FAKE_OS=Darwin FAKE_ARCH=arm64 PATH="$TMP/stubs:$PATH" "$SCRIPT" "$TMP/linked-bin" 2>&1)" ||
  fail "install into a symlinked bin dir should succeed: $out"
[ "$("$TMP/linked-bin/xcode-build-server" 2>&1)" = launcher ] ||
  fail "xcode-build-server should run through a symlinked bin dir"

# A relative bin dir is not looked up in CDPATH (scripts/bootstrap passes build/tools/bin).
mkdir -p "$TMP/elsewhere/rel/bin" "$TMP/cwd"
out="$(cd "$TMP/cwd" && env -u CI -u GITHUB_PATH CDPATH="$TMP/elsewhere" FAKE_OS=Darwin FAKE_ARCH=arm64 PATH="$TMP/stubs:$PATH" "$SCRIPT" rel/bin 2>&1)" ||
  fail "install into a relative bin dir should ignore CDPATH: $out"
[ -f "$TMP/cwd/rel/libexec/xcode-build-server/misc.py" ] || fail "a relative bin dir should resolve against the current directory, not CDPATH"

# CI runs no LSP, so it skips the download.
install Darwin arm64 CI=true
[ "$code" -eq 0 ] || fail "macOS CI install should succeed (got $code): $out"
! grep -q xcode-build-server "$TMP/curl.calls" || fail "CI should not fetch xcode-build-server"
[ ! -e "$TMP/bin/xcode-build-server" ] || fail "CI should not install xcode-build-server"

# A zip whose sha256 is not the pinned one is never installed.
# bad_sha <os> <arch> <asset> <tool>
bad_sha() {
  install "$1" "$2" BAD_SHA="$3"
  [ "$code" -ne 0 ] || fail "$1: a $3 with the wrong sha256 should fail the install"
  [ ! -e "$TMP/bin/$4" ] || fail "$1: a $3 with the wrong sha256 should not be installed"
  [[ "$out" == *"$3 sha256"* ]] || fail "$1: a $3 sha256 mismatch should say so, got: $out"
}
bad_sha Darwin arm64 "periphery-$PERIPHERY_VERSION.zip" periphery
bad_sha Darwin arm64 "v$XCODE_BUILD_SERVER_VERSION.tar.gz" xcode-build-server
bad_sha Darwin arm64 portable_swiftlint.zip swiftlint
bad_sha Darwin arm64 swiftformat.zip swiftformat
bad_sha Linux x86_64 swiftlint_linux_amd64.zip swiftlint
bad_sha Linux x86_64 swiftformat_linux.zip swiftformat

install Linux x86_64
[ "$code" -eq 0 ] || fail "Linux install should succeed (got $code): $out"
grep -q '/swiftlint_linux_amd64.zip$' "$TMP/curl.calls" && grep -q '/swiftformat_linux.zip$' "$TMP/curl.calls" ||
  fail "Linux should fetch the linux assets, got: $(cat "$TMP/curl.calls")"
[ "$("$TMP/bin/swiftformat")" = "$SWIFTFORMAT_VERSION" ] || fail "swiftformat_linux should be installed as swiftformat"
[ "$("$TMP/bin/swiftlint")" = "$SWIFTLINT_VERSION" ] || fail "swiftlint-static should be installed as swiftlint on Linux"
! grep -q periphery "$TMP/curl.calls" || fail "Linux has no Periphery release; it should not fetch one"
! grep -q xcode-build-server "$TMP/curl.calls" || fail "xcode-build-server is macOS only; Linux should not fetch it"

install Linux x86_64 LINT_VERSION=0.1.0
[ "$code" -ne 0 ] || fail "a binary that is not the pinned version should fail the install"

install Plan9 mips
[ "$code" -ne 0 ] || fail "an unsupported OS should fail"

# Without GITHUB_PATH (local runs) nothing is written, and the default dir is under RUNNER_TEMP.
rm -rf "${TMP:?}/bin"
out="$(env -u GITHUB_PATH -u CI FAKE_OS=Darwin FAKE_ARCH=arm64 RUNNER_TEMP="$TMP/runner" PATH="$TMP/stubs:$PATH" "$SCRIPT" 2>&1)" ||
  fail "default bin dir install should succeed: $out"
[ -x "$TMP/runner/ci-tools/bin/swiftlint" ] || fail "default bin dir should be \$RUNNER_TEMP/ci-tools/bin"

[ "$failures" -eq 0 ]
