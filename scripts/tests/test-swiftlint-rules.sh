#!/usr/bin/env bash
# Tests the path-scoped architecture rules (custom_rules in .swiftlint.yml):
# for each rule, a file in its folder that must fail and one that must pass.
# Fixtures are written into a temp tree that mirrors the real folders and copies
# the real configs, since a .swift fixture in the repo would be linted itself.
# Custom rules need SourceKit, so this runs on macOS (as scripts/tests/run does in CI).
# shellcheck disable=SC2329 # test_* functions are called via declare -F
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORK="$(mktemp -d "${TEST_TMPDIR:-${TMPDIR:-/tmp}}/test-swiftlint-rules.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

# A tree with the real configs and baseline; cd's into it.
new_tree() {
  local dir="$WORK/$1"
  mkdir -p "$dir/HealthTracker/Domain/Entities" "$dir/HealthTracker/Presentation/ViewModels" \
    "$dir/HealthTrackerTests" "$dir/HealthTrackerUITests"
  cd "$dir" || exit 1
  cp "$ROOT/.swiftlint.yml" "$ROOT/.swiftlint-baseline.json" . || exit 1
  cp "$ROOT/HealthTrackerTests/.swiftlint.yml" HealthTrackerTests/ || exit 1
  cp "$ROOT/HealthTrackerUITests/.swiftlint.yml" HealthTrackerUITests/ || exit 1
}

# write <path> <lines...>
write() {
  local path="$1"
  shift
  mkdir -p "$(dirname "$path")"
  printf '%s\n' "$@" >"$path"
}

# Lints the whole tree, then the one file per file (as the hooks do).
lint() { swiftlint lint --strict --quiet -- "$@" 2>&1; }

expect_clean() {
  local out
  if ! out="$(lint)" || [ -n "$out" ]; then echo "expected no violations, got: $out"; return 1; fi
  if ! out="$(lint "$1")" || [ -n "$out" ]; then echo "expected $1 to pass, got: $out"; return 1; fi
}

# expect_violation <rule> <file>
expect_violation() {
  local rule="$1" file="$2" out
  for args in "" "$file"; do
    # shellcheck disable=SC2086 # empty args lints the whole tree
    if out="$(lint $args)"; then echo "expected $rule in $file to fail --strict, it passed: $out"; return 1; fi
    [[ "$out" == *"$file"*"($rule)"* ]] || { echo "expected $rule in $file, got: $out"; return 1; }
  done
}

test_domain_ui_import_fails() {
  new_tree domain-fails
  write HealthTracker/Domain/Entities/New.swift 'import SwiftUI' 'struct New {}'
  expect_violation domain_no_ui_frameworks HealthTracker/Domain/Entities/New.swift || return 1
  write HealthTracker/Domain/Entities/New.swift 'import UserNotifications' 'struct New {}'
  expect_violation domain_no_ui_frameworks HealthTracker/Domain/Entities/New.swift
}

test_domain_allowlisted_and_foundation_pass() {
  new_tree domain-passes
  cp "$ROOT/HealthTracker/Domain/Entities/DayStatus.swift" "$ROOT/HealthTracker/Domain/Entities/Mood.swift" \
    HealthTracker/Domain/Entities/ || return 1
  write HealthTracker/Domain/Entities/New.swift 'import Foundation' '// No SwiftUI here.' 'struct New {}'
  expect_clean HealthTracker/Domain/Entities/DayStatus.swift || return 1
  expect_clean HealthTracker/Domain/Entities/Mood.swift || return 1
  expect_clean HealthTracker/Domain/Entities/New.swift
}

test_ui_import_outside_domain_passes() {
  new_tree presentation-swiftui
  write HealthTracker/Presentation/View.swift 'import SwiftUI' 'struct Screen {}'
  expect_clean HealthTracker/Presentation/View.swift
}

test_presentation_data_layer_fails() {
  local file=HealthTracker/Presentation/ViewModels/VM.swift
  new_tree presentation-fails
  for type in HealthDataRepository ICloudDriveDataSource UserDefaultsDataSource NotificationService; do
    write "$file" "let dependency = $type()"
    expect_violation presentation_no_data_layer "$file" || return 1
  done
}

test_presentation_protocols_and_disabled_init_pass() {
  local file=HealthTracker/Presentation/ViewModels/VM.swift
  new_tree presentation-passes
  write "$file" \
    'func make(repository: HealthDataRepositoryProtocol, service: NotificationServiceProtocol) {}' \
    '// Never call HealthDataRepository() from a view.' \
    '// swiftlint:disable:next presentation_no_data_layer' \
    'let composed = HealthDataRepository()'
  expect_clean "$file" || return 1
  # The real MainViewModel, with its composition-root convenience init.
  cp "$ROOT/HealthTracker/Presentation/ViewModels/MainViewModel.swift" HealthTracker/Presentation/ViewModels/ || return 1
  expect_clean HealthTracker/Presentation/ViewModels/MainViewModel.swift
}

test_data_layer_outside_presentation_passes() {
  new_tree data-construct
  write HealthTracker/Data/Factory.swift 'let repository = HealthDataRepository()'
  expect_clean HealthTracker/Data/Factory.swift
}

test_hardcoded_locale_fails() {
  new_tree locale-fails
  write HealthTracker/Presentation/Format.swift 'let locale = Locale(identifier: "pt_BR")'
  expect_violation no_hardcoded_locale HealthTracker/Presentation/Format.swift || return 1
  write HealthTracker/Domain/Clock.swift 'let zone = TimeZone(identifier: "UTC")'
  expect_violation no_hardcoded_locale HealthTracker/Domain/Clock.swift
}

test_device_locale_passes() {
  new_tree locale-passes
  write HealthTracker/Presentation/Format.swift 'let locale = Locale.current' 'let zone = TimeZone.current' \
    '// never Locale(identifier: "pt_BR")'
  expect_clean HealthTracker/Presentation/Format.swift
}

test_unit_tests_xctest_fails() {
  new_tree xctest-fails
  write HealthTrackerTests/OldTests.swift 'import XCTest' 'final class OldTests: XCTestCase {}'
  expect_violation unit_tests_use_swift_testing HealthTrackerTests/OldTests.swift
}

test_unit_tests_swift_testing_passes() {
  new_tree xctest-passes
  write HealthTrackerTests/NewTests.swift 'import Testing' '@testable import HealthTracker' \
    '// Not import XCTest.' 'struct NewTests {}'
  expect_clean HealthTrackerTests/NewTests.swift || return 1
  write HealthTrackerUITests/FlowTests.swift 'import XCTest' 'final class FlowTests: XCTestCase {}'
  expect_clean HealthTrackerUITests/FlowTests.swift
}

test_ui_tests_testable_import_fails() {
  new_tree testable-fails
  write HealthTrackerUITests/FlowTests.swift '@testable import HealthTracker' 'import XCTest'
  expect_violation ui_tests_no_testable_import HealthTrackerUITests/FlowTests.swift
}

test_ui_tests_black_box_passes() {
  new_tree testable-passes
  write HealthTrackerUITests/FlowTests.swift 'import XCTest' '// No @testable import here.'
  expect_clean HealthTrackerUITests/FlowTests.swift
}

test_ui_tests_sleep_fails() {
  local file=HealthTrackerUITests/FlowTests.swift call
  new_tree sleep-fails
  for call in 'sleep(1)' 'usleep(1000)' 'Thread.sleep(forTimeInterval: 1)'; do
    write "$file" 'import Foundation' "func wait() { $call }"
    expect_violation ui_tests_no_sleep "$file" || return 1
  done
}

test_ui_tests_sleep_in_comment_passes() {
  new_tree sleep-passes
  write HealthTrackerUITests/FlowTests.swift 'import Foundation' '// Wait on assertExists, never sleep(1).' \
    'let note = "no usleep( here"'
  expect_clean HealthTrackerUITests/FlowTests.swift || return 1
  write HealthTrackerTests/HelperTests.swift 'import Foundation' 'func pause() { usleep(10) }'
  expect_clean HealthTrackerTests/HelperTests.swift
}

test_no_print_still_fails() {
  new_tree print
  write HealthTracker/Debug.swift 'func debug() { print("x") }'
  expect_violation no_print HealthTracker/Debug.swift
}

test_rules_name_their_agents_rule() {
  local rule
  for rule in domain_no_ui_frameworks presentation_no_data_layer no_hardcoded_locale \
    unit_tests_use_swift_testing ui_tests_no_testable_import ui_tests_no_sleep; do
    grep -A8 "^  $rule:" "$ROOT/.swiftlint.yml" | grep -q 'AGENTS.md' ||
      { echo "$rule's message must name the AGENTS.md rule it enforces"; return 1; }
  done
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
