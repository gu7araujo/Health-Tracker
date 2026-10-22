#!/usr/bin/env bash
# Selects the Xcode pinned in scripts/tool-versions.env and prints its path.
# Looks for $XCODE_APPS_DIR/Xcode_<version>*.app (default /Applications) whose xcodebuild reports
# exactly "Xcode <version>"; runners name an app after its release stage (e.g. _Release_Candidate).
set -uo pipefail

# shellcheck source=../tool-versions.env
source "$(dirname "$0")/../tool-versions.env"

APPS="${XCODE_APPS_DIR:-/Applications}"

for app in "$APPS/Xcode_$XCODE_VERSION"*.app; do
  version="$("$app/Contents/Developer/usr/bin/xcodebuild" -version 2>/dev/null | head -n 1)"
  if [ "$version" = "Xcode $XCODE_VERSION" ]; then
    sudo xcode-select -s "$app" || exit 1
    echo "$app"
    exit 0
  fi
done

echo "error: no Xcode $XCODE_VERSION in $APPS (scripts/tool-versions.env). Found:" >&2
ls -d "$APPS"/Xcode*.app >&2 2>/dev/null || echo "  (none)" >&2
exit 1
