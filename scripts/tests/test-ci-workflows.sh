#!/usr/bin/env bash
# Fitness test for .github/workflows: every Summary step runs under if: always() and calls
# scripts/ci/summary.sh unconditionally, so a run that stops before build/quality.json is
# written still gets summary.sh's "no report" summary instead of a blank one. Also: lint job
# wiring, NUL-safe xargs, weekly/ci test-step parity, the weekly failure issue, action pinning.
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

# File lists piped to xargs are NUL-separated, so a filename with spaces stays one argument.
while IFS= read -r line; do
  fail "pipe a NUL-separated list (grep -Z ... | xargs -0): $line"
done < <(grep -HnE '\| *xargs' "$ROOT"/.github/workflows/*.yml |
  grep -vE 'grep -[A-Za-z]*Z[A-Za-z]* .*\| *xargs -0 ' | sed "s|^$ROOT/||")

# test_steps <workflow>: the test job's steps, with the quality mode spelled --full and without
# weekly.yml's red-run notification.
test_steps() {
  awk '/^  test:/ { job = 1; next } job && /^  [a-z]/ { exit } job && /^    steps:/ { steps = 1; next } steps { print }' "$1" |
    awk '/^ *- name: Notify on failure *$/ { skip = 1; next } skip && /^      - / { skip = 0 } !skip' |
    sed 's|scripts/quality "\$MODE"|scripts/quality --full|'
}
# The weekly run copies ci.yml's test job steps (see weekly.yml); they must not drift apart.
WEEKLY="$ROOT/.github/workflows/weekly.yml"
drift="$(diff <(test_steps "$CI") <(test_steps "$WEEKLY"))" ||
  fail "weekly.yml's test steps drifted from ci.yml's (< ci.yml, > weekly.yml):"$'\n'"$drift"
[ -n "$(test_steps "$CI")" ] || fail "ci.yml: no test job steps found"

# A red scheduled run opens (or comments on) an issue, so it does not go unnoticed.
notify="$(awk '/^ *- name: Notify on failure *$/ { found = 1; next } found && /^ *- / { exit } found { print }' "$WEEKLY")"
grep -qE "^ *if: failure\(\) && github.event_name == 'schedule' *\$" <<<"$notify" ||
  fail "weekly.yml: needs a 'Notify on failure' step with if: failure() && github.event_name == 'schedule'"
grep -q 'gh issue create' <<<"$notify" || fail "weekly.yml: 'Notify on failure' should open an issue"
grep -qE '^ *issues: write *$' "$WEEKLY" || fail "weekly.yml: opening an issue needs 'issues: write'"
# A hung simulator must fail the Quality gate step, not time out the job: a job timeout is a
# cancel, so the if: failure() upload and notification steps would be skipped.
gate="$(awk '/^ *- name: Quality gate *$/ { found = 1; next } found && /^ *- / { exit } found { print }' "$WEEKLY")"
gate_timeout="$(sed -nE 's/^ *timeout-minutes: ([0-9]+) *$/\1/p' <<<"$gate")"
job_timeout="$(sed -nE 's/^    timeout-minutes: ([0-9]+) *$/\1/p' "$WEEKLY")"
[ -n "$gate_timeout" ] && [ "$gate_timeout" -lt "$job_timeout" ] ||
  fail "weekly.yml: the Quality gate step needs a timeout-minutes below the job's ($job_timeout)"

# The AI review costs per run: draft PRs skip it. Fork PRs get no secrets, so they skip it too.
grep -qxF "    if: github.event.pull_request.draft != true && github.event.pull_request.head.repo.full_name == github.repository" \
  "$ROOT/.github/workflows/claude-code-review.yml" ||
  fail "claude-code-review.yml: the job must skip draft and fork PRs"

# The public repo's @claude job spends the owner's token: it answers only the owner.
grep -qxF "      github.actor == 'gu7araujo' && (" "$ROOT/.github/workflows/claude.yml" ||
  fail "claude.yml: the job must run only when github.actor is the owner"

[ "$failures" -eq 0 ]
