#!/usr/bin/env bash
# Claude Code Stop hook: when a .swift file changed on this branch (committed since main, or not yet
# committed) is newer than the last gate run's build/quality.json, or that file is missing, warns
# that the definition of done (AGENTS.md Workflow) needs a fresh gate table. Blocks the stop once,
# so Claude reads the reason and runs the gate or says why not; a stop that already follows a Stop
# hook's block (stop_hook_active) goes through, so it never loops. Silent without xcrun: a cloud
# session runs the gate on CI.
set -uo pipefail
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"

[ "$(field .stop_hook_active)" != "true" ] || exit 0
command -v xcrun >/dev/null || exit 0
checkout="$(git -C "$(field .cwd)" rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$checkout" || exit 0
base="$(git merge-base HEAD main 2>/dev/null || git merge-base HEAD origin/main 2>/dev/null || echo HEAD)"
changed=()
# NUL-separated, so git never quotes a name; ./ keeps a leading - from reading as a find option.
while IFS= read -r -d '' path; do
  [ ! -f "$path" ] || changed+=("./$path")
done < <({
  git diff -z --name-only "$base" -- '*.swift'
  git ls-files -z --others --exclude-standard -- '*.swift'
} 2>/dev/null)
[ "${#changed[@]}" -gt 0 ] || exit 0
[ ! -f build/quality.json ] || [ -n "$(find "${changed[@]}" -newer build/quality.json 2>/dev/null)" ] || exit 0

jq -n '{decision: "block", reason: "Swift changed since the last scripts/quality run (build/quality.json): run scripts/quality (--full for done) and paste its table, or tell the user why not (AGENTS.md: Definition of done)."}'
