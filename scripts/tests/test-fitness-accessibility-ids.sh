#!/usr/bin/env bash
# scripts/fitness/accessibility-ids.sh: every identifier the UI-test mirror declares exists in the app.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$ROOT/scripts/fitness/accessibility-ids.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
failures=0

fail() {
  printf '  FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

# expect <output> <line>: the output must contain <line> as a whole line.
expect() {
  grep -qxF -- "$2" <<<"$1" || fail "missing line '$2' in:"$'\n'"$1"
}

# ids <repo> <app content> <ui-test content>
ids() {
  mkdir -p "$1/HealthTracker/Presentation" "$1/HealthTrackerUITests/Support"
  printf '%s\n' "$2" >"$1/HealthTracker/Presentation/AccessibilityID.swift"
  printf '%s\n' "$3" >"$1/HealthTrackerUITests/Support/AccessibilityID.swift"
}

APP='//  Keep in sync with "the mirror".
enum AccessibilityID {
    static let addRecordButton = "addRecordButton"
    static let modalList = "addEditModalList"
    static let appOnly = "appOnly"

    static func calendarDay(offset: Int) -> String {
        "calendarDay_\(offset)"
    }

    static func moodButton(_ mood: Mood) -> String {
        "moodButton_\(mood.rawValue.lowercased())"
    }
}'

# Must pass: exact lets, func templates by prefix, lets that expand an app template; app-only IDs are fine.
ids "$TMP/pass" "$APP" 'enum AccessibilityID {
    static let addRecordButton = "addRecordButton"
    static let modalList = "addEditModalList"
    static let moodButtonGood = "moodButton_good"

    static func calendarDay(offset: Int) -> String {
        "calendarDay_\(offset)"
    }
}'
out="$("$SCRIPT" "$TMP/pass")"
code=$?
[ "$code" -eq 0 ] || fail "a consistent mirror should exit 0 (got $code): $out"
[ -z "$out" ] || fail "a consistent mirror should print nothing, got: $out"

# Must fail: a renamed let value, a let with no app counterpart, and a template the app lacks.
ids "$TMP/fail" "$APP" 'enum AccessibilityID {
    static let addRecordButton = "addButton"
    static let modalList = "addEditModalList"
    static let ghost = "ghost"

    static func mealCard(_ index: Int) -> String {
        "mealCard_\(index)"
    }
}'
out="$("$SCRIPT" "$TMP/fail")"
code=$?
[ "$code" -eq 1 ] || fail "a drifted mirror should exit 1 (got $code)"
expect "$out" 'accessibility-ids: HealthTrackerUITests/Support/AccessibilityID.swift:2: "addButton" not declared in HealthTracker/Presentation/AccessibilityID.swift'
expect "$out" 'accessibility-ids: HealthTrackerUITests/Support/AccessibilityID.swift:4: "ghost" not declared in HealthTracker/Presentation/AccessibilityID.swift'
expect "$out" 'accessibility-ids: HealthTrackerUITests/Support/AccessibilityID.swift:7: "mealCard_\(…)" not declared in HealthTracker/Presentation/AccessibilityID.swift'
[ "$(wc -l <<<"$out" | tr -d ' ')" -eq 3 ] || fail "expected exactly 3 violations, got:"$'\n'"$out"

[ "$failures" -eq 0 ]
