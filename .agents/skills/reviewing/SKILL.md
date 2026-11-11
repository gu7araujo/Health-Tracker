---
name: reviewing
description: Review a HealthTracker diff before it ships - pick the passes its risk tier calls for (code-review level, Codex, security-review), brief each one, and converge the rounds. Use at Workflow step 5, whenever a change is ready for review, when briefing a review subagent, or when you are the subagent running a review pass.
---

# Reviewing

A diff is reviewed by **passes** (one reviewer, one run), chosen by its risk **tier**, in **rounds** that converge. The session that wrote the change never reviews it: a fresh context reads the diff the way the next maintainer will, without the author's assumptions filling the gaps.

## 1. Pick the tier

The tier is set by the riskiest path the diff touches. A diff of only files matching the `paths-ignore` list in `.github/workflows/ci.yml` is Docs, even under a High path.

| Tier | Diff touches | Passes |
|---|---|---|
| Docs | only docs or agent config (CI's `paths-ignore`) | `code-review` at `low` |
| Standard | app or test code | `code-review` at `high`, then Codex |
| High | persisted types (`Domain/Entities/`, `Data/`), the frozen intent contract (`Presentation/Intents/`), `HealthTracker.entitlements`, `Info.plist`, and the guardrails (`.github/`, `.githooks/`, `scripts/`, `.claude/settings.json`, `.claude/hooks/`, `.swiftlint.yml`, `.periphery.yml`) | Standard with `code-review` at `xhigh`, plus `security-review` |

**Done when:** every path in `git diff --name-only main...` (plus uncommitted files) is placed in a tier, and the highest one is named.

## 2. Run round 1

Run every pass of the tier.

- **Claude passes** (`code-review`, `security-review`): each in a subagent with fresh context (the Agent tool), briefed as a cold start with the diff's scope, the tier and the [pass contract](#the-pass-contract) below.
- **Codex** runs when `codex` is on the `PATH` (cloud sessions lack it: say so in the report):

  ```bash
  codex review -c model_reasoning_effort="xhigh" --uncommitted   # or --base main once committed
  ```

  It accepts no custom prompt alongside `--uncommitted`, and runs for minutes: give it a 600000 ms timeout.

**Done when:** each pass of the tier has returned its findings list, or is named in the report as unavailable.

## 3. Verify, then fix

Check each finding against the code before acting on it. A real one gets fixed (a bug fix starts with its regression test: call `Skill("tdd")`). A false positive is rejected with the reason, and stays rejected when a later pass reports it again. A pre-existing problem becomes a GitHub issue (`issue-tracking` skill), so the PR stays on its own change.

**Done when:** every finding is fixed, rejected with a reason, or filed.

## 4. Converge

Later rounds re-review only the fixes: `code-review` at the tier's level, in a fresh subagent, on the lines the fixes changed. Stop when a round returns "No issues". After three rounds that still produce findings, stop and rethink the approach with the user instead of starting a fourth.

**Done when:** a round returns "No issues", or the user has the three rounds' findings and the question of how to proceed.

## The pass contract

What every pass, Claude or Codex, is held to. Put it in each brief; follow it when you are the pass.

- **Criteria:** the conventions in the root `AGENTS.md`, plus the `<rule_N>` blocks and conventions in the `AGENTS.md` of each directory the diff touches. Read those first: they don't load on their own. A broken rule is a finding.
- **Report bugs and rule breaks.** Format, lint, unused code and the fitness checks belong to `scripts/quality`, which enforces them; leave those, `build/` and `.swiftlint-baseline.json` to it.
- **Mark pre-existing problems** (in lines the diff doesn't touch) as such.
- **Format:** open with the finding count, or "No issues"; cite `file:line` for every finding.
