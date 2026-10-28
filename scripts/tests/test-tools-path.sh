#!/usr/bin/env bash
# Tests scripts/lib/tools-path.sh: prepend_tools_path <root> puts <root>/build/tools/bin first on
# PATH, leaves PATH alone when that dir is missing or can't be entered, and every script that
# looks up the pinned tools uses it.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'chmod -R u+rwx "$TMP"; rm -rf "$TMP"' EXIT
failures=0

fail() {
  printf '  FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

# path_after <root> [shell options]: PATH after sourcing the helper and calling it on <root> from
# $TMP, in a shell with the given options (the callers run under set -uo pipefail or set -euo pipefail).
path_after() {
  (cd "$TMP" && PATH="/usr/bin:/bin" bash -c "set $2"'; source "$1"; prepend_tools_path "$2"; printf "%s" "$PATH"' \
    _ "$ROOT/scripts/lib/tools-path.sh" "$1")
}

# Present: the absolute build/tools/bin comes first, even from a relative root.
mkdir -p "$TMP/repo/build/tools/bin"
[ "$(path_after "$TMP/repo" "-uo pipefail")" = "$TMP/repo/build/tools/bin:/usr/bin:/bin" ] ||
  fail "build/tools/bin should come first on PATH, got: $(path_after "$TMP/repo" "-uo pipefail")"
[ "$(path_after repo "-euo pipefail")" = "$TMP/repo/build/tools/bin:/usr/bin:/bin" ] ||
  fail "a relative root should resolve to an absolute entry, got: $(path_after repo "-euo pipefail")"

# An exported CDPATH makes cd print the dir it enters; that must not end up in PATH.
[ "$(CDPATH=. path_after repo "-euo pipefail")" = "$TMP/repo/build/tools/bin:/usr/bin:/bin" ] ||
  fail "CDPATH should not change the entry, got: $(CDPATH=. path_after repo "-euo pipefail")"

# Missing: plain PATH.
[ "$(path_after "$TMP/none" "-euo pipefail")" = "/usr/bin:/bin" ] ||
  fail "without build/tools/bin PATH should stay the same, got: $(path_after "$TMP/none" "-euo pipefail")"

# Present but can't be entered: plain PATH, no empty entry (an empty entry means the current
# directory) and no failure under set -e. Root enters any dir, so skip it there.
if [ "$(id -u)" -ne 0 ]; then
  mkdir -p "$TMP/locked/build/tools/bin"
  chmod 000 "$TMP/locked/build/tools/bin"
  out="$(path_after "$TMP/locked" "-euo pipefail")"
  code=$?
  [ "$code" -eq 0 ] || fail "an unenterable build/tools/bin should not fail under set -e (got $code)"
  [ "$out" = "/usr/bin:/bin" ] || fail "an unenterable build/tools/bin should leave PATH alone, got: $out"
fi

# Every script that looks up the pinned tools uses the helper, not its own copy of the lookup.
for caller in scripts/quality scripts/doctor .githooks/pre-commit .claude/hooks/format-swift.sh scripts/tests/run; do
  src="$(grep -v '^[[:space:]]*#' "$ROOT/$caller")"
  grep -q '^[[:space:]]*prepend_tools_path ' <<<"$src" || fail "$caller should call prepend_tools_path"
  if grep -q 'PATH=' <<<"$src"; then
    fail "$caller should not set PATH itself"
  fi
done

[ "$failures" -eq 0 ]
