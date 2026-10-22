#!/usr/bin/env bash
# WARN-ONLY (always exits 0). Flags a branch that changes the persisted JSON shape of an entity
# without touching HealthTracker/Data/Migration/ or DataMigrationTests (root AGENTS.md "Data Migrations").
# Editing only the entity's own tests does not count: renaming a field usually forces those edits anyway.
#
# Shape lines: added or removed diff lines (comments aside) in a persisted file that declare a
# non-static `let`/`var` with a type annotation or an initializer (so a method-local `let x =` warns
# too), an enum `case`, an enum with a raw type or conformances, or mention CodingKeys,
# init(from:), encode(to:) or a container decode/encode call. Static members are not encoded.
# With GITHUB_ACTIONS=true each warning is a `::warning file=...::` annotation on the PR.
#
# Usage: persisted-shape-guard.sh <base-ref> [repo-root]
set -uo pipefail

BASE="${1:-}"
REPO="${2:-$(cd "$(dirname "$0")/../.." && pwd)}"
PERSISTED=(
  HealthTracker/Domain/Entities/DayData.swift
  HealthTracker/Domain/Entities/RecordedDayData.swift
  HealthTracker/Domain/Entities/Meal.swift
  HealthTracker/Domain/Entities/Workout.swift
  HealthTracker/Domain/Entities/Mood.swift
  HealthTracker/Data/Models/DayDataContainer.swift
)
MESSAGE='persisted shape changed without touching HealthTracker/Data/Migration/ or DataMigrationTests; see the "Data Migrations" policy in AGENTS.md'

note() {
  printf 'persisted-shape-guard: note: %s; skipping\n' "$1"
  exit 0
}

[ -n "$BASE" ] || note "no base ref given"
git -C "$REPO" rev-parse --verify --quiet "$BASE^{commit}" >/dev/null || note "base ref '$BASE' not found"
changed="$(git -C "$REPO" diff --name-only "$BASE...HEAD")" || note "cannot diff '$BASE...HEAD'"

grep -Eq '^(HealthTracker/Data/Migration/|HealthTrackerTests/(.*/)?DataMigrationTests[^/]*\.swift$)' <<<"$changed" && exit 0

# Persisted files with a shape line in the diff.
shaped="$(git -C "$REPO" diff --no-color --no-ext-diff --src-prefix=a/ --dst-prefix=b/ --unified=0 "$BASE...HEAD" -- "${PERSISTED[@]}" | awk '
  /^\+\+\+ / || /^--- / { if ($2 != "/dev/null") file = substr($2, 3); next }
  !/^[-+]/ { next }
  {
    line = substr($0, 2)
    sub(/^[[:space:]]+/, "", line)
    if (line ~ /^(\/\/|\/\*|\*)/) next
    if (line ~ /(^|[[:space:]])(static|class)[[:space:]]+(let|var)[[:space:]]/) next
    if (line ~ /^(@[A-Za-z]+[[:space:]]+)*([a-z()]+[[:space:]]+)*(let|var)[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]*[:=]/ ||
        line ~ /^(indirect[[:space:]]+)?case[[:space:]]/ ||
        line ~ /^((public|internal|fileprivate|private)[[:space:]]+)?(indirect[[:space:]]+)?enum[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]*:/ ||
        line ~ /CodingKeys|init\(from|encode\(to|\.(decode|decodeIfPresent|encode|encodeIfPresent)\(/) {
      if (!(file in seen)) { seen[file] = 1; print file }
    }
  }
')"

while IFS= read -r file; do
  [ -n "$file" ] || continue
  if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
    printf '::warning file=%s::%s\n' "$file" "$MESSAGE"
  else
    printf 'persisted-shape-guard: %s: warning: %s\n' "$file" "$MESSAGE"
  fi
done <<<"$shaped"

exit 0
