#!/usr/bin/env bash
# Tests the SwiftLint metrics: new violations fail --strict, test targets may
# force-unwrap, and the committed baseline freezes the existing violations by
# file + rule + line text, so they survive line shifts and a moved checkout.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORK="$(mktemp -d "${TEST_TMPDIR:-${TMPDIR:-/tmp}}/test-swiftlint-metrics.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
BASELINED="HealthTracker/Domain/Entities/Workout.swift"

# A tree with the real configs and baseline, plus one real baselined file.
new_tree() {
  local dir="$WORK/$1"
  mkdir -p "$dir/HealthTracker/Domain/Entities" "$dir/HealthTrackerTests" "$dir/HealthTrackerUITests"
  cd "$dir" || exit 1
  cp "$ROOT/.swiftlint.yml" "$ROOT/.swiftlint-baseline.json" . || exit 1
  cp "$ROOT/HealthTrackerTests/.swiftlint.yml" HealthTrackerTests/ || exit 1
  cp "$ROOT/HealthTrackerUITests/.swiftlint.yml" HealthTrackerUITests/ || exit 1
  cp "$ROOT/$BASELINED" "$BASELINED"
}

# Lints the whole tree, or the files given, the way every call site does.
lint() { swiftlint lint --strict --quiet -- "$@" 2>&1; }

expect_clean() {
  local out
  if ! out="$(lint "$@")" || [ -n "$out" ]; then echo "expected no violations, got: $out"; return 1; fi
}

# expect_violation <rule> [files...]
expect_violation() {
  local rule="$1" out
  shift
  if out="$(lint "$@")"; then echo "expected $rule to fail --strict, it passed: $out"; return 1; fi
  [[ "$out" == *"($rule)"* ]] || { echo "expected $rule, got: $out"; return 1; }
}

unwraps() { printf 'let forced = Int("1")!\nvar implicit: String!\n' >"$1"; }

test_long_closure_fails() {
  new_tree closure
  { echo 'let work = {'; echo '    var total = 0'
    for _ in $(seq 31); do echo '    total += 1'; done
    echo '    return total'; echo '}'; } >HealthTracker/Long.swift
  expect_violation closure_body_length
}

test_production_unwraps_fail() {
  new_tree production
  unwraps HealthTracker/Unwrap.swift
  expect_violation force_unwrapping || return 1
  expect_violation implicitly_unwrapped_optional HealthTracker/Unwrap.swift
}

test_test_target_unwraps_pass() {
  new_tree tests
  unwraps HealthTrackerTests/Unwrap.swift
  unwraps HealthTrackerUITests/Unwrap.swift
  expect_clean || return 1
  expect_clean HealthTrackerTests/Unwrap.swift HealthTrackerUITests/Unwrap.swift || return 1
  expect_clean "$(pwd -P)/HealthTrackerTests/Unwrap.swift"
}

test_baselined_violation_passes() {
  new_tree baselined
  expect_clean || return 1
  expect_clean "$BASELINED" || return 1
  # The Claude hook passes an absolute path. SwiftLint matches it against the
  # baseline only without symlinks in it (macOS /var -> /private/var), hence -P.
  expect_clean "$(pwd -P)/$BASELINED"
}

test_shifted_baselined_violation_passes() {
  new_tree shifted
  { echo '// An edit above the baselined violation.'; cat "$ROOT/$BASELINED"; } >"$BASELINED"
  expect_clean || return 1
  expect_clean "$BASELINED"
}

test_new_violation_in_baselined_file_fails() {
  new_tree new-in-baselined
  echo 'let forced = Int("1")!' >>"$BASELINED"
  expect_violation force_unwrapping || return 1
  expect_violation force_unwrapping "$BASELINED"
}

test_baseline_paths_are_repo_relative() {
  local absolute
  absolute="$(jq -r '.[].violation.location.file | select(startswith("/") or startswith("file:") or startswith("./"))' \
    "$ROOT/.swiftlint-baseline.json")" || { echo "baseline is not valid JSON"; return 1; }
  [ -z "$absolute" ] || { echo "baseline paths must be repo-relative (CI checks out elsewhere): $absolute"; return 1; }
}

failed=0
for test in $(declare -F | awk '{print $3}' | grep '^test_'); do
  if out="$("$test" 2>&1)"; then
    printf '  ok   %s\n' "$test"
  else
    printf '  FAIL %s\n%s\n' "$test" "$out"
    failed=1
  fi
done
exit "$failed"
