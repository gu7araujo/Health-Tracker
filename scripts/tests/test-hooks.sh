#!/usr/bin/env bash
# Tests for .githooks/pre-commit and .githooks/pre-push, run against throwaway
# git repos. Set TEST_TMPDIR to choose where they are created.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FIXTURES="$ROOT/scripts/tests/fixtures/hooks"
WORK="$(mktemp -d "${TEST_TMPDIR:-${TMPDIR:-/tmp}}/test-hooks.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
unset GIT_DIR GIT_INDEX_FILE GIT_WORK_TREE SKIP_QUALITY QUALITY_CMD

# A repo with one commit on main (made before the hooks were enabled),
# the hooks copied in, and a bare "origin" remote.
new_repo() {
  local dir="$WORK/$1"
  git init -q -b main "$dir"
  cd "$dir" || exit 1
  git config user.name "Hook Test"
  git config user.email "hooks@example.com"
  git config commit.gpgsign false
  cp -R "$ROOT/.githooks" .githooks
  git add .githooks
  git commit -q --allow-empty -m init
  git config core.hooksPath .githooks
  git init -q --bare "$WORK/$1.git"
  git remote add origin "$WORK/$1.git"
}

# An executable script at $1 that touches $2 and exits with $3.
stub() {
  printf '#!/usr/bin/env bash\ntouch "%s"\nexit %s\n' "$2" "$3" > "$1"
  chmod +x "$1"
}

test_commit_on_main_is_refused() {
  new_repo main-commit
  echo hi > notes.txt && git add notes.txt
  local out
  if out="$(git commit -m msg 2>&1)"; then echo "commit on main succeeded"; return 1; fi
  [[ "$out" == *"branch first: git switch -c <type>/<name>"* ]] || { echo "missing message: $out"; return 1; }
}

test_commit_formats_staged_swift_and_restages_it() {
  new_repo format
  git switch -q -c feat/format
  mkdir Sources && cp "$FIXTURES/Unformatted.swift.fixture" Sources/Greeter.swift
  git add Sources/Greeter.swift
  git commit -q -m add || { echo "commit failed"; return 1; }
  diff <(git show HEAD:Sources/Greeter.swift) "$FIXTURES/Formatted.swift.fixture" || return 1
  [ -z "$(git status --porcelain)" ] || { echo "dirty tree: $(git status --porcelain)"; return 1; }
}

test_commit_with_partially_staged_swift_is_refused() {
  new_repo partial
  git switch -q -c feat/partial
  cp "$FIXTURES/Formatted.swift.fixture" Greeter.swift && git add Greeter.swift
  echo "// unstaged edit" >> Greeter.swift
  local out
  if out="$(git commit -m add 2>&1)"; then echo "commit succeeded and swallowed unstaged hunks"; return 1; fi
  [[ "$out" == *"unstaged changes"* ]] || { echo "missing message: $out"; return 1; }
  [ "$(git diff --name-only)" = "Greeter.swift" ] || { echo "unstaged edit was staged"; return 1; }
}

test_commit_with_lint_violation_is_refused() {
  new_repo lint
  git switch -q -c feat/lint
  cp "$FIXTURES/LintViolation.swift.fixture" Caster.swift && git add Caster.swift
  local out
  if out="$(git commit -m add 2>&1)"; then echo "commit succeeded"; return 1; fi
  [[ "$out" == *force_cast* ]] || { echo "violation not reported: $out"; return 1; }
}

test_commit_without_swift_files_skips_the_tools() {
  new_repo no-swift
  git switch -q -c feat/docs
  mkdir bin
  stub bin/swiftformat "$WORK/tool-ran" 1
  stub bin/swiftlint "$WORK/tool-ran" 1
  echo hi > notes.txt && git add notes.txt
  PATH="$PWD/bin:$PATH" git commit -q -m docs || { echo "commit failed"; return 1; }
  [ ! -e "$WORK/tool-ran" ] || { echo "swiftformat/swiftlint ran"; return 1; }
}

test_commit_with_staged_swift_deletion_succeeds() {
  new_repo deletion
  git switch -q -c feat/delete
  cp "$FIXTURES/Formatted.swift.fixture" Greeter.swift && git add Greeter.swift
  git commit -q -m add || { echo "first commit failed"; return 1; }
  git rm -q Greeter.swift
  git commit -q -m delete || { echo "deletion commit failed"; return 1; }
}

test_commit_runs_doctor_but_only_warns() {
  new_repo doctor
  git switch -q -c feat/doctor
  mkdir scripts && stub scripts/doctor "$WORK/doctor-ran" 1
  cp "$FIXTURES/Formatted.swift.fixture" Greeter.swift && git add Greeter.swift
  git commit -q -m add || { echo "commit failed"; return 1; }
  [ -e "$WORK/doctor-ran" ] || { echo "doctor not run"; return 1; }
}

test_commit_works_from_a_linked_worktree() {
  new_repo wt-main
  git worktree add -q -b feat/wt "$WORK/wt"
  cd "$WORK/wt" || return 1
  mkdir Sources && cp "$FIXTURES/Unformatted.swift.fixture" Sources/Greeter.swift
  git add Sources/Greeter.swift
  (cd Sources && git commit -q -m add) || { echo "commit failed"; return 1; }
  diff <(git show HEAD:Sources/Greeter.swift) "$FIXTURES/Formatted.swift.fixture" || return 1
}

test_push_to_main_is_refused() {
  new_repo push-main
  local out
  if out="$(QUALITY_CMD=true git push -q origin main 2>&1)"; then echo "push main succeeded"; return 1; fi
  [[ "$out" == *"refusing to push to main"* ]] || { echo "missing message: $out"; return 1; }
  git switch -q -c feat/sneaky
  if QUALITY_CMD=true git push -q origin feat/sneaky:main 2>/dev/null; then echo "push to main via refspec succeeded"; return 1; fi
  [ -z "$(git ls-remote origin refs/heads/main)" ] || { echo "main reached the remote"; return 1; }
}

test_push_to_feature_runs_the_quality_command() {
  new_repo push-ok
  git switch -q -c feat/ok
  stub "$WORK/quality" "$WORK/quality-ran" 0
  QUALITY_CMD="$WORK/quality" git push -q origin feat/ok || { echo "push failed"; return 1; }
  [ -e "$WORK/quality-ran" ] || { echo "quality not run"; return 1; }
  [ -n "$(git ls-remote origin refs/heads/feat/ok)" ] || { echo "branch not pushed"; return 1; }
}

test_push_is_blocked_by_a_failing_quality_command() {
  new_repo push-red
  git switch -q -c feat/red
  stub "$WORK/quality" "$WORK/quality-ran" 1
  if QUALITY_CMD="$WORK/quality" git push -q origin feat/red 2>/dev/null; then echo "push succeeded"; return 1; fi
  [ -e "$WORK/quality-ran" ] || { echo "quality not run"; return 1; }
  [ -z "$(git ls-remote origin refs/heads/feat/red)" ] || { echo "branch reached the remote"; return 1; }
}

test_push_defaults_to_scripts_quality_fast_from_repo_root() {
  new_repo push-default
  git switch -q -c feat/default
  mkdir -p scripts sub
  printf '#!/usr/bin/env bash\necho "$*" > "%s"\n' "$WORK/quality-args" > scripts/quality
  chmod +x scripts/quality
  (cd sub && git push -q origin feat/default) || { echo "push failed"; return 1; }
  [ "$(cat "$WORK/quality-args" 2>/dev/null)" = "--fast" ] || { echo "scripts/quality --fast not run"; return 1; }
}

test_skip_quality_skips_the_gate_with_a_warning() {
  new_repo push-skip
  git switch -q -c feat/skip
  stub "$WORK/quality" "$WORK/quality-ran" 1
  local out
  out="$(SKIP_QUALITY=1 QUALITY_CMD="$WORK/quality" git push -q origin feat/skip 2>&1)" || { echo "push failed: $out"; return 1; }
  [ ! -e "$WORK/quality-ran" ] || { echo "quality ran"; return 1; }
  [[ "$out" == *"SKIP_QUALITY"*"CI"* ]] || { echo "missing warning: $out"; return 1; }
}

failures=0
for test in $(declare -F | awk '{ print $3 }' | grep '^test_'); do
  rm -f "$WORK"/*-ran "$WORK/quality-args"
  if output="$("$test" 2>&1)"; then
    printf '✓ %s\n' "$test"
  else
    printf '✗ %s\n%s\n' "$test" "$output"
    failures=$((failures + 1))
  fi
done

if [ "$failures" -gt 0 ]; then
  printf '\n%d hook test(s) failed.\n' "$failures"
  exit 1
fi
printf '\nAll hook tests passed.\n'
