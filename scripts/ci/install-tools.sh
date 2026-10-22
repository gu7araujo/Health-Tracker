#!/usr/bin/env bash
# Installs the SwiftLint and SwiftFormat release binaries pinned in scripts/tool-versions.env.
#
# Usage: scripts/ci/install-tools.sh [<bin-dir>]
#   <bin-dir> defaults to ${RUNNER_TEMP:-$TMPDIR}/ci-tools/bin. When GITHUB_PATH is set, <bin-dir>
#   is appended to it so later steps find the tools. Supports macOS and Linux x86_64.
set -euo pipefail

# shellcheck source=../tool-versions.env
source "$(dirname "$0")/../tool-versions.env"

BIN="${1:-${RUNNER_TEMP:-${TMPDIR:-/tmp}}/ci-tools/bin}"

case "$(uname -s)-$(uname -m)" in
  Darwin-*)
    lint_asset="portable_swiftlint.zip" lint_bin="swiftlint"
    format_asset="swiftformat.zip" format_bin="swiftformat"
    ;;
  # The Linux SwiftLint zip also holds a dynamically linked `swiftlint`; the static one has no system deps.
  Linux-x86_64)
    lint_asset="swiftlint_linux_amd64.zip" lint_bin="swiftlint-static"
    format_asset="swiftformat_linux.zip" format_bin="swiftformat_linux"
    ;;
  *)
    echo "error: no pinned release asset for $(uname -s) $(uname -m)" >&2
    exit 1
    ;;
esac

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$BIN"

# install <tool> <owner/repo> <version> <asset> <binary>: unzips the asset and installs <binary> as <tool>.
install_tool() {
  curl -fsSL --retry 3 -o "$work/$1.zip" "https://github.com/$2/releases/download/$3/$4"
  unzip -q -o "$work/$1.zip" -d "$work/$1"
  [ -f "$work/$1/$5" ] || {
    echo "error: no $5 in $4" >&2
    exit 1
  }
  cp "$work/$1/$5" "$BIN/$1"
  chmod +x "$BIN/$1"
}

install_tool swiftlint realm/SwiftLint "$SWIFTLINT_VERSION" "$lint_asset" "$lint_bin"
install_tool swiftformat nicklockwood/SwiftFormat "$SWIFTFORMAT_VERSION" "$format_asset" "$format_bin"

# check <label> <installed> <pinned>
check() {
  echo "$1 $2"
  [ "$2" = "$3" ] || {
    echo "error: $1 $2 installed, pinned $3" >&2
    exit 1
  }
}
check SwiftLint "$("$BIN/swiftlint" version)" "$SWIFTLINT_VERSION"
check SwiftFormat "$("$BIN/swiftformat" --version)" "$SWIFTFORMAT_VERSION"

if [ -n "${GITHUB_PATH:-}" ]; then
  echo "$BIN" >>"$GITHUB_PATH"
fi
