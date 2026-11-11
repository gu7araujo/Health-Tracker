#!/usr/bin/env bash
# Claude Code hook on Bash, wired to PreToolUse, PostToolUse and PostToolUseFailure. Before the
# call it snapshots the content hash of each Swift file git reports changed (against HEAD, or
# untracked) in the session's checkout; after it, format-swift.sh runs on each such file whose hash
# is new. A file edited by sed, a heredoc or a script so still gets formatted and linted, while
# files changed before the call (the user's own work, an Edit the Edit hook already checked) are
# left alone. The snapshot is keyed by tool_use_id; a call without one is skipped. Violations go to
# stderr with exit 2, as format-swift.sh reports them.
set -uo pipefail
hooks="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
source "$hooks/lib.sh"

checkout="$(git -C "$(field .cwd)" rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$checkout" || exit 0
snapshot="$(state_path "bash-$(field .tool_use_id)")"

# "<hash> <path>" per changed Swift file.
changed_swift() {
  local files=() file
  while IFS= read -r -d '' file; do
    [ -f "$file" ] && files+=("$file")
  done < <(
    git diff -z --name-only --diff-filter=ACMR HEAD -- '*.swift' 2>/dev/null
    git ls-files -z --others --exclude-standard -- '*.swift'
  )
  [ "${#files[@]}" -gt 0 ] || return 0
  paste -d ' ' <(git hash-object -- "${files[@]}") <(printf '%s\n' "${files[@]}")
}

if [ "$(field .hook_event_name)" = PreToolUse ]; then
  mkdir -p "$(dirname "$snapshot")"
  changed_swift >"$snapshot"
  exit 0
fi

[ -f "$snapshot" ] || exit 0
status=0
while read -r hash file; do
  grep -qxF "$hash $file" "$snapshot" && continue
  jq -n --arg path "$checkout/$file" '{tool_input: {file_path: $path}}' | "$hooks/format-swift.sh" || status=2
done < <(changed_swift)
rm -f "$snapshot"
exit "$status"
