#!/usr/bin/env bash
# Every *.strings file in HealthTracker/Resources/en.lproj must exist in pt-BR.lproj with the identical
# key set, and vice versa (Presentation rule: "the two files stay in sync"). Values are not compared.
#
# Usage: localization-parity.sh [repo-root]
# Prints one line per missing file or key; exits 1 if any.
set -euo pipefail

REPO="${1:-$(cd "$(dirname "$0")/../.." && pwd)}"
RES=HealthTracker/Resources
LOCALES=(en pt-BR)
export LC_ALL=C

# keys <file>: the key of every `"key" = "value";` entry, skipping /* */ and // comments.
# A key is the first string literal of each statement; escapes (\") stay as written.
keys() {
  awk '
    {
      line = $0 "\n"
      for (i = 1; i <= length(line); i++) {
        c = substr(line, i, 1); next2 = substr(line, i, 2)
        if (state == "block") { if (next2 == "*/") { state = ""; i++ }; continue }
        if (state == "line") { if (c == "\n") state = ""; continue }
        if (state == "string") {
          if (c == "\\") { text = text substr(line, i, 2); i++ }
          else if (c == "\"") { state = ""; if (!seen_key) { print text; seen_key = 1 } }
          else text = text c
          continue
        }
        if (next2 == "/*") { state = "block"; i++ }
        else if (next2 == "//") { state = "line"; i++ }
        else if (c == "\"") { state = "string"; text = "" }
        else if (c == ";") seen_key = 0
      }
    }
  ' "$1" | sort -u
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
violations=0

report() {
  printf 'localization-parity: %s\n' "$1"
  violations=$((violations + 1))
}

files="$(for locale in "${LOCALES[@]}"; do
  for path in "$REPO/$RES/$locale.lproj"/*.strings; do
    if [ -e "$path" ]; then basename "$path"; fi
  done
done | sort -u)"

while IFS= read -r name; do
  [ -n "$name" ] || continue
  for locale in "${LOCALES[@]}"; do
    if [ -f "$REPO/$RES/$locale.lproj/$name" ]; then
      keys "$REPO/$RES/$locale.lproj/$name" >"$TMP/$locale"
    else
      rm -f "$TMP/$locale"
    fi
  done
  for locale in "${LOCALES[@]}"; do
    for other in "${LOCALES[@]}"; do
      [ "$other" != "$locale" ] || continue
      # Report against the locale that lacks the file or key.
      [ -f "$TMP/$other" ] || continue
      if [ ! -f "$TMP/$locale" ]; then
        report "$RES/$locale.lproj/$name: missing file (present in $other.lproj)"
        continue
      fi
      while IFS= read -r key; do
        report "$RES/$locale.lproj/$name: missing key \"$key\" (present in $other.lproj)"
      done < <(comm -13 "$TMP/$locale" "$TMP/$other")
    done
  done
done <<<"$files"

[ "$violations" -eq 0 ]
