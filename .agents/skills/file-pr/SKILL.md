---
name: file-pr
description: File a concise HealthTracker pull request - title and description a reviewer understands in one read. Use when opening a PR, or when rewriting an existing PR's title or description.
---

# File PR

Pushing, when to open the PR and watching its CI live in the `quality-gate` skill, section 6. This skill writes what the reviewer reads.

## 1. Check the branch

```bash
gh pr view --json url,state 2>/dev/null   # a PR for this branch already exists: edit it with `gh pr edit`
git fetch origin main && git diff --stat origin/main...HEAD
```

Read the diff against `origin/main` and compare it with the goal: every file traces to the request, and nothing the request needs is missing.

**Done when:** you know whether to create or edit, and the diff matches the goal.

## 2. Write the title

PR titles become the squash commit message, so follow the history's convention, `type(scope): summary` (`git log --oneline -15 origin/main`, `gh pr list --state merged -L 10`). Make the summary say why the change matters to a user or developer, in plain words:

BAD
> ❌ fix(data): decode Mood with decodeIfPresent

GOOD
> ✅ fix(data): stop losing a day's log when an old file has no mood

## 3. Write the description

Fill `.github/pull_request_template.md`; its comments say what each section holds. Open **Summary** with the problem in a sentence or two, told from the user's original prompt, then the solution in a sentence. The implementation inventory goes after, only where a reviewer needs it:

BAD
> ❌ Changed `DayDataRepository.add(_:)` to resolve the date through `Calendar.current.startOfDay(for: selectedDate)` instead of `Date.now`. Added `selectedDate` to `AddWaterUseCase`, updated `WaterViewModel` and its mock.

GOOD
> ✅ Water logged while looking at yesterday landed on today. Now it lands on the day you're looking at.

Delete the template's comments and any line that does not apply.

**Done when:** **Quality gate** holds the table from the last `scripts/quality` run, **How verified** carries the Definition of done evidence that applies, and a reviewer who never saw the conversation knows from the first two sentences what was wrong and what changed.

## 4. Open it

Open it once the gate `quality-gate` section 6 names is green: push (`git push -u origin HEAD`, with that section's timeout), then `gh pr create --title ... --body-file ...` (or `gh pr edit`), ready for review. Continue at section 6 to watch CI.

**Done when:** `gh pr view --json title,body,isDraft` shows your title and body with `isDraft` false, and the user has the link.
