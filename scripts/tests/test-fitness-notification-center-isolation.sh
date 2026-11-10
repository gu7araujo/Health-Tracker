#!/usr/bin/env bash
# scripts/fitness/notification-center-isolation.sh: a file that calls UNUserNotificationCenter
# declares only nonisolated types (or actors), so its synchronous calls never run on the main actor.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$ROOT/scripts/fitness/notification-center-isolation.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
failures=0

fail() {
  printf '  FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

# put <repo> <path> <lines...>
put() {
  local file="$1/$2"
  mkdir -p "$(dirname "$file")"
  printf '%s\n' "${@:3}" >"$file"
}

# Must fail: the #51 -> #54 miss, a main-actor-isolated class making the synchronous call.
put "$TMP/fail" HealthTracker/Data/Services/NotificationService.swift \
  'import UserNotifications' \
  'final class NotificationService: NotificationServiceProtocol {' \
  '    func cancelAllNotifications() {' \
  '        notificationCenter.removeAllPendingNotificationRequests()' \
  '    }' \
  '}' \
  'private nonisolated extension NotificationAuthorizationOptions {}'
out="$("$SCRIPT" "$TMP/fail")"
code=$?
[ "$code" -eq 1 ] || fail "a main-actor class calling the center should exit 1 (got $code)"
[ "$out" = 'notification-center-isolation: HealthTracker/Data/Services/NotificationService.swift:2: "final class NotificationService" is not nonisolated in a file that calls UNUserNotificationCenter' ] ||
  fail "should name the file, line and declaration, got: $out"

# Each isolated declaration in such a file is one violation: extensions and @MainActor types too.
put "$TMP/many" HealthTracker/Data/Services/Center.swift \
  'extension UNUserNotificationCenter: UserNotificationCentering {}' \
  '@MainActor struct Canceller {' \
  '    func cancel() { center.removeDeliveredNotifications(withIdentifiers: []) }' \
  '}'
out="$("$SCRIPT" "$TMP/many")"
[ "$(wc -l <<<"$out")" -eq 2 ] || fail "should report both declarations, got: $out"
[[ "$out" == *'Center.swift:1: "extension UNUserNotificationCenter"'*'Center.swift:2: "@MainActor struct Canceller"'* ]] ||
  fail "should name the extension and the struct, got: $out"

# Must pass: nonisolated types and actors; mentions in comments; files that never touch the center.
put "$TMP/pass" HealthTracker/Data/Services/NotificationService.swift \
  '/// Wraps UNUserNotificationCenter.' \
  'final nonisolated class NotificationService: NotificationServiceProtocol {' \
  '    struct Nested {}' \
  '    func cancelAllNotifications() { notificationCenter.removeAllPendingNotificationRequests() }' \
  '}' \
  'nonisolated extension UNUserNotificationCenter: UserNotificationCentering {}' \
  'actor Scheduler { func clear() { UNUserNotificationCenter.current().removeAllDeliveredNotifications() } }'
put "$TMP/pass" HealthTracker/Domain/Protocols/NotificationServiceProtocol.swift \
  '/// iOS UNUserNotificationCenterDelegate. // removeAllPendingNotificationRequests()' \
  'protocol NotificationCenterDelegate {}'
put "$TMP/pass" HealthTracker/Presentation/ViewModels/VM.swift 'final class VM {}'
# Test doubles are out of scope: the rule guards the app.
put "$TMP/pass" HealthTrackerTests/Mocks/MockCenter.swift \
  'final class MockCenter { func removeAllPendingNotificationRequests() {} }'
out="$("$SCRIPT" "$TMP/pass")"
code=$?
[ "$code" -eq 0 ] || fail "nonisolated types, actors and comments should exit 0 (got $code)"
[ -z "$out" ] || fail "should print nothing, got: $out"

# A tree without app sources has nothing to check.
mkdir -p "$TMP/empty"
out="$("$SCRIPT" "$TMP/empty")"
[ $? -eq 0 ] && [ -z "$out" ] || fail "a tree without HealthTracker/ should pass silently, got: $out"

# The real repository is clean.
out="$("$SCRIPT")"
[ $? -eq 0 ] || fail "this repository should pass:"$'\n'"$out"

[ "$failures" -eq 0 ]
