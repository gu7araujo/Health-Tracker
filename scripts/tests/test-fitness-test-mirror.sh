#!/usr/bin/env bash
# scripts/fitness/test-mirror.sh: every Domain/Data source file has a <Name>Tests.swift, unless excepted.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$ROOT/scripts/fitness/test-mirror.sh"
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

# put <repo> <path> [content]
put() {
  mkdir -p "$(dirname "$1/$2")"
  printf '%s\n' "${3:-struct Placeholder {}}" >"$1/$2"
}

# exceptions <repo> <content>
exceptions() {
  mkdir -p "$1/scripts/fitness"
  printf '%s\n' "$2" >"$1/scripts/fitness/test-mirror-exceptions.txt"
}

PROTOCOL_ONLY='import Foundation

/// A protocol { with a brace in its doc comment }.
protocol Repository {
    func load() -> [String]
    func save(
        days: [String]
    ) async throws
}

// Plain data next to the protocol is still declaration-only.
struct Options: OptionSet {
    let rawValue: Int
    static let alert = Options(rawValue: 1 << 0)
}

enum Status {
    case on
    case off
}'

PROTOCOL_WITH_EXTENSION='protocol Centering {
    func status() async -> Int
}

extension Center: Centering {
    func status() async -> Int {
        0
    }
}'

# Must pass: tests mirrored anywhere under HealthTrackerTests, protocol-only files and exceptions skipped.
R="$TMP/pass"
put "$R" HealthTracker/Domain/Entities/Meal.swift
put "$R" HealthTrackerTests/Domain/Entities/MealTests.swift
put "$R" HealthTracker/Data/Migration/DataMigration.swift
put "$R" HealthTrackerTests/Data/DataMigrationTests.swift
put "$R" HealthTracker/Domain/Protocols/Repository.swift "$PROTOCOL_ONLY"
put "$R" HealthTracker/Data/Services/Centering.swift "$PROTOCOL_WITH_EXTENSION"
put "$R" HealthTracker/Presentation/Views/MainView.swift
exceptions "$R" '# Header comment.

HealthTracker/Data/Services/Centering.swift  # bridges the real center'
out="$("$SCRIPT" "$R")"
code=$?
[ "$code" -eq 0 ] || fail "a mirrored tree should exit 0 (got $code): $out"
[ -z "$out" ] || fail "a mirrored tree should print nothing, got: $out"

# Must fail: untested files (including a protocol with an extension body) and stale exceptions.
R="$TMP/fail"
put "$R" HealthTracker/Domain/UseCases/SaveUseCase.swift
put "$R" HealthTrackerTests/Domain/UseCases/SaveUseCaseLoggingTests.swift
put "$R" HealthTracker/Data/Services/Centering.swift "$PROTOCOL_WITH_EXTENSION"
put "$R" HealthTracker/Domain/Entities/Mood.swift
put "$R" HealthTrackerTests/Domain/Entities/MoodTests.swift
exceptions "$R" 'HealthTracker/Domain/Entities/Mood.swift  # now tested
HealthTracker/Data/Services/Gone.swift  # deleted'
out="$("$SCRIPT" "$R")"
code=$?
[ "$code" -eq 1 ] || fail "an unmirrored tree should exit 1 (got $code)"
expect "$out" 'test-mirror: HealthTracker/Domain/UseCases/SaveUseCase.swift: no HealthTrackerTests/**/SaveUseCaseTests.swift'
expect "$out" 'test-mirror: HealthTracker/Data/Services/Centering.swift: no HealthTrackerTests/**/CenteringTests.swift'
expect "$out" 'test-mirror: scripts/fitness/test-mirror-exceptions.txt:1: stale exception HealthTracker/Domain/Entities/Mood.swift (it has a test now; remove the entry)'
expect "$out" 'test-mirror: scripts/fitness/test-mirror-exceptions.txt:2: stale exception HealthTracker/Data/Services/Gone.swift (file no longer exists; remove the entry)'
[ "$(wc -l <<<"$out" | tr -d ' ')" -eq 4 ] || fail "expected exactly 4 violations, got:"$'\n'"$out"

# Must fail: logic hidden on a one-line declaration next to a protocol.
R="$TMP/one-liner"
put "$R" HealthTracker/Domain/Services/Runner.swift 'protocol Running {}
struct Runner: Running { func run() -> Int { 1 } }'
out="$("$SCRIPT" "$R")"
expect "$out" 'test-mirror: HealthTracker/Domain/Services/Runner.swift: no HealthTrackerTests/**/RunnerTests.swift'

# Must fail: a file larger than a pipe buffer is still read to the end (no SIGPIPE short-circuit).
R="$TMP/large"
put "$R" HealthTracker/Domain/Services/Big.swift "protocol Big {}
$(for i in $(seq 1 4000); do printf 'enum Pad%d { case a }\n' "$i"; done)
final class BigImpl: Big { func work() {} }"
out="$("$SCRIPT" "$R")"
expect "$out" 'test-mirror: HealthTracker/Domain/Services/Big.swift: no HealthTrackerTests/**/BigTests.swift'

# A missing exceptions file means no exceptions.
R="$TMP/no-exceptions"
put "$R" HealthTracker/Domain/Entities/Meal.swift
put "$R" HealthTrackerTests/Domain/Entities/MealTests.swift
"$SCRIPT" "$R" >/dev/null || fail "a missing exceptions file should not fail a mirrored tree"

[ "$failures" -eq 0 ]
