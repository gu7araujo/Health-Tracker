#!/usr/bin/env bash
# scripts/fitness/localization-parity.sh: every *.strings file has the same key set in en and pt-BR.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$ROOT/scripts/fitness/localization-parity.sh"
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

# strings_file <repo> <locale> <file> <content>
strings_file() {
  mkdir -p "$1/HealthTracker/Resources/$2.lproj"
  printf '%s\n' "$4" >"$1/HealthTracker/Resources/$2.lproj/$3"
}

# Must pass: identical key sets despite different values, order, spacing and comments.
strings_file "$TMP/pass" en Localizable.strings '/* Titles */
"app_title" = "Track your health";
// "commented_out" = "ignored";
"quoted \"key\"" = "Quote";
/* A block comment
   "inside_comment" = "ignored"; */
  "indented"="Spaces vary";'
strings_file "$TMP/pass" pt-BR Localizable.strings '"indented" = "Espaços";
"quoted \"key\"" = "Aspas";
"app_title" = "Acompanhe sua saúde";'
strings_file "$TMP/pass" en AppShortcuts.strings '"shortcut" = "Log water";'
strings_file "$TMP/pass" pt-BR AppShortcuts.strings '"shortcut" = "Registrar água";'
out="$("$SCRIPT" "$TMP/pass")"
code=$?
[ "$code" -eq 0 ] || fail "matching key sets should exit 0 (got $code): $out"
[ -z "$out" ] || fail "matching key sets should print nothing, got: $out"

# Must fail: a key missing on each side, and a file missing from each locale.
strings_file "$TMP/fail" en Localizable.strings '"shared" = "Shared";
"only_en" = "English only";'
strings_file "$TMP/fail" pt-BR Localizable.strings '"shared" = "Compartilhado";
"only_pt" = "Só português";'
strings_file "$TMP/fail" en AppShortcuts.strings '"shortcut" = "Log water";'
strings_file "$TMP/fail" pt-BR Extra.strings '"extra" = "Extra";'
out="$("$SCRIPT" "$TMP/fail")"
code=$?
[ "$code" -eq 1 ] || fail "mismatched key sets should exit 1 (got $code)"
expect "$out" 'localization-parity: HealthTracker/Resources/pt-BR.lproj/Localizable.strings: missing key "only_en" (present in en.lproj)'
expect "$out" 'localization-parity: HealthTracker/Resources/en.lproj/Localizable.strings: missing key "only_pt" (present in pt-BR.lproj)'
expect "$out" 'localization-parity: HealthTracker/Resources/pt-BR.lproj/AppShortcuts.strings: missing file (present in en.lproj)'
expect "$out" 'localization-parity: HealthTracker/Resources/en.lproj/Extra.strings: missing file (present in pt-BR.lproj)'
[ "$(wc -l <<<"$out" | tr -d ' ')" -eq 4 ] || fail "expected exactly 4 violations, got:"$'\n'"$out"

[ "$failures" -eq 0 ]
