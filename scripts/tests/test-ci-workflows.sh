#!/usr/bin/env bash
# Fitness test for .github/workflows: every Summary step runs under if: always() and calls
# scripts/ci/summary.sh unconditionally, so a run that stops before build/quality.json is
# written still gets summary.sh's "no report" summary instead of a blank one.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck disable=SC2016 # the literal workflow line; $GITHUB_STEP_SUMMARY must not expand
EXPECTED='run: scripts/ci/summary.sh build/quality.json >>"$GITHUB_STEP_SUMMARY"'
failures=0

fail() {
  printf '  FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

for workflow in "$ROOT"/.github/workflows/*.yml; do
  name="$(basename "$workflow")"
  # The Summary step's lines, from "- name: Summary" up to the next step.
  step="$(awk '
    /^ *- name: Summary *$/ { found = 1; print; next }
    found && /^ *- / { exit }
    found { print }
  ' "$workflow")"
  if [ -z "$step" ]; then
    grep -q 'summary.sh' "$workflow" && fail "$name calls summary.sh outside a Summary step"
    continue
  fi
  grep -qE '^ *if: always\(\) *$' <<<"$step" || fail "$name: Summary step is not if: always()"
  sed 's/^ *//; s/ *$//' <<<"$step" | grep -qxF -- "$EXPECTED" ||
    fail "$name: Summary step does not call summary.sh unconditionally:"$'\n'"$step"
done

# The Linux lint job runs the fitness checks, and on PRs the warn-only persisted-shape guard
# against the merge commit's first parent (the PR base): checkout fetch-depth 2 brings that parent
# (persist-credentials: false leaves no token for a later `git fetch` in this private repo).
CI="$ROOT/.github/workflows/ci.yml"
lint="$(awk '/^  lint:/ { found = 1; next } found && /^  [a-z]/ { exit } found { print }' "$CI")"
grep -qE '^ *fetch-depth: 2 *$' <<<"$lint" || fail "ci.yml lint job: checkout needs fetch-depth: 2 for the merge commit's parent"
grep -qE '^ *run: scripts/fitness/run *$' <<<"$lint" || fail "ci.yml lint job: no 'run: scripts/fitness/run' step"
guard="$(awk '/^ *- name: Persisted shape *$/ { found = 1; next } found && /^ *- / { exit } found { print }' <<<"$lint")"
grep -qE "^ *if: github.event_name == 'pull_request' *\$" <<<"$guard" ||
  fail "ci.yml lint job: 'Persisted shape' step must run on pull_request only"
grep -qE '^ *run: scripts/fitness/persisted-shape-guard.sh HEAD\^1 *$' <<<"$guard" ||
  fail "ci.yml lint job: 'Persisted shape' step must run the guard against HEAD^1 (the PR base)"

# Every action is pinned by full commit SHA, with its version in a comment (Dependabot bumps both).
while IFS= read -r line; do
  fail "action not pinned by SHA with a '# v...' comment: $line"
done < <(grep -HnE '^[^#]*uses: ' "$ROOT"/.github/workflows/*.yml |
  grep -vE 'uses: [^@ ]+@[0-9a-f]{40} # v[0-9][^ ]* *$' | sed "s|^$ROOT/||")

# The AI review costs per run: draft PRs skip it.
grep -qxE "    if: github.event.pull_request.draft != true *" "$ROOT/.github/workflows/claude-code-review.yml" ||
  fail "claude-code-review.yml: the job needs 'if: github.event.pull_request.draft != true'"

[ "$failures" -eq 0 ]
