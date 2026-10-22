# HealthTracker

An iOS 26 health tracking app (SwiftUI, Swift 6, Clean Architecture). Agents working in this repo follow `AGENTS.md`; this README is the same workflow for humans.

## Setup

Install the tools with Homebrew:

```bash
brew install swiftlint swiftformat xcbeautify jq
```

Then, once per clone, enable the git hooks and check tool versions:

```bash
scripts/bootstrap
```

`bootstrap` sets `core.hooksPath=.githooks`. The path is relative, so every worktree uses its own hooks. If a different hooks path was configured before, it tells you it replaced it. Re-running it is safe.

### Tool versions

Versions are pinned in `scripts/tool-versions.env` (SwiftLint 0.65.0, SwiftFormat 0.61.1, Xcode 27.1). Different formatter versions format code differently, so a mismatch can make the format gate fail on code that looks fine. Check yours with:

```bash
scripts/doctor
```

It prints a fix command for each mismatch. Locally it only warns; with `CI=true` it fails.

## The quality gate

`scripts/quality` is the single command that decides whether the code is good to ship. It prints a pass/fail table and exits `0` only when every gate passes:

```
Format                               0  <= 0       ✓
Lint                                 0  <= 0       ✓
Unit tests                           0  <= 0       ✓
UI tests                             0  <= 0       ✓
App line coverage               94.17%  >= 90.0%   ✓
Per-file floor                  88.36%  >= 80.0%   ✓

6/6 gates passed.
```

| Command | Runs | Time | Use it |
|---|---|---|---|
| `scripts/quality` or `scripts/quality --fast` | format, lint, unit tests, Domain/Data unit coverage | ~2 min | while you work; the pre-push hook runs it too |
| `scripts/quality --full` | everything above (Domain/Data ratchets included), plus UI tests, app coverage and the per-file floor | ~8 min | before marking a PR ready; this is the definition of done |

Other options (`scripts/quality --help` lists them all):

- `--json` also writes `build/quality.json`, one entry per gate.
- `--simulator <udid>` runs the tests on a simulator you choose.
- `--update-baseline` raises the coverage ratchets (see below).

Exit codes: `0` means every gate passed, `1` means a gate failed, `2` means a usage error.

### Simulators

By default, the gate tests on a simulator named `HT-<branch>`, with `/` replaced by `-`. It clones one the first time, so each branch or worktree gets its own device and parallel runs don't collide. An exported `SIMULATOR_ID` is ignored on purpose; pass `--simulator <udid>` to choose a device. When you're done with a branch, delete its simulator:

```bash
xcrun simctl delete "HT-feature-my-branch"
```

### Coverage gates

Thresholds live in `scripts/quality-thresholds.env`:

| Gate | Mode | Threshold | Meaning |
|---|---|---|---|
| App line coverage | `--full` | `APP_LINE_MIN` = 90.0 | whole app, unit + UI tests |
| Per-file floor | `--full` | `FILE_FLOOR` = 80.0 | every non-View file, so a new untested file can't hide behind a good average |
| Domain unit line coverage | both | `DOMAIN_UNIT_MIN` (ratchet) | `HealthTracker/Domain/`, unit tests only |
| Data unit line coverage | both | `DATA_UNIT_MIN` (ratchet) | `HealthTracker/Data/`, unit tests only |

- **Unit-only ratchets.** Domain and Data are counted from unit tests alone because UI tests run code without really asserting it. The ratchets start at today's measured values and only go up.
- **Raising them.** After adding tests, lock the gain in, then commit the updated thresholds file together with the tests:

  ```bash
  scripts/quality --fast --update-baseline
  ```

  It only raises thresholds, and only after a fully green run.
- **Grandfathered files.** `scripts/coverage-exceptions.txt` lists files that were already below the floor. Remove an entry once its file is covered.
- **Lowering a bar.** Lowering a threshold or adding an exception is a deliberate, reviewed change: call it out in the PR.

### When a gate is red

- **Format**: run `swiftformat . --swift-version 6`.
- **Lint**: fix the reported violations; `swiftlint --fix` handles the autocorrectable ones.
- **Unit / UI tests**: the full log is in `build/xcodebuild.log`. Rerun one test with the commands in `.agents/skills/cli-test/SKILL.md`.
- **Coverage**: list the least-covered files from the last run, then add tests for them:

  ```bash
  xcrun xccov view --report --json build/Test.xcresult | jq -r '.targets[]
    | select(.name == "HealthTracker.app") | .files | sort_by(.lineCoverage) | .[:10][]
    | "\(.lineCoverage * 100 | floor)%\t\(.path | sub(".*/HealthTracker/"; "HealthTracker/"))"'
  ```

- **`n/a` in the table**: the metric couldn't be measured, usually because the build failed or a test bundle crashed. Read `build/xcodebuild.log`.

## Git hooks

| Hook | What it does |
|---|---|
| `pre-commit` | refuses commits on `main` |
| | refuses Swift files that are only partially staged (stage or stash the rest first) |
| | formats the staged Swift files and re-stages them |
| | lints the staged Swift files with `swiftlint --strict` |
| `pre-push` | refuses pushes to `main` |
| | runs `scripts/quality --fast` |

In an emergency, `SKIP_QUALITY=1 git push` skips the pre-push gate. Use it sparingly: nothing else checks the branch until CI exists.

The Xcode build phase only lints and never rewrites your files. Formatting happens in the pre-commit hook. Lint warnings show up inline in Xcode.

## Day-to-day workflow

1. **Branch**: `git switch -c <type>/<name>`. Commits on `main` are refused.
2. **Write a failing test, then the code**, following the red → green loop in `AGENTS.md`.
3. **Iterate** with `scripts/quality --fast`.
4. **Commit.** The pre-commit hook formats and lints your staged Swift files.
5. **Push.** The pre-push hook runs `--fast` again (~2 min).
6. **Before marking the PR ready**, run `scripts/quality --full` and paste its table into the PR description.
7. **Merge.** Every PR is reviewed and merged by hand; there is no auto-merge.

## Working with AI agents

- Agents read `AGENTS.md` (plus a per-layer `AGENTS.md` in each folder) and the skills in `.agents/skills/`. The `quality-gate` skill covers the gate.
- `.claude/settings.json` stops agents from:
  - bypassing the hooks (`--no-verify`, `SKIP_QUALITY`, overriding `core.hooksPath`);
  - pushing to `main` or force-pushing;
  - merging PRs (`gh pr merge`).
- A Claude Code hook formats and lints every Swift file an agent edits.
- Agents open PRs as **drafts**, and stop once the PR is ready with the gate table pasted in. You review and merge.

## Testing the scripts themselves

The gate, hooks and helpers have their own bash tests (fixtures and stubbed tools, no simulator needed):

```bash
scripts/tests/run
```

Run them after changing anything under `scripts/`, `.githooks/` or `.claude/hooks/`.
