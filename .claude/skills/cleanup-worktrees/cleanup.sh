#!/usr/bin/env bash
# cleanup.sh: list (default) or delete (--apply) what finished worktrees leave on this Mac:
# the extra git worktrees, their HT-<branch> simulators and their Xcode DerivedData folders.
# A worktree with uncommitted changes, or a HEAD on no remote branch, is kept, and so are
# its simulators and DerivedData. The main checkout and HT-main are always kept.
# Usage: cleanup.sh [--apply]   (from any checkout of the repo)
# Exit: 0 done, 1 bad argument.
set -euo pipefail

apply=""
case "${1:-}" in
  "") ;;
  --apply) apply=1 ;;
  *) echo "usage: $0 [--apply]" >&2; exit 1 ;;
esac

run() { if [ -n "$apply" ]; then "$@"; else echo "    would run: $*"; fi; }

worktrees() { git worktree list --porcelain | sed -n 's/^worktree //p'; }
main="$(worktrees | sed -n 1p)"
kept=("$main")

echo "Worktrees:"
while IFS= read -r wt; do
  if [ ! -d "$wt" ]; then
    echo "  prune $wt (folder already gone)"
  elif [ -n "$(git -C "$wt" status --porcelain)" ]; then
    echo "  KEEP  $wt (uncommitted changes)"; kept+=("$wt")
  elif [ -z "$(git -C "$wt" branch -r --contains HEAD)" ]; then
    echo "  KEEP  $wt (HEAD is on no remote branch)"; kept+=("$wt")
  else
    echo "  remove $wt"
    run git -C "$main" worktree remove "$wt" || { echo "    failed, kept"; kept+=("$wt"); }
  fi
done < <(worktrees | tail -n +2)
run git -C "$main" worktree prune

# Simulator names follow scripts/quality: HT-<branch with / as ->, plus HT-<branch>-ios27.
keep_sims=" HT-main HT-main-ios27 "
for wt in "${kept[@]}"; do
  b="$(git -C "$wt" rev-parse --abbrev-ref HEAD)"; b="${b//\//-}"
  keep_sims+="HT-$b HT-$b-ios27 "
done

echo "Simulators:"
while read -r udid name; do
  if [[ "$keep_sims" == *" $name "* ]]; then echo "  KEEP  $name"; continue; fi
  echo "  delete $name ($udid)"
  run xcrun simctl shutdown "$udid" 2>/dev/null || true
  run xcrun simctl delete "$udid"
done < <(xcrun simctl list devices -j | jq -r '.devices[][] | select(.name | startswith("HT-")) | "\(.udid) \(.name)"')

echo "DerivedData:"
dd="$HOME/Library/Developer/Xcode/DerivedData"
for d in "$dd"/HealthTracker-*; do
  [ -d "$d" ] || continue
  ws="$(plutil -extract WorkspacePath raw "$d/info.plist" 2>/dev/null || true)"
  keep=""
  for wt in "${kept[@]}"; do [ "$ws" = "$wt/HealthTracker.xcodeproj" ] && keep=1; done
  if [ -n "$keep" ]; then echo "  KEEP  $(basename "$d") ($ws)"; continue; fi
  echo "  delete $(basename "$d") (${ws:-no workspace recorded})"
  run rm -rf "$d"
done

[ -n "$apply" ] || echo "Dry run. Rerun with --apply to delete."
