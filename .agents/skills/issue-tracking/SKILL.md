---
name: issue-tracking
description: File, pick up and close HealthTracker's GitHub Issues, the repo's task tracker. Use when a task won't fit this session or is out of scope for it, when filing a retro row, a your-call decision or a flaky test, when triaging open issues, or when picking up or closing an issue.
---

# Issue tracking

GitHub Issues hold every task that outlives a session: one issue per task, closed by the PR that does it. A session ends with its deferred work filed, so the next agent picks it up from `gh issue list` instead of from memory.

## When to file

File an issue for:

- a task deferred or out of scope for this session (a follow-up a PR names, a finding left for later);
- each retro row the user approves, and each your-call row (`retro` skill, step 3);
- a decision only the user can make (a threshold, an exception, a product trade-off);
- a flaky test, on its first sighting: the run id makes the second sighting provable.

Work that this session's PR finishes goes in that PR's body, not in an issue.

## Labels

Each issue takes every area label it touches (`ci`, `intents`, `product`; GitHub's `documentation` for docs-only work), plus each of `retro`, `flaky-test` and `your-call` that applies. GitHub's defaults (`bug`, `enhancement`, `documentation`, `dependencies`, `github_actions`, `duplicate`, `wontfix`) keep their meanings.

| Label | Means |
|---|---|
| `retro` | Came from a retro row |
| `ci` | CI workflows, `scripts/quality`, hooks, the gate's tools |
| `flaky-test` | A test that passed and failed on the same code |
| `intents` | App Intents, App Shortcuts, `HealthTrackerIntentsUITests` |
| `product` | User-visible app behaviour |
| `your-call` | Blocked on the user's decision; the agent proposes, the user picks |

A label missing from the repo: `gh label create <name> --description "<the meaning above>"`.

## 1. Dedupe

```bash
gh issue list --state all --search "<keywords>" --limit 50
```

Search two or three keyword sets (the file, the test, the symptom). An open match gets a comment with the new evidence instead of a new issue; a partial overlap gets a new issue that links it (`Related: #<n>`); a closed match that recurred gets reopened with the new evidence.

**Done when:** each keyword set's results are read, and the task is a comment, a reopen, or a new issue.

## 2. File

```bash
gh issue create --title "<imperative, under 70 chars>" --label <area>[,retro][,your-call] --body-file <file>
```

The body, in this order:

- **Problem**: what is wrong or missing, with evidence (PR, commit sha, run id, file:line, the failing output).
- **Proposed action**: the smallest change that fixes it.
- **Done when**: a checkable condition (a test goes red → green, a gate row passes, a count reaches 0). A condition checkable only after the PR merges (the next CI or review run) says so, and that PR uses `Part of #<n>`.
- **Effort**: S < 1 h, M < half a day, L.

A `your-call` issue replaces Proposed action with **Options**: each option with its numbers (the threshold before and after, the coverage it costs, the runtime it saves), the agent's recommendation last.

**Done when:** the issue exists with every section filled, and its number is in the session's report.

## 3. Pick up

A `your-call` issue waits for the user's choice in a comment. For any other issue: branch (`git switch -c <type>/<name>`), then follow the root `AGENTS.md` Workflow and Quality Gates through the PR. The PR body's first line is `Closes #<n>`, so the merge closes the issue; a PR that does part of it says `Part of #<n>` instead.

## 4. Close

An issue closes when its PR merges, or, for a post-merge Done when, once that check passes. Any other close carries a comment saying why: `gh issue close <n> --reason "not planned" --comment "<why>"` for a wontfix, or `--comment "Duplicate of #<m>"` for a duplicate.

## The weekly auto-issue

A red scheduled run of `.github/workflows/weekly.yml` opens an unlabelled issue titled `Weekly quality gate failed`, or comments on the open one. Triage it like any other: add `ci` (and `flaky-test` when a re-run passes), read the linked run through the `quality-gate` skill's CI section, and close it with the fixing PR's `Closes #<n>`.
