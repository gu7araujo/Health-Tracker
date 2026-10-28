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

test_commit_runs_the_pinned_tools_in_build_tools_bin_before_path() {
  new_repo pinned
  git switch -q -c feat/pinned
  mkdir -p bin build/tools/bin
  stub bin/swiftformat "$WORK/path-tool-ran" 1
  stub bin/swiftlint "$WORK/path-tool-ran" 1
  stub build/tools/bin/swiftformat "$WORK/pinned-swiftformat-ran" 0
  stub build/tools/bin/swiftlint "$WORK/pinned-swiftlint-ran" 0
  cp "$FIXTURES/Formatted.swift.fixture" Greeter.swift && git add Greeter.swift
  PATH="$PWD/bin:$PATH" git commit -q -m add || { echo "commit failed"; return 1; }
  [ ! -e "$WORK/path-tool-ran" ] || { echo "swiftformat/swiftlint from PATH ran"; return 1; }
  [ -e "$WORK/pinned-swiftformat-ran" ] || { echo "build/tools/bin/swiftformat not run"; return 1; }
  [ -e "$WORK/pinned-swiftlint-ran" ] || { echo "build/tools/bin/swiftlint not run"; return 1; }
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
  [[ "$out" == *"SKIP_QUALITY"*"CI re-runs the gate on the PR"*"draft PRs run lint only"* ]] ||
    { echo "missing warning: $out"; return 1; }
  [[ "$out" != *"until CI exists"* ]] || { echo "warning says CI does not exist: $out"; return 1; }
}

test_commit_with_staged_strings_runs_fitness_and_is_refused_on_violations() {
  new_repo fitness-red
  git switch -q -c feat/strings
  mkdir -p scripts/fitness
  printf '#!/usr/bin/env bash\ntouch "%s"\necho "localization-parity: missing key"\necho "1 violation(s)"\nexit 1\n' \
    "$WORK/fitness-ran" > scripts/fitness/run
  chmod +x scripts/fitness/run
  mkdir en.lproj && echo '"k" = "v";' > en.lproj/Localizable.strings && git add en.lproj
  local out
  if out="$(git commit -m strings 2>&1)"; then echo "commit succeeded despite fitness violations"; return 1; fi
  [ -e "$WORK/fitness-ran" ] || { echo "fitness not run"; return 1; }
  [[ "$out" == *"localization-parity: missing key"*"fitness"* ]] || { echo "violations not reported: $out"; return 1; }
}

test_commit_with_staged_swift_runs_fitness() {
  new_repo fitness-green
  git switch -q -c feat/fitness
  mkdir -p scripts/fitness && stub scripts/fitness/run "$WORK/fitness-ran" 0
  cp "$FIXTURES/Formatted.swift.fixture" Greeter.swift && git add Greeter.swift
  git commit -q -m add || { echo "commit failed"; return 1; }
  [ -e "$WORK/fitness-ran" ] || { echo "fitness not run"; return 1; }
}

test_commit_without_swift_or_strings_skips_fitness() {
  new_repo fitness-skip
  git switch -q -c feat/docs
  mkdir -p scripts/fitness && stub scripts/fitness/run "$WORK/fitness-ran" 1
  echo hi > notes.txt && git add notes.txt
  git commit -q -m docs || { echo "commit failed"; return 1; }
  [ ! -e "$WORK/fitness-ran" ] || { echo "fitness ran"; return 1; }
}

# The real scripts/fitness checks, AccessibilityID files and matching en/pt-BR Localizable.strings,
# committed on branch $2.
new_fitness_repo() {
  new_repo "$1"
  git switch -q -c "$2"
  mkdir -p scripts HealthTracker/Resources/en.lproj HealthTracker/Resources/pt-BR.lproj \
    HealthTracker/Presentation HealthTrackerUITests/Support
  cp -R "$ROOT/scripts/fitness" scripts/fitness
  : > scripts/fitness/test-mirror-exceptions.txt
  cp "$ROOT/HealthTracker/Presentation/AccessibilityID.swift" HealthTracker/Presentation/
  cp "$ROOT/HealthTrackerUITests/Support/AccessibilityID.swift" HealthTrackerUITests/Support/
  echo '"a" = "A";' > HealthTracker/Resources/en.lproj/Localizable.strings
  echo '"a" = "A";' > HealthTracker/Resources/pt-BR.lproj/Localizable.strings
  git add scripts HealthTracker HealthTrackerUITests
  git commit -q --no-verify -m fitness
}

test_commit_checks_fitness_on_the_staged_source_not_its_unstaged_test() {
  new_fitness_repo "fitness staged source" feat/source
  mkdir -p HealthTracker/Domain/UseCases HealthTrackerTests/Domain/UseCases
  cp "$FIXTURES/Formatted.swift.fixture" HealthTracker/Domain/UseCases/X.swift
  cp "$FIXTURES/Formatted.swift.fixture" HealthTrackerTests/Domain/UseCases/XTests.swift
  git add HealthTracker/Domain/UseCases/X.swift
  local out
  if out="$(git commit -m source 2>&1)"; then echo "commit succeeded without its staged test"; return 1; fi
  [[ "$out" == *"test-mirror: HealthTracker/Domain/UseCases/X.swift"*"fitness checks failed"* ]] ||
    { echo "violation not reported: $out"; return 1; }
}

test_commit_ignores_an_intent_to_add_test() {
  new_fitness_repo "fitness intent to add" feat/ita
  mkdir -p HealthTracker/Domain/UseCases HealthTrackerTests/Domain/UseCases
  cp "$FIXTURES/Formatted.swift.fixture" HealthTracker/Domain/UseCases/Zed.swift
  cp "$FIXTURES/Formatted.swift.fixture" HealthTrackerTests/Domain/UseCases/ZedTests.swift
  git add HealthTracker/Domain/UseCases/Zed.swift
  git add -N HealthTrackerTests/Domain/UseCases/ZedTests.swift
  local out
  if out="$(git commit -m source 2>&1)"; then echo "commit succeeded with only an intent-to-add test"; return 1; fi
  [[ "$out" == *"test-mirror: HealthTracker/Domain/UseCases/Zed.swift"* ]] ||
    { echo "violation not reported: $out"; return 1; }
}

test_commit_checks_fitness_on_the_staged_strings_not_unstaged_ones() {
  new_fitness_repo "fitness staged strings" feat/strings
  echo '"b" = "B";' >> HealthTracker/Resources/en.lproj/Localizable.strings
  echo '"b" = "B";' >> HealthTracker/Resources/pt-BR.lproj/Localizable.strings
  git add HealthTracker/Resources/en.lproj
  local out
  if out="$(git commit -m strings 2>&1)"; then echo "commit succeeded without its staged pt-BR key"; return 1; fi
  [[ "$out" == *"pt-BR.lproj/Localizable.strings: missing key \"b\""*"fitness checks failed"* ]] ||
    { echo "violation not reported: $out"; return 1; }
}

test_commit_passes_fitness_when_both_sides_are_staged_from_a_linked_worktree() {
  new_fitness_repo "fitness staged both" feat/both-main
  git worktree add -q -b feat/both "$WORK/fitness wt"
  cd "$WORK/fitness wt" || return 1
  mkdir -p HealthTracker/Domain/UseCases HealthTrackerTests/Domain/UseCases
  cp "$FIXTURES/Formatted.swift.fixture" HealthTracker/Domain/UseCases/X.swift
  cp "$FIXTURES/Formatted.swift.fixture" HealthTrackerTests/Domain/UseCases/XTests.swift
  echo '"b" = "B";' >> HealthTracker/Resources/en.lproj/Localizable.strings
  echo '"b" = "B";' >> HealthTracker/Resources/pt-BR.lproj/Localizable.strings
  git add HealthTracker HealthTrackerTests
  git commit -q -m both || { echo "commit failed"; return 1; }
}

test_push_runs_the_persisted_shape_guard_against_origin_main_but_never_blocks() {
  new_repo push-guard
  git switch -q -c feat/guard
  mkdir -p scripts/fitness
  printf '#!/usr/bin/env bash\necho "$*" > "%s"\necho "persisted-shape-guard: X.swift: warning: w"\nexit 1\n' \
    "$WORK/guard-args" > scripts/fitness/persisted-shape-guard.sh
  chmod +x scripts/fitness/persisted-shape-guard.sh
  stub "$WORK/quality" "$WORK/quality-ran" 0
  local out
  out="$(QUALITY_CMD="$WORK/quality" git push -q origin feat/guard 2>&1)" || { echo "push failed: $out"; return 1; }
  [ "$(cat "$WORK/guard-args" 2>/dev/null)" = "origin/main" ] || { echo "guard not run against origin/main"; return 1; }
  [[ "$out" == *"warning: w"* ]] || { echo "guard warning not shown: $out"; return 1; }
  [ -e "$WORK/quality-ran" ] || { echo "quality not run after the guard"; return 1; }
}

test_push_without_origin_main_still_succeeds_with_the_real_guard() {
  new_repo push-no-main
  git switch -q -c feat/no-main
  mkdir -p scripts/fitness && cp "$ROOT/scripts/fitness/persisted-shape-guard.sh" scripts/fitness/
  local out
  out="$(QUALITY_CMD=true git push -q origin feat/no-main 2>&1)" || { echo "push failed: $out"; return 1; }
  [[ "$out" == *"persisted-shape-guard: note: base ref 'origin/main' not found; skipping"* ]] ||
    { echo "missing note: $out"; return 1; }
}

failures=0
for test in $(declare -F | awk '{ print $3 }' | grep '^test_'); do
  rm -f "$WORK"/*-ran "$WORK/quality-args" "$WORK/guard-args"
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
