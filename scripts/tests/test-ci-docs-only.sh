#!/usr/bin/env bash
# scripts/ci/docs-only.sh exits 0 only when every file in a NUL-separated list is docs or agent
# config, and its patterns are ci.yml's push paths-ignore, the one definition of "docs-only".
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$ROOT/scripts/ci/docs-only.sh"
failures=0

fail() {
  printf '  FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

# expect <status> <file>...: the script, fed those files NUL-separated, exits <status>.
expect() {
  want="$1"
  shift
  if [ $# -eq 0 ]; then "$SCRIPT" </dev/null; else printf '%s\0' "$@" | "$SCRIPT"; fi
  got=$?
  [ "$got" -eq "$want" ] || fail "expected exit $want, got $got for: $*"
}

expect 0 README.md
expect 0 scripts/AGENTS.md "HealthTracker/Domain/AGENTS.md"
expect 0 "docs/a b.md" .agents/skills/tdd/SKILL.md .claude/skills/x/run.sh .codex/config.toml
expect 1 HealthTracker/App.swift
expect 1 README.md "HealthTracker/My View.swift"
expect 1 "a b.md.swift"
expect 1 .claude/settings.json
expect 1 .claude/hooks/format-swift.sh
expect 1 .github/workflows/ci.yml
expect 1 notes.mdx
# An empty list is a failed or empty diff: CI runs rather than skipping on nothing.
expect 1
# A last entry without its trailing NUL still counts.
printf 'README.md\0HealthTracker/App.swift' | "$SCRIPT" && fail "an unterminated last entry must still be checked"

# The patterns are push's paths-ignore, so the docs that point at paths-ignore stay right.
ignore="$(awk '/^  push:/ { found = 1; next } found && /^  [a-z]/ { exit } found { print }' "$ROOT/.github/workflows/ci.yml" |
  sed -nE 's/^    paths-ignore: \[(.*)\] *$/\1/p' | tr -d ',')"
patterns="$(sed -nE 's/^PATTERNS=\((.*)\) *$/\1/p' "$SCRIPT")"
[ -n "$ignore" ] && [ "$ignore" = "$patterns" ] ||
  fail "docs-only.sh PATTERNS ($patterns) must equal ci.yml push paths-ignore ($ignore)"

# docs-only.sh matches with bash [[ ]], where * crosses / (GitHub's does not): only the two shapes
# whose meaning both agree on, **/*.<ext> and <dir>/** (a plain path), are allowed.
for pattern in $patterns; do
  [[ "$pattern" =~ ^\'(\*\*/\*\.[A-Za-z0-9]+|[A-Za-z0-9._/-]+/\*\*)\'$ ]] ||
    fail "docs-only.sh pattern $pattern: use **/*.<ext> or <dir>/** (bash and GitHub globs differ elsewhere)"
done

[ "$failures" -eq 0 ]
