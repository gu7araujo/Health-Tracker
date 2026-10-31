#!/usr/bin/env bash
# Fitness test for .github/workflows: every Summary step runs under if: always() and calls
# scripts/ci/summary.sh unconditionally, so a run that stops before build/quality.json is
# written still gets summary.sh's "no report" summary instead of a blank one. Also: lint job
# wiring, the test job's PR filter, NUL-safe xargs, weekly/ci test-step parity, the weekly
# failure issue, the simulator runtime step, step and job timeouts, action pinning.
# Usage: test-ci-workflows.sh [workflows dir]  (default: .github/workflows, which also runs the
# checks on scripts/tests/fixtures/ci-workflows to prove they still catch what they are for).
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORKFLOWS="${1:-$ROOT/.github/workflows}"
# shellcheck disable=SC2016 # the literal workflow line; $GITHUB_STEP_SUMMARY must not expand
EXPECTED='run: scripts/ci/summary.sh build/quality.json >>"$GITHUB_STEP_SUMMARY"'
failures=0

fail() {
  printf '  FAIL: %s\n' "$1"
  failures=$((failures + 1))
}
# strip_root: drops the literal "$ROOT/" prefix from each line, so a checkout path holding sed or
# glob metacharacters still prints repo-relative paths.
strip_root() { while IFS= read -r line; do printf '%s\n' "${line#"$ROOT/"}"; done; }

for workflow in "$WORKFLOWS"/*.yml; do
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
# (persist-credentials: false leaves no token for a later `git fetch`).
CI="$WORKFLOWS/ci.yml"
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
done < <(grep -HnE '^[^#]*uses: ' "$WORKFLOWS"/*.yml |
  grep -vE 'uses: [^@ ]+@[0-9a-f]{40} # v[0-9][^ ]* *$' | strip_root)

# File lists piped to xargs are NUL-separated, so a filename with spaces stays one argument.
while IFS= read -r line; do
  fail "pipe a NUL-separated list (grep -Z ... | xargs -0): $line"
done < <(grep -HnE '\| *xargs' "$WORKFLOWS"/*.yml |
  grep -vE 'grep -[A-Za-z]*Z[A-Za-z]* .*\| *xargs -0 ' | strip_root)
# Every xargs takes -0, also when the pipe is split across lines. Quoted strings, comments and
# step names are not commands.
while IFS= read -r line; do
  fail "xargs needs -0 for a NUL-separated list: $line"
done < <(awk '{
  code = $0
  gsub(/"[^"]*"|'\''[^'\'']*'\''/, "", code)
  sub(/(^|[ \t])#.*/, "", code)
  if (code ~ /^ *(- )?name:/) next
  gsub(/xargs -0( |$)/, "", code)
  if (code ~ /(^|[^[:alnum:]_-])xargs([^[:alnum:]_-]|$)/) print FILENAME ":" FNR ":" $0
}' "$WORKFLOWS"/*.yml | strip_root)

# Draft PRs run the macOS test job too, so marking a PR ready needs no run of its own: no
# ready_for_review trigger (it would cancel the draft's run and re-run it). Dependabot PRs skip test.
test_job="$(awk '/^  test:/ { found = 1; next } found && /^  [a-z]/ { exit } found { print }' "$CI")"
test_if="$(awk '/^    if:/ { found = 1; print; next } found && /^      / { print; next } found { exit }' <<<"$test_job")"
grep -q 'draft' <<<"$test_job" && fail "ci.yml test job: draft PRs run test too; drop the draft condition"
grep -qF "github.actor != 'dependabot[bot]'" <<<"$test_if" || fail "ci.yml test job: Dependabot PRs must skip test"
grep -qE '^[^#]*ready_for_review' "$CI" && fail "ci.yml: no ready_for_review trigger; the draft's run already checked the commit"

# test_steps <workflow>: the test job's steps, with the quality mode spelled --full (ci.yml's
# --full-only condition dropped) and without weekly.yml's red-run notification.
test_steps() {
  awk '/^  test:/ { job = 1; next } job && /^  [a-z]/ { exit } job && /^    steps:/ { steps = 1; next } steps { print }' "$1" |
    awk '/^ *- name: Notify on failure *$/ { skip = 1; next } skip && /^      - / { skip = 0 } !skip' |
    sed -E -e 's|scripts/quality "\$MODE"|scripts/quality --full|' -e "/^ *if: env.MODE == '--full'( +#.*)? *\$/d"
}
# The weekly run copies ci.yml's test job steps (see weekly.yml); they must not drift apart.
WEEKLY="$WORKFLOWS/weekly.yml"
drift="$(diff <(test_steps "$CI") <(test_steps "$WEEKLY"))" ||
  fail "weekly.yml's test steps drifted from ci.yml's (< ci.yml, > weekly.yml):"$'\n'"$drift"
[ -n "$(test_steps "$CI")" ] || fail "ci.yml: no test job steps found"

# A red scheduled run opens (or comments on) an issue, so it does not go unnoticed.
notify="$(awk '/^ *- name: Notify on failure *$/ { found = 1; next } found && /^ *- / { exit } found { print }' "$WEEKLY")"
grep -qE "^ *if: failure\(\) && github.event_name == 'schedule' *\$" <<<"$notify" ||
  fail "weekly.yml: needs a 'Notify on failure' step with if: failure() && github.event_name == 'schedule'"
grep -q 'gh issue create' <<<"$notify" || fail "weekly.yml: 'Notify on failure' should open an issue"
grep -qE '^ *issues: write *$' "$WEEKLY" || fail "weekly.yml: opening an issue needs 'issues: write'"
# A hung simulator must fail the Quality gate step, not time out the test job (ci.yml and
# weekly.yml): a job timeout is a cancel, so the if: failure() upload and notification steps
# would be skipped.
for workflow in "$CI" "$WEEKLY"; do
  job="$(awk '/^  test:/ { found = 1; next } found && /^  [a-z]/ { exit } found { print }' "$workflow")"
  gate="$(awk '/^ *- name: Quality gate *$/ { found = 1; next } found && /^ *- / { exit } found { print }' <<<"$job")"
  gate_timeout="$(sed -nE 's/^ *timeout-minutes: ([0-9]+) *$/\1/p' <<<"$gate")"
  job_timeout="$(sed -nE 's/^    timeout-minutes: ([0-9]+) *$/\1/p' <<<"$job")"
  [ -n "$gate_timeout" ] && [ -n "$job_timeout" ] && [ "$gate_timeout" -lt "$job_timeout" ] ||
    fail "$(basename "$workflow"): the Quality gate step needs a timeout-minutes below the test job's ($job_timeout)"
  # --full runs HealthTrackerIntentsUITests, which needs a simulator runtime at the SDK's version
  # that the runner image can lack: a Simulator runtime step installs it right before the gate. Its
  # timeout plus the gate's stays below the job's, so either step can time out and the if: failure()
  # steps still run.
  runtime="$(awk '/^ *- name: Simulator runtime *$/ { found = 1; next } found && /^ *- / { exit } found { print }' <<<"$job")"
  before_gate="$(awk '/^ *- name: Quality gate *$/ { print prev; exit } /^      - / { prev = $0 }' <<<"$job")"
  [[ "$before_gate" =~ ^\ *-\ name:\ Simulator\ runtime\ *$ ]] &&
    grep -qE '^ *run: scripts/ci/install-simulator-runtime.sh *$' <<<"$runtime" ||
    fail "$(basename "$workflow"): the test job needs a 'Simulator runtime' step running scripts/ci/install-simulator-runtime.sh right before Quality gate"
  [ -n "$runtime" ] || continue
  runtime_timeout="$(sed -nE 's/^ *timeout-minutes: ([0-9]+) *$/\1/p' <<<"$runtime")"
  [ -n "$runtime_timeout" ] && [ -n "$gate_timeout" ] && [ -n "$job_timeout" ] &&
    [ $((runtime_timeout + gate_timeout)) -lt "$job_timeout" ] ||
    fail "$(basename "$workflow"): the Simulator runtime and Quality gate step timeouts (${runtime_timeout:-none} + ${gate_timeout:-none}) must sum below the test job's ($job_timeout)"
done
# Pushes to main run --fast, which has no intents run: they skip the download.
runtime="$(awk '/^ *- name: Simulator runtime *$/ { found = 1; next } found && /^ *- / { exit } found { print }' "$CI")"
grep -qE "^ *if: env.MODE == '--full'( +#.*)? *\$" <<<"$runtime" ||
  fail "ci.yml: the Simulator runtime step must run only when MODE is --full (if: env.MODE == '--full')"

# The AI review costs per run: draft PRs skip it. Fork PRs get no secrets, so they skip it too.
grep -qxF "    if: github.event.pull_request.draft != true && github.event.pull_request.head.repo.full_name == github.repository" \
  "$WORKFLOWS/claude-code-review.yml" ||
  fail "claude-code-review.yml: the job must skip draft and fork PRs"

# The public repo's @claude job spends the owner's token: it answers only the owner.
grep -qxF "      github.actor == 'gu7araujo' && (" "$WORKFLOWS/claude.yml" ||
  fail "claude.yml: the job must run only when github.actor is the owner"

# The real workflows pass every check, which a check gone blind would too: the fixtures prove each
# check still catches what it is for, and pass/ that together they accept a clean set. Only on the
# default run, so the fixture runs do not recurse.
if [ $# -eq 0 ]; then
  FIXTURES="$ROOT/scripts/tests/fixtures/ci-workflows"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  # fixture <dir> <n>: runs the checks on pass/ with that dir's files copied over it, so only the
  # checks the dir breaks fail, and asserts exactly n FAIL lines, each counted in the exit status;
  # must asserts on its output.
  fixture() {
    dir="$1"
    mkdir "$tmp/$dir"
    cp "$FIXTURES"/pass/*.yml "$FIXTURES/$dir"/*.yml "$tmp/$dir/"
    out="$("$0" "$tmp/$dir" 2>&1)"
    status=$?
    printed="$(grep -c '^  FAIL: ' <<<"$out")"
    counted="$(sed -nE 's/^([0-9]+) check\(s\) failed$/\1/p' <<<"$out")"
    [ "$printed" -eq "$2" ] && [ "${counted:-0}" -eq "$2" ] && { [ "$2" -ne 0 ] || [ "$status" -eq 0 ]; } ||
      fail "fixture $dir: expected $2 FAIL line(s), all counted; got exit $status:"$'\n'"$out"
  }
  must() { grep -qF -- "$1" <<<"$out" || fail "fixture $dir: expected '$1', got:"$'\n'"$out"; }
  fixture pass 0
  fixture xargs 4
  XARGS="FAIL: xargs needs -0 for a NUL-separated list: $tmp/xargs"
  must "$XARGS/split-line.yml:8:"
  must "$XARGS/quoted-hash.yml:6:"
  must "$XARGS/second-xargs.yml:6:"
  must "FAIL: pipe a NUL-separated list (grep -Z ... | xargs -0): $tmp/xargs/producer.yml:6:"
  fixture timeouts 4
  must "ci.yml: the Quality gate step needs a timeout-minutes below the test job's (45)"
  must "weekly.yml: the Quality gate step needs a timeout-minutes below the test job's (30)"
  must "ci.yml: the Simulator runtime and Quality gate step timeouts (20 + 45) must sum below the test job's (45)"
  must "weekly.yml: the Simulator runtime and Quality gate step timeouts (20 + 45) must sum below the test job's (30)"
  fixture runtime 3
  must "ci.yml: the Simulator runtime step must run only when MODE is --full"
  must "ci.yml: the Simulator runtime and Quality gate step timeouts (30 + 45) must sum below the test job's (75)"
  must "weekly.yml: the Simulator runtime and Quality gate step timeouts (30 + 45) must sum below the test job's (75)"
  fixture runtime-order 2
  must "weekly.yml: the test job needs a 'Simulator runtime' step running scripts/ci/install-simulator-runtime.sh right before Quality gate"
  must "weekly.yml's test steps drifted from ci.yml's"
  fixture draft 2
  must "ci.yml test job: draft PRs run test too; drop the draft condition"
  must "ci.yml: no ready_for_review trigger"
  fixture dependabot 1
  must "ci.yml test job: Dependabot PRs must skip test"
  fixture drift 1
  must "weekly.yml's test steps drifted from ci.yml's"
  fixture pinning 3
  PINNING="FAIL: action not pinned by SHA with a '# v...' comment: $tmp/pinning/unpinned.yml"
  must "$PINNING:6:"
  must "$PINNING:7:"
  must "$PINNING:8:"
  fixture summary 3
  must "FAIL: not-always.yml: Summary step is not if: always()"
  must "FAIL: conditional.yml: Summary step does not call summary.sh unconditionally"
  must "FAIL: outside.yml calls summary.sh outside a Summary step"
  fixture lint 4
  must "FAIL: ci.yml lint job: checkout needs fetch-depth: 2"
  must "FAIL: ci.yml lint job: no 'run: scripts/fitness/run' step"
  must "FAIL: ci.yml lint job: 'Persisted shape' step must run on pull_request only"
  must "FAIL: ci.yml lint job: 'Persisted shape' step must run the guard against HEAD^1"
  fixture notify 3
  must "FAIL: weekly.yml: needs a 'Notify on failure' step with if: failure()"
  must "FAIL: weekly.yml: 'Notify on failure' should open an issue"
  must "FAIL: weekly.yml: opening an issue needs 'issues: write'"
  fixture claude 2
  must "FAIL: claude-code-review.yml: the job must"
  must "FAIL: claude.yml: the job must"
  # A checkout path with sed or glob metacharacters (| [ * \) still prints repo-relative paths, from
  # each check that prints file paths.
  odd="$tmp/a|b[*\\c"
  rel="scripts/tests/fixtures/ci-workflows/odd"
  mkdir -p "$odd/$rel"
  cp "$0" "$odd/scripts/tests/"
  cp "$FIXTURES/pinning/unpinned.yml" "$FIXTURES/xargs/producer.yml" "$FIXTURES/xargs/split-line.yml" "$odd/$rel/"
  dir="odd (checkout at $odd)"
  out="$("$odd/scripts/tests/test-ci-workflows.sh" "$odd/$rel" 2>&1)"
  must "comment: $rel/unpinned.yml:6:"
  must "xargs -0): $rel/producer.yml:6:"
  must "NUL-separated list: $rel/split-line.yml:8:"
fi

[ "$failures" -eq 0 ] || { printf '%s check(s) failed\n' "$failures"; exit 1; }
