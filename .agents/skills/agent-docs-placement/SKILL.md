---
name: agent-docs-placement
description: Decide where an instruction for agents belongs in HealthTracker - the root AGENTS.md, a directory's AGENTS.md, a skill, a lint rule or check, the README, or nowhere - and move it without breaking what cites it. Use before adding a rule, convention, gotcha or workflow step to any AGENTS.md or skill, when a retro row or review asks for a doc change, when a doc has grown and needs slimming, or when unsure which file should hold a new instruction.
---

# Agent docs placement

An instruction costs context every time it loads, so it belongs in the **home** that loads only when it is needed. This skill picks the home; the `writing-for-agents` skill covers how to word what goes there.

## The homes

| Home | Loads | Holds |
|---|---|---|
| Root `AGENTS.md` | Every turn of every session and subagent | What every task needs: the red → green workflow, the done bar, hard guardrails, and pointers to everything else. Budget: under ~1,200 words (`wc -w AGENTS.md`) |
| A directory's `AGENTS.md` | In Claude Code, when a file in that directory is first read. Not while planning, and not in a review that reads only a diff | Rules for code in that one directory, as `<rule_N>` blocks or conventions |
| A skill (`.agents/skills/<name>/SKILL.md`) | Its description: every turn. Its body: when the description fires | One moment or task that cuts across directories (reviewing, shipping a PR, running parallel agents) |
| A sibling file inside a skill | When the skill's body points to it | One branch of that skill |
| A lint rule, fitness check, hook or deny rule | Never: it runs instead of being read | Anything a regex or script can see |
| `README.md`, a script's header comment | When opened | What a human needs; a script's own spec |
| Memory | Each session on this machine only | Facts about the user or this Mac. A rule cloud agents could use goes in the repo |

## 1. Decide whether it earns a home

Drop it when the model already does it by default, or when one command or one file answers it (`scripts/quality --help`, a config file, the directory layout). Keep what an agent cannot find by looking: the unwritten convention, the reason behind a choice, the gotcha.

**Done when:** you can name the mistake an agent makes without this instruction.

## 2. Prefer enforcement to prose

If a script could catch the mistake, propose a SwiftLint `custom_rules` entry, a `scripts/fitness/` check or a hook, each with its test, written red → green. Those paths are High tier and change the guardrails, so propose it to the user before building it. Prose then shrinks to one line naming the enforcer.

**Done when:** the instruction is marked enforceable (with the proposal made) or prose-only.

## 3. Find the existing home

```bash
grep -rn '<keyword>' AGENTS.md HealthTracker*/AGENTS.md HealthTracker/*/AGENTS.md HealthTracker/Presentation/Intents/AGENTS.md scripts/AGENTS.md .agents/skills README.md
```

A meaning that already has a home gets edited there. One meaning in two places drifts, and inflates its importance.

**Done when:** two or three keyword sets are searched, and the instruction is an edit to a named file or confirmed new.

## 4. Pick the home for a new instruction

Ask who needs it, and when:

- **Every task, in any directory** → root `AGENTS.md`. Check the budget first; over it, something else moves out in the same change.
- **Only when touching one directory** → that directory's `AGENTS.md`. Create one when a subdirectory's rules would otherwise load for unrelated work in its parent (as `Presentation/Intents/` has).
- **Only at one moment, in any directory** → the skill for that moment. Extend an existing skill before creating one: a new skill adds a description that loads every turn, so it needs a trigger no existing skill has.
- **Only on one branch of a skill** → a sibling file in that skill, with a pointer from its body.

A hard guardrail (frozen contract, never-merge, the user's-call list) keeps one plain sentence in the root or the directory file even when its detail lives in a skill: a pointer can fail to fire, and a guardrail must not depend on it.

**Done when:** the home is named with the reason another home is wrong.

## 5. Write it and wire it

- **A moved instruction leaves a pointer** where it was: what the material is, and the condition for reaching it.
- **New skill:** `.agents/skills/<name>/SKILL.md`, a symlink `.claude/skills/<name> -> ../../.agents/skills/<name>`, and optionally `agents/openai.yaml` (see `tdd`).
- **New `AGENTS.md`:** add its row to the root Repo Map. Under `HealthTracker/` it also needs a `membershipExceptions` entry in `HealthTracker.xcodeproj/project.pbxproj`, or it ships in the app bundle; that edit makes the change Standard tier instead of Docs. Deeper than one level, add its path to the `grep` in step 3 and in the `retro` skill.

**Done when:** every pointer, link and list above that applies is in the diff.

## 6. Check what cites the docs

Docs are cited by name from outside themselves. After a move or rename, each of these still resolves:

- **Rule numbers.** `.swiftlint.yml` messages and README tables cite `<file> rule_N`. Append new rules; keep existing numbers.
- **Headings.** `scripts/fitness/persisted-shape-guard.sh` and its test cite the root `Data Migrations` heading; skills cite root sections (`Workflow`, `Quality Gates`); `quality-gate`'s section numbers (1 to 7) are cited within it and from the README, and `issue-tracking` cites its CI section by name.
- **Skill names** in backticks across `AGENTS.md` files and skills.

```bash
grep -rn '<old heading, rule or skill name>' . --include='*.md' --include='*.yml' --include='*.sh' --exclude-dir=build --exclude-dir=.git
```

**Done when:** that search returns only lines that point at the new location, `wc -w AGENTS.md` is within budget, and `scripts/quality --fast` exits 0. Then review as the root Workflow says (`reviewing` skill).
