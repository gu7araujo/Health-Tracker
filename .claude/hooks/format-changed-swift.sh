#!/usr/bin/env bash
# Claude Code PostToolUse hook on Bash: runs format-swift.sh on each Swift file that git reports
# changed (against HEAD, or untracked) and whose content differs from the last call's. A file
# edited by sed, a heredoc or a script so still gets formatted and linted. The content hashes
# seen last are kept per session, agent and checkout under $TMPDIR/claude-hooks. Violations go to
# stderr with exit 2, as format-swift.sh reports them.
set -uo pipefail

hooks="$(cd "$(dirname "$0")" && pwd)"
input="$(cat)"
field() { jq -r "$1 // empty" <<<"$input"; }

checkout="$(git -C "$(field .cwd)" rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$checkout" || exit 0

files=()
while IFS= read -r -d '' file; do
  [ -f "$file" ] && files+=("$file")
done < <(
  git diff -z --name-only --diff-filter=ACMR HEAD -- '*.swift' 2>/dev/null
  git ls-files -z --others --exclude-standard -- '*.swift'
)
[ "${#files[@]}" -gt 0 ] || exit 0

agent="$(field .agent_id)"
state="${TMPDIR:-/tmp}/claude-hooks/$(field .session_id)-${agent:-main}-formatted-$(git hash-object --stdin <<<"$checkout")"
mkdir -p "$(dirname "$state")"
touch "$state"

status=0
for file in "${files[@]}"; do
  grep -qxF "$(git hash-object -- "$file") $file" "$state" && continue
  jq -n --arg path "$checkout/$file" '{tool_input: {file_path: $path}}' | "$hooks/format-swift.sh" || status=2
done

for file in "${files[@]}"; do
  printf '%s %s\n' "$(git hash-object -- "$file")" "$file"
done >"$state"
exit "$status"
