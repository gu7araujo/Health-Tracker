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

[ "$failures" -eq 0 ]
