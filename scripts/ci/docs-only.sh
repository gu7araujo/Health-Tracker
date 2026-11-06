#!/usr/bin/env bash
# Exits 0 when every changed file in a NUL-separated list on stdin is docs or agent config, so
# ci.yml's changes job can skip lint and test; 1 otherwise, or on an empty list (a failed or empty
# diff runs CI rather than skipping it). PATTERNS are ci.yml's push paths-ignore, in its syntax
# (scripts/tests/test-ci-docs-only.sh keeps them equal).
# Usage: git diff --no-renames --name-only -z HEAD^1 HEAD | docs-only.sh  (--no-renames lists a
# rename's old path too, so code moved to a .md still counts)
set -uo pipefail

PATTERNS=('**/*.md' '.agents/**' '.claude/skills/**' '.codex/**')

# is_doc <file>: a leading **/ also matches the repo root; in [[ ]], * already crosses /.
is_doc() {
  for pattern in "${PATTERNS[@]}"; do
    # shellcheck disable=SC2053 # unquoted: $pattern is a glob
    [[ "$1" == ${pattern#\*\*/} ]] && return 0
  done
  return 1
}

seen=0
while IFS= read -r -d '' file || [ -n "$file" ]; do # also an unterminated last entry
  seen=1
  is_doc "$file" || exit 1
done
[ "$seen" -eq 1 ]
