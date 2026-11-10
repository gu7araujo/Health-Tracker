#!/usr/bin/env bash
# A file under HealthTracker/ that calls UNUserNotificationCenter declares only `nonisolated` types
# and extensions (or actors). The app defaults to MainActor isolation, and the center's synchronous
# calls (removeAllPendingNotificationRequests() and its siblings) block on XPC: on the main actor
# they stall the UI (#51, #54).
#
# A file calls the center when, outside // comments, it names UNUserNotificationCenter or calls one
# of its synchronous methods. Only declarations at column 0 are checked: nested types inherit.
#
# Usage: notification-center-isolation.sh [repo-root]
# Prints one line per isolated declaration in such a file; exits 1 if any.
set -euo pipefail

REPO="${1:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$REPO"
[ -d HealthTracker ] || exit 0

find HealthTracker -name '*.swift' -exec awk '
  function flush(   i) {
    if (calls) for (i = 1; i <= count; i++) { print found[i]; violations++ }
    calls = 0
    count = 0
  }
  FNR == 1 { flush() }
  {
    sub(/\/\/.*/, "")
    if ($0 ~ /UNUserNotificationCenter|\.(removeAllPendingNotificationRequests|removePendingNotificationRequests|removeAllDeliveredNotifications|removeDeliveredNotifications|setNotificationCategories)\(/)
      calls = 1
    if ($0 !~ /nonisolated/ && match($0, /^([A-Za-z@]+ +)*(class|struct|enum|extension|protocol) +[A-Za-z_]+/))
      found[++count] = sprintf("notification-center-isolation: %s:%d: \"%s\" is not nonisolated in a file that calls UNUserNotificationCenter", \
        FILENAME, FNR, substr($0, RSTART, RLENGTH))
  }
  END {
    flush()
    exit (violations > 0)
  }
' {} +
