---
name: cleanup-worktrees
description: Clean up what finished git worktrees leave on this Mac - the worktrees in .claude/worktrees and ~/.t3/worktrees, their HT-<branch> simulators and their Xcode DerivedData folders. Use when asked to clean up worktrees, simulators or DerivedData, or to free disk space after parallel agents.
---

`cleanup.sh` in this folder does the work. It keeps any worktree with uncommitted changes or a HEAD on no remote branch, plus that worktree's simulators and DerivedData. It always keeps the main checkout and `HT-main`. The standard iPhone and iPad simulators are never touched, and neither is `build/DerivedData` inside a checkout, which goes away with its worktree.

1. **Dry run.** From the main checkout, run `.claude/skills/cleanup-worktrees/cleanup.sh`. It prints each worktree, `HT-*` simulator and `HealthTracker-*` DerivedData folder as `remove`/`delete` or `KEEP` with the reason. **Done when:** you hold that list.
2. **Confirm.** Show the user the list. A worktree another agent or session is still using looks clean, so the user decides. If they want a kept worktree removed, they say so and you run `git worktree remove <path>` for it. **Done when:** the user approves.
3. **Apply.** Run the script with `--apply`, then run it again without flags. **Done when:** the second run lists nothing to remove or delete beyond what the user chose to keep.

Report what was removed and what was kept, with the reason for each kept item. A deleted DerivedData folder only costs a slower next build.
