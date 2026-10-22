#!/usr/bin/env bash
# scripts/fitness/persisted-shape-guard.sh: warns (never fails) when a PR changes a persisted shape
# without touching Data/Migration/ or that entity's tests. Runs against a throwaway git repo.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$ROOT/scripts/fitness/persisted-shape-guard.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
failures=0
REPO="$TMP/repo"
MEAL=HealthTracker/Domain/Entities/Meal.swift
MOOD=HealthTracker/Domain/Entities/Mood.swift
MESSAGE='persisted shape changed without touching HealthTracker/Data/Migration/ or DataMigrationTests; see the "Data Migrations" policy in AGENTS.md'

fail() {
  printf '  FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

# expect <output> <line>: the output must contain <line> as a whole line.
expect() {
  grep -qxF -- "$2" <<<"$1" || fail "missing line '$2' in:"$'\n'"$1"
}

git_() { git -C "$REPO" -c user.name=test -c user.email=test@example.com -c commit.gpgsign=false "$@"; }

# put <path> <content>
put() {
  mkdir -p "$(dirname "$REPO/$1")"
  printf '%s\n' "$2" >"$REPO/$1"
}

# branch <name>: a fresh branch from the base commit.
branch() { git_ checkout -q -B "$1" base; }

commit() { git_ add -A && git_ commit -q -m change; }

# guard [env...] -> sets out, code (base ref "base")
guard() {
  out="$(env -u GITHUB_ACTIONS "$@" "$SCRIPT" base "$REPO")"
  code=$?
}

git init -q "$REPO"
put "$MEAL" 'struct Meal: Codable {
    // Notes about the meal.
    let id: UUID
    var items: [String]

    func summary() -> String {
        items.joined()
    }
}'
put "$MOOD" 'enum Mood: String, Codable {
    case good
    case sad
}'
put HealthTracker/Presentation/Views/MainView.swift 'struct MainView {}'
commit
git_ branch -q -M base

# A stored-property change with nothing else warns, naming the file and the policy, and exits 0.
branch shape-only
put "$MEAL" "$(sed 's/var items: \[String\]/var calories: Int/' "$REPO/$MEAL")"
commit
guard
[ "$code" -eq 0 ] || fail "the guard is warn-only and must exit 0 (got $code)"
expect "$out" "persisted-shape-guard: $MEAL: warning: $MESSAGE"
[ "$(wc -l <<<"$out" | tr -d ' ')" -eq 1 ] || fail "expected exactly 1 warning, got:"$'\n'"$out"

# On GitHub Actions the warning becomes a PR annotation.
guard GITHUB_ACTIONS=true
[ "$code" -eq 0 ] || fail "the guard must exit 0 on GitHub Actions (got $code)"
expect "$out" "::warning file=$MEAL::$MESSAGE"

# An enum case change is a shape change too.
branch enum-case
put "$MOOD" "$(sed 's/case sad/case unhappy/' "$REPO/$MOOD")"
commit
guard
expect "$out" "persisted-shape-guard: $MOOD: warning: $MESSAGE"

# An enum raw-type change changes the encoded JSON.
branch raw-type
put "$MOOD" "$(sed 's/enum Mood: String, Codable/enum Mood: Int, Codable/' "$REPO/$MOOD")"
commit
guard
expect "$out" "persisted-shape-guard: $MOOD: warning: $MESSAGE"

# Editing only the entity's own tests does not silence it: a rename usually forces those edits anyway.
branch with-entity-tests
put "$MEAL" "$(sed 's/let id: UUID/let id: String/' "$REPO/$MEAL")"
put HealthTrackerTests/Domain/Entities/MealTests.swift 'struct MealTests {}'
commit
guard
expect "$out" "persisted-shape-guard: $MEAL: warning: $MESSAGE"

# Touching the migration tests silences the warning.
branch with-migration-tests
put "$MEAL" "$(sed 's/let id: UUID/let id: String/' "$REPO/$MEAL")"
put HealthTrackerTests/Data/DataMigrationTests.swift 'struct DataMigrationTests {}'
commit
guard
[ -z "$out" ] || fail "a shape change with migration tests should not warn, got: $out"

# Touching Data/Migration/ silences the warning.
branch with-migration
put "$MEAL" "$(sed 's/let id: UUID/let id: String/' "$REPO/$MEAL")"
put HealthTracker/Data/Migration/DataMigration.swift 'struct DataMigration {}'
commit
guard
[ -z "$out" ] || fail "a shape change with a migration should not warn, got: $out"

# Comments, method bodies and unrelated files are not shape changes.
branch no-shape
put "$MEAL" "$(sed -e 's/Notes about the meal/Notes about a meal/' -e 's/items.joined()/items.joined(separator: " ")/' "$REPO/$MEAL")"
put HealthTracker/Presentation/Views/MainView.swift 'struct MainView { var title: String }'
commit
guard
[ "$code" -eq 0 ] && [ -z "$out" ] || fail "non-shape changes should not warn (code $code): $out"

# A missing base ref prints a note and still exits 0.
out="$("$SCRIPT" no-such-ref "$REPO")"
code=$?
[ "$code" -eq 0 ] || fail "an invalid base ref must exit 0 (got $code)"
[[ "$out" == "persisted-shape-guard: note:"*"no-such-ref"* ]] || fail "an invalid base ref should print a note, got: $out"
out="$("$SCRIPT" "" "$REPO")" || fail "an empty base ref must exit 0"
[[ "$out" == "persisted-shape-guard: note:"* ]] || fail "an empty base ref should print a note, got: $out"

[ "$failures" -eq 0 ]
