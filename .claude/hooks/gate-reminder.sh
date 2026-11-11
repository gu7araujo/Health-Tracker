#!/usr/bin/env bash
# Claude Code Stop hook: when a .swift file changed on this branch (committed since main, or not yet
# committed) is newer than the last gate run's build/quality.json, or that file is missing, warns
# that the definition of done (AGENTS.md Workflow) needs a fresh gate table. Non-blocking: a
# systemMessage, never a decision. Silent without xcrun: a cloud session runs the gate on CI.
set -uo pipefail
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"

command -v xcrun >/dev/null || exit 0
checkout="$(git -C "$(field .cwd)" rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$checkout" || exit 0
base="$(git merge-base HEAD main 2>/dev/null || git merge-base HEAD origin/main 2>/dev/null || echo HEAD)"
changed=()
while IFS= read -r path; do
  [ ! -f "$path" ] || changed+=("$path")
done < <({
  git diff --name-only "$base" -- '*.swift'
  git ls-files --others --exclude-standard -- '*.swift'
} 2>/dev/null)
[ "${#changed[@]}" -gt 0 ] || exit 0
[ ! -f build/quality.json ] || [ -n "$(find "${changed[@]}" -newer build/quality.json 2>/dev/null)" ] || exit 0

jq -n '{systemMessage: "Swift changed since the last gate run: run scripts/quality --json (--full for done) and paste the table."}'
