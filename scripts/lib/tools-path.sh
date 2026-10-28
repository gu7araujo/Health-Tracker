#!/usr/bin/env bash
# Puts the pinned tools (scripts/bootstrap installs them into build/tools/bin) first on PATH.
# Source, don't run.
#
# Usage: source scripts/lib/tools-path.sh; prepend_tools_path <repo-root>
#   Prepends <repo-root>/build/tools/bin as an absolute path. Leaves PATH alone when that dir is
#   missing or can't be entered (never an empty entry, which would mean the current directory).
#   Always returns 0, so it is safe under set -e.

prepend_tools_path() {
  local bin
  bin="$(CDPATH='' cd -- "$1/build/tools/bin" 2>/dev/null && pwd)" || return 0
  PATH="$bin:$PATH"
}
