#!/usr/bin/env bash
# scripts/fitness/run: runs every fitness check, prints all violations and a total, exits 1 if any.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$ROOT/scripts/fitness/run"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
failures=0

fail() {
  printf '  FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

# put <repo> <path> <content>
put() {
  mkdir -p "$(dirname "$1/$2")"
  printf '%s\n' "$3" >"$1/$2"
}

# A minimal tree that satisfies every check.
clean_tree() {
  put "$1" HealthTracker/Resources/en.lproj/Localizable.strings '"title" = "Title";'
  put "$1" HealthTracker/Resources/pt-BR.lproj/Localizable.strings '"title" = "Título";'
  put "$1" HealthTracker/Domain/Entities/Meal.swift 'struct Meal {}'
  put "$1" HealthTrackerTests/Domain/Entities/MealTests.swift 'struct MealTests {}'
  put "$1" HealthTracker/Presentation/AccessibilityID.swift 'static let a = "a"'
  put "$1" HealthTrackerUITests/Support/AccessibilityID.swift 'static let a = "a"'
}

# Must pass: a clean tree.
clean_tree "$TMP/pass"
out="$("$SCRIPT" "$TMP/pass")"
code=$?
[ "$code" -eq 0 ] || fail "a clean tree should exit 0 (got $code): $out"
[ "$(tail -n 1 <<<"$out")" = "0 violation(s)" ] || fail "a clean tree should end with '0 violation(s)', got: $out"

# Must fail: one violation from each check, all reported, then the total.
clean_tree "$TMP/fail"
put "$TMP/fail" HealthTracker/Resources/en.lproj/Localizable.strings '"title" = "Title";
"extra" = "Extra";'
put "$TMP/fail" HealthTracker/Domain/UseCases/Save.swift 'struct Save {}'
put "$TMP/fail" HealthTrackerUITests/Support/AccessibilityID.swift 'static let b = "b"'
out="$("$SCRIPT" "$TMP/fail")"
code=$?
[ "$code" -eq 1 ] || fail "a tree with violations should exit 1 (got $code)"
grep -q '^localization-parity: ' <<<"$out" || fail "should run localization-parity: $out"
grep -q '^test-mirror: ' <<<"$out" || fail "should run test-mirror: $out"
grep -q '^accessibility-ids: ' <<<"$out" || fail "should run accessibility-ids: $out"
[ "$(tail -n 1 <<<"$out")" = "3 violation(s)" ] || fail "should end with '3 violation(s)', got: $out"

# The real repository is clean.
out="$("$SCRIPT")"
code=$?
[ "$code" -eq 0 ] || fail "this repository should pass every fitness check (got $code):"$'\n'"$out"

[ "$failures" -eq 0 ]
