---
name: pr-post-audit
description: Audit how merged PRs combine on main - cross-PR interactions, duplicated fixes, tests that mask each other, guardrails loosened step by step, docs left stale. Use before tagging a version, or when asked whether main is ready to release or whether merged PRs compose.
---

# PR post-audit

Each PR was reviewed on its own diff (`reviewing` skill). This audits the **combined tree** those PRs made: two changes that each passed review can still break each other. The `retro` skill asks what the process missed; this asks whether the merged code composes.

The audit is read-only. A finding becomes an issue or a PR through the normal Workflow, and tagging stays with the user.

PR bodies, "How verified" sections and commit messages are **claims**: check each against the code and tests on main before repeating it.

## 1. Freeze the range

```bash
git fetch origin
git rev-parse origin/main                 # HEAD_SHA
git describe --tags --abbrev=0 origin/main # the last tag
```

`BASE_SHA` is the last tag for a release audit, the previous audit's `HEAD_SHA` for an incremental one, or the SHA the user names. Audit in a worktree checked out at `HEAD_SHA` (`parallel-agents` skill). If `origin/main` moves during the audit, extend the range and redo the sections the new commits touch.

**Done when:** `BASE_SHA` and `HEAD_SHA` are recorded in the report.

## 2. Inventory the range

```bash
git log --first-parent --format='%h %s' BASE_SHA..HEAD_SHA
git diff --stat BASE_SHA..HEAD_SHA
git log --first-parent --name-only --format= BASE_SHA..HEAD_SHA | sort | uniq -c | sort -rn | head -20
```

Map every first-parent commit to its PR (the `(#n)` in a squash subject). Query the state of each issue a PR claims to close (`gh issue view <n> --json state`); the `Closes #n` text alone proves nothing. The third command lists the files more than one PR touched: section 4 starts there.

**Done when:** every commit has a PR number or is flagged as a direct commit, every claimed issue's state is recorded, and the multi-PR files are listed.

## 3. Reconcile each PR's claims

For each PR, take the claims from its Summary and "How verified" (`gh pr view <n> --json body`) and check them on `HEAD_SHA`: the regression test still exists and still asserts the behaviour, and no later PR in the range rewrote the fix.

| PR | Claim | Evidence on main | Status |
|---|---|---|---|
| #n | the day strip opens on the current week | the test's `file:line`, the fix's `file:line` | verified / regressed / uncertain |

**Done when:** every PR in the range has a row per claim.

## 4. Sweep the interactions

Read the merged code around each multi-PR file, whole functions and their callers. Answer each item with a `file:line` or "no change in range":

1. **Duplicate or overlapping fixes.** Two PRs fixing one symptom, a near-identical subject line, a hunk applied twice, a revert followed by a re-land. The same fix landing more than once means the first one's premise was wrong: say so.
2. **Helper drift.** Two helpers that now do one job differently: date and week arithmetic, formatting, `HealthTrackerUITests/Support/`, `TestDataBuilder`, the mocks.
3. **Test masking.** A mock default, a fixture or a startup switch in `UITestingSupport.swift` added by one PR that lets another PR's test pass without reaching production code.
4. **Persisted shape.** Fields added or retyped on `DayData`, `Meal`, `Workout`, `Mood` or `DayDataContainer` across several PRs still decode a file written before the range (root **Data Migrations**).
5. **Intent contract.** The frozen contract in `Presentation/Intents/AGENTS.md` still holds after every PR that touched an intent, and each write still posts `healthDataDidChange`.
6. **Ordering and lifecycle.** Startup, notification observers and ViewModel loading still run in a coherent order once the PRs are combined.
7. **Localization.** A key added by one PR and renamed or dropped by another; text one PR made user-visible that another left untranslated.
8. **Guardrails, net.** Diff `scripts/quality-thresholds.env`, the exception lists, `.swiftlint-baseline.json`, `.claude/settings.json`, `.claude/hooks/` and `.github/` across the whole range. Each step was approved alone; report the **net** change, which is the user's call.
9. **Docs that cite each other.** Rule numbers, headings and skill names still resolve, and the root `AGENTS.md` is within budget (`agent-docs-placement` skill, step 6). The README still describes what the gate does.

**Done when:** all nine items carry an answer.

## 5. Security pass

When the range touches a High-tier path (the tier table in the `reviewing` skill), run a `security-review` pass over the range diff in a fresh subagent, briefed with that skill's pass contract.

**Done when:** the pass has returned its findings, or the report says no High-tier path changed.

## 6. Gate the exact SHA

Run `CI=true scripts/quality --full` once in the worktree at `HEAD_SHA` (`quality-gate` skill), and read the hosted result for that same SHA: `gh run list --commit HEAD_SHA`. A green run on a PR's head is not main's result, and a pending or skipped run is not green.

CI skips a push to main that touches only docs or agent config (`paths-ignore` in `.github/workflows/ci.yml`), so `HEAD_SHA` can have no run. Then read the newest run on main inside the range, and name in the report the commits merged after it: the local gate, which did run on `HEAD_SHA`, is their evidence. A range with no run at all is reported as such. A hosted run on `HEAD_SHA` itself costs a macOS CI run (`gh workflow run ci.yml --ref main`): offer it to the user for a release audit.

**Done when:** the report holds the gate table, and the hosted run's URL, SHA and conclusion or the reason the range has none.

## 7. Report

```markdown
## Post-audit: <BASE_SHA>..<HEAD_SHA>

PRs audited: <list>            Direct commits: <list or none>
Issues: <claimed-closed issues still open, or none>
Gate on <HEAD_SHA>: <table>    Hosted CI: <run URL, SHA, conclusion; commits after it, or why the range has none>

### Findings
- [BLOCKING | SHOULD-FIX | NIT] file:line - which PRs interact, and the fix

### Claims
<the section 3 table, non-verified rows first>

### Guardrails, net
<what loosened or tightened across the range>

Ready to tag: yes | blocked by <findings>
```

Verify each finding against the code before reporting it. A BLOCKING finding gets a fix PR through the root Workflow; the rest are filed (`issue-tracking` skill). After fixes merge, audit the extended range.

**Done when:** the user has the report, and every finding is fixed, filed or rejected with a reason.
