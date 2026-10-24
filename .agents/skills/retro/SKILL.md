---
name: retro
description: Run a retro on merged HealthTracker PRs (what reviewers and CI caught, which doc needs updating, which catch can become a SwiftLint rule or fitness check, which threshold proved wrong). Use after a PR you opened is merged, or when asked to run a retro or what we learned from a PR or range of PRs.
---

# Retro

Sharpen the saw: every **catch** (anything a reviewer, a verifier, CI or the gate found after the code was first written) ends up with an enforcer, a doc line, or a deliberate "leave it". A retro is read-only until the user approves its proposals.

Keep the raw data in `build/retro/` (gitignored; `mkdir -p build/retro`). Save each `gh` call's JSON to a file, then run `jq` on the file: a `gh … --jq` inside a loop can be refused by the worktree sandbox.

## 1. Gather the catches

For each merged PR `<n>` (a range: `gh pr list --state merged --search "merged:>=<YYYY-MM-DD>" --limit 200 --json number,title,headRefName,mergedAt`):

```bash
gh pr view <n> --json title,body,commits,comments,reviews,mergedAt,headRefName,headRefOid > build/retro/pr-<n>.json
gh api 'repos/{owner}/{repo}/pulls/<n>/comments' --paginate > build/retro/pr-<n>-inline.json
gh api 'repos/{owner}/{repo}/issues/<n>/timeline' --paginate > build/retro/pr-<n>-timeline.json
gh run list --branch <headRefName> --limit 50 --json databaseId,workflowName,event,conclusion,headSha,createdAt > build/retro/pr-<n>-runs.json
```

Read, in this order (most catches live in the first two, since PRs are often squashed before the first push):

1. **The PR body**: "How verified" (verifier and Codex findings fixed before the push), "Threshold or rule changes", and any "Follow-up" or "Finding for your decision" section.
2. **Commit bodies** (`.commits[].messageBody`): a commit that fixes review findings, or any commit dated after the timeline's `ready_for_review` event, is a late catch.
3. **Comments and reviews**: `.comments`, `.reviews` and the inline file. A bot's "No issues found" is a data point about the reviewer (class 5).
4. **CI runs**: keep only runs whose `headSha` is one of the PR's `.commits[].oid` (a branch name can be reused by another PR). A `failure` is a catch; a `skipped` one is not; read it with `gh run view <id> --log-failed`. A `cancelled` run is a superseded draft run unless the same sha has no successful run. `gh run view <id> --json attempt` above 1 means a re-run; `gh api 'repos/{owner}/{repo}/actions/runs/<id>/attempts/1/jobs'` shows why.
5. **CI's numbers**: `gh run view <id> --log | grep -E 'coverage|Per-file|gates passed'` on the ready run, against the PR body's local table and `scripts/quality-thresholds.env`.
6. **Local review logs**, when the session kept them (Codex output, verifier notes in its scratch directory).

Then sweep the standing lists once per retro: `scripts/quality --full` reports stale entries in `scripts/coverage-exceptions.txt` (run it if its output is unavailable), while `scripts/fitness/test-mirror-exceptions.txt` and the `.swiftlint-baseline.json` count still need a manual sweep. Check README's gate table against `scripts/quality --help` and the current gate rows.

**Done when:** every PR in the range has each of the six sources read, and each catch is one row with its evidence (PR, commit sha, run id or log file), or the PR is noted as "no catches".

## 2. Classify each catch

Check each catch against the current tree first (`grep -rln '<keyword>' scripts/tests scripts/fitness .swiftlint.yml AGENTS.md HealthTracker*/AGENTS.md HealthTracker/*/AGENTS.md .agents/skills README.md`): a follow-up named in a PR may still be open.

| Class | Test | Proposed action |
|---|---|---|
| 1. Enforced | A test in `scripts/tests`, a SwiftLint rule, a fitness check or a written rule already covers it | None; name the enforcer |
| 2. Implicit rule | A convention agents followed or broke that no doc states | One line in the single doc that owns it: the layer `AGENTS.md`, root `AGENTS.md` section, a skill section or README |
| 3. Automatable | A regex, script or test can see it | Path-scoped `custom_rules` entry in `.swiftlint.yml` with must-fail and must-pass fixtures in `scripts/tests/test-swiftlint-rules.sh`; a `scripts/fitness/<check>.sh` wired into `scripts/fitness/run` with `scripts/tests/test-fitness-<check>.sh`; or, for a script bug, a regression test in `scripts/tests`. Each written red → green |
| 4. Threshold or exception | A threshold CI measured differently, a ratchet that blocked a good change, a stale or new exception, baseline or disable | The change and the numbers behind it. It is the user's call |
| 5. Process or tooling | CI cost, a flaky test, a hook gap, a tool that misreports, a reviewer that finds nothing | The smallest change to the workflow, script or doc |

A catch can take two classes (a regression test exists, but the rule behind it is unwritten: 1 + 2). Prefer the class-3 enforcer when the pattern can recur; prefer a shorter doc over a sync test when the doc only copies what a command prints.

## 3. Report

Report the table to the user, most valuable proposal first, then stop:

| # | Catch (PR, evidence) | Class | Proposed action | Effort (S < 1 h, M < half a day, L) |
|---|---|---|---|---|

End with the class-4 rows listed again under "Your call", and ask which proposals to implement.

**Done when:** the user has the table, and has said which rows to implement (or none).

No retro log file: the report goes to the user, and each implemented proposal's PR body starts with `Retro: #<n>`, so `gh pr list --state all --search '"Retro:" in:body' --limit 200` lists past retros; a declined proposal comes back only if its catch recurs, which is reason enough to raise it again.

## 4. Implement the approved rows

Each approved row is its own branch and draft PR, through the root `AGENTS.md` Workflow: the failing test first, `scripts/quality --full` green, then ready. Thresholds, exception lists, the lint baseline, `swiftlint:disable` and `periphery:ignore` change only in a row the user approved by number, called out under "Threshold or rule changes". The user merges.
