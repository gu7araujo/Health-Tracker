#!/usr/bin/env bash
# Tests for scripts/bootstrap, run against throwaway git repos.
# Set TEST_TMPDIR to choose where they are created.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORK="$(mktemp -d "${TEST_TMPDIR:-${TMPDIR:-/tmp}}/test-bootstrap.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
unset GIT_DIR GIT_INDEX_FILE GIT_WORK_TREE

new_repo() {
  git init -q -b main "$WORK/$1"
  cd "$WORK/$1" || exit 1
  mkdir scripts && cp "$ROOT/scripts/bootstrap" scripts/bootstrap
}

test_bootstrap_sets_relative_hooks_path() {
  new_repo hooks-path
  scripts/bootstrap > /dev/null || { echo "bootstrap failed"; return 1; }
  [ "$(git config --get-all core.hooksPath)" = ".githooks" ] || { echo "core.hooksPath is '$(git config --get-all core.hooksPath)'"; return 1; }
}

test_bootstrap_is_idempotent() {
  new_repo idempotent
  scripts/bootstrap > /dev/null && scripts/bootstrap > /dev/null || { echo "bootstrap failed"; return 1; }
  [ "$(git config --get-all core.hooksPath)" = ".githooks" ] || { echo "core.hooksPath is '$(git config --get-all core.hooksPath)'"; return 1; }
}

test_bootstrap_reports_a_replaced_hooks_path() {
  new_repo replaced
  git config core.hooksPath scripts/githooks
  local out
  out="$(scripts/bootstrap)" || { echo "bootstrap failed"; return 1; }
  [[ "$out" == *"replaced core.hooksPath=scripts/githooks"* ]] || { echo "old value not reported: $out"; return 1; }
}

test_bootstrap_runs_doctor_when_present() {
  new_repo doctor
  printf '#!/usr/bin/env bash\ntouch "%s"\n' "$WORK/doctor-ran" > scripts/doctor && chmod +x scripts/doctor
  scripts/bootstrap > /dev/null || { echo "bootstrap failed"; return 1; }
  [ -e "$WORK/doctor-ran" ] || { echo "doctor not run"; return 1; }
}

test_bootstrap_installs_tools_into_build_tools_bin() {
  new_repo install-tools
  mkdir scripts/ci
  printf '#!/usr/bin/env bash\necho "$1" > "%s"\n' "$WORK/install-tools-arg" > scripts/ci/install-tools.sh && chmod +x scripts/ci/install-tools.sh
  scripts/bootstrap > /dev/null || { echo "bootstrap failed"; return 1; }
  [ "$(cat "$WORK/install-tools-arg" 2>/dev/null)" = "build/tools/bin" ] || { echo "install-tools.sh not run with build/tools/bin"; return 1; }
}

test_bootstrap_prints_next_steps() {
  new_repo next-steps
  local out
  out="$(scripts/bootstrap)" || { echo "bootstrap failed"; return 1; }
  [[ "$out" == *"scripts/quality"* ]] || { echo "no next steps: $out"; return 1; }
}

failures=0
for test in $(declare -F | awk '{ print $3 }' | grep '^test_'); do
  if output="$("$test" 2>&1)"; then
    printf '✓ %s\n' "$test"
  else
    printf '✗ %s\n%s\n' "$test" "$output"
    failures=$((failures + 1))
  fi
done

if [ "$failures" -gt 0 ]; then
  printf '\n%d bootstrap test(s) failed.\n' "$failures"
  exit 1
fi
printf '\nAll bootstrap tests passed.\n'
