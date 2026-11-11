#!/usr/bin/env bash
# Claude Code SessionStart hook: a checkout without the pinned tools (a fresh clone or worktree)
# fails the format hook and the pre-push gate, so tell the agent to bootstrap it. SessionStart
# stdout becomes session context.
set -uo pipefail

cwd="$(jq -r '.cwd // empty')"
checkout="$(git -C "${cwd:-.}" rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ ! -e "$checkout/build/tools/bin/swiftlint" ] || exit 0
echo "This checkout has no build/tools/bin/swiftlint: run scripts/bootstrap before editing or pushing."
