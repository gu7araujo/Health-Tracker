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
# shasum prints the pinned sha256 for any file, or \$FAKE_SHA.
cat >"$TMP/stubs/shasum" <<EOF
#!/bin/sh
for last in "\$@"; do :; done
echo "\${FAKE_SHA:-$PERIPHERY_SHA256}  \$last"
EOF
chmod +x "$TMP/stubs/"*

# install <os> <arch> [env...] -> sets out, code
install() {
  rm -rf "${TMP:?}/bin" "$TMP/curl.calls"
  : >"$TMP/github_path"
  out="$(env FAKE_OS="$1" FAKE_ARCH="$2" GITHUB_PATH="$TMP/github_path" PATH="$TMP/stubs:$PATH" \
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

# A zip whose sha256 is not the pinned one is never installed.
install Darwin arm64 FAKE_SHA=0000
[ "$code" -ne 0 ] || fail "a periphery zip with the wrong sha256 should fail the install"
[ ! -e "$TMP/bin/periphery" ] || fail "a periphery zip with the wrong sha256 should not be installed"
[[ "$out" == *"sha256"* ]] || fail "a sha256 mismatch should say so, got: $out"

install Linux x86_64
[ "$code" -eq 0 ] || fail "Linux install should succeed (got $code): $out"
grep -q '/swiftlint_linux_amd64.zip$' "$TMP/curl.calls" && grep -q '/swiftformat_linux.zip$' "$TMP/curl.calls" ||
  fail "Linux should fetch the linux assets, got: $(cat "$TMP/curl.calls")"
[ "$("$TMP/bin/swiftformat")" = "$SWIFTFORMAT_VERSION" ] || fail "swiftformat_linux should be installed as swiftformat"
[ "$("$TMP/bin/swiftlint")" = "$SWIFTLINT_VERSION" ] || fail "swiftlint-static should be installed as swiftlint on Linux"
! grep -q periphery "$TMP/curl.calls" || fail "Linux has no Periphery release; it should not fetch one"

install Linux x86_64 LINT_VERSION=0.1.0
[ "$code" -ne 0 ] || fail "a binary that is not the pinned version should fail the install"

install Plan9 mips
[ "$code" -ne 0 ] || fail "an unsupported OS should fail"

# Without GITHUB_PATH (local runs) nothing is written, and the default dir is under RUNNER_TEMP.
rm -rf "${TMP:?}/bin"
out="$(env -u GITHUB_PATH FAKE_OS=Darwin FAKE_ARCH=arm64 RUNNER_TEMP="$TMP/runner" PATH="$TMP/stubs:$PATH" "$SCRIPT" 2>&1)" ||
  fail "default bin dir install should succeed: $out"
[ -x "$TMP/runner/ci-tools/bin/swiftlint" ] || fail "default bin dir should be \$RUNNER_TEMP/ci-tools/bin"

[ "$failures" -eq 0 ]
