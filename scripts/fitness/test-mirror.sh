#!/usr/bin/env bash
# Every .swift file under HealthTracker/Domain/ and HealthTracker/Data/ needs a matching
# HealthTrackerTests/**/<Name>Tests.swift (Tests rule: "mirrors the production tree one-to-one").
# A basename shared with any other HealthTracker/ source is ambiguous, so each such file needs its test
# at the mirrored path: HealthTracker/<dirs>/<Name>.swift -> HealthTrackerTests/<dirs>/<Name>Tests.swift.
#
# Skipped:
#   - Protocol-only files: the file declares a protocol, and, comments aside, every line holding a `{`
#     opens a protocol, struct or enum and holds only that one `{`. So protocols plus plain data types
#     (cases, stored lets) pass; any func/init/computed-property/closure body, class, actor or extension
#     makes the file need a test.
#   - Paths listed in scripts/fitness/test-mirror-exceptions.txt (repo-relative path, then a # comment).
#     A stale entry (the file has a test now, or no longer exists) is a violation, so the list only shrinks.
#
# Usage: test-mirror.sh [repo-root]
# Prints one line per violation; exits 1 if any.
set -euo pipefail

REPO="${1:-$(cd "$(dirname "$0")/../.." && pwd)}"
EXCEPTIONS=scripts/fitness/test-mirror-exceptions.txt
violations=0

report() {
  printf 'test-mirror: %s\n' "$1"
  violations=$((violations + 1))
}

# protocol_only <file>: see the header. One awk pass over the whole file (no pipe that could stop early);
# a line with more than one `{` hides a body on a one-line declaration, so it needs a test too.
protocol_only() {
  awk '
    { sub(/\/\/.*/, "") }
    /\/\*/ { comment = 1 }
    comment { if (/\*\//) comment = 0; next }
    /(^|[[:space:]])protocol[[:space:]]/ { proto = 1 }
    /\{/ {
      if (gsub(/\{/, "{") > 1) logic = 1
      else if ($0 !~ /^[[:space:]]*((public|internal|fileprivate|private)[[:space:]]+)?(protocol|struct|enum)[[:space:]]/) logic = 1
    }
    END { exit !(proto && !logic) }
  ' "$1"
}

# ambiguous <source path>: its basename is shared by another HealthTracker/ source.
ambiguous() {
  grep -qxF "$(basename "$1")" <<<"$duplicates"
}

# mirrored_test <source path>: HealthTrackerTests/<same dirs>/<Name>Tests.swift
mirrored_test() {
  local rel="${1#HealthTracker/}"
  printf 'HealthTrackerTests/%sTests.swift' "${rel%.swift}"
}

# has_test <source path>
has_test() {
  if ambiguous "$1"; then
    [ -f "$REPO/$(mirrored_test "$1")" ]
  else
    grep -qxF "$(basename "$1" .swift)Tests.swift" <<<"$tests"
  fi
}

tests="$(find "$REPO/HealthTrackerTests" -name '*Tests.swift' -exec basename {} \; 2>/dev/null || true)"

# "<line>\t<path>" for every exception entry.
excepted=""
if [ -f "$REPO/$EXCEPTIONS" ]; then
  excepted="$(awk '{ sub(/#.*/, ""); gsub(/^[[:space:]]+|[[:space:]]+$/, "") } $0 != "" { print NR "\t" $0 }' "$REPO/$EXCEPTIONS")"
fi
excepted_paths="$(cut -f2 <<<"$excepted")"

sources="$(cd "$REPO" && for dir in HealthTracker/Domain HealthTracker/Data; do
  if [ -d "$dir" ]; then find "$dir" -name '*.swift'; fi
done | LC_ALL=C sort)"
# Ambiguous names count every app source (e.g. a Presentation file can share a Domain file's name).
duplicates="$(cd "$REPO" && if [ -d HealthTracker ]; then find HealthTracker -name '*.swift'; fi |
  sed 's#.*/##' | LC_ALL=C sort | uniq -d)"

while IFS= read -r path; do
  [ -n "$path" ] || continue
  has_test "$path" && continue
  grep -qxF "$path" <<<"$excepted_paths" && continue
  protocol_only "$REPO/$path" && continue
  if ambiguous "$path"; then
    report "$path: no $(mirrored_test "$path") ($(basename "$path") is not a unique name, so its test must mirror its path)"
  else
    report "$path: no HealthTrackerTests/**/$(basename "$path" .swift)Tests.swift"
  fi
done <<<"$sources"

while IFS=$'\t' read -r line path; do
  [ -n "$path" ] || continue
  if [ ! -f "$REPO/$path" ]; then
    report "$EXCEPTIONS:$line: stale exception $path (file no longer exists; remove the entry)"
  elif has_test "$path"; then
    report "$EXCEPTIONS:$line: stale exception $path (it has a test now; remove the entry)"
  fi
done <<<"$excepted"

[ "$violations" -eq 0 ]
