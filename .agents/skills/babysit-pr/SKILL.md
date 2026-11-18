---
name: babysit-pr
description: Watch a HealthTracker pull request through review and CI until it is ready to merge. Use when asked to monitor, watch or babysit a PR.
---

# Babysit PR

Every PR here gets the `claude-review` bot (`.github/workflows/claude-code-review.yml`, inline comments) and CI, whose required check is `ci-gate`. The bot is helpful and sometimes wrong.

## 1. Watch

If the harness watches PRs for you (the Claude Code desktop app's `ccd_pr` tools with Auto-fix), bind the PR and act when its events arrive. Otherwise poll about every 10 minutes (the macOS `test` job takes ~23):

```bash
gh pr view <n> --json headRefOid,mergeable,commits --jq '{head: .headRefOid, mergeable, pushed: .commits[-1].committedDate}'
gh pr checks <n>
gh pr view <n> --json comments,reviews
gh api graphql -f query='query($o:String!,$r:String!,$n:Int!){repository(owner:$o,name:$r){pullRequest(number:$n){reviewThreads(first:100){nodes{id isResolved comments(first:1){nodes{databaseId path line body createdAt}}}}}}}' -F o=<owner> -F r=<repo> -F n=<n> --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved | not)'
```

Act only on checks and comments newer than the latest push.

**Done when:** you have the list of new failing checks and unresolved threads since the latest push, or know there are none.

## 2. Act on each item

- **Bot finding**: verify it against the source before changing code. A real one gets fixed test-first (`tdd` skill), with the gate green before the push. A false positive, or one not worth addressing, gets a reply with the reason, then its thread resolved.
- **Red check**: read it with the `quality-gate` skill, section 7. Tell a repository failure (reproduces locally with `CI=true scripts/quality --full`) from an infrastructure flake (runner image, simulator, network, a runner that never connected). Flakes follow rule 6 in `HealthTrackerUITests/AGENTS.md`; report each one to the user.
- **Scope**: fix real shortcomings within the PR's original goal. Work beyond it becomes a GitHub issue (`issue-tracking` skill), linked in the reply.

Reply to an inline comment, then resolve its thread:

```bash
gh api repos/<owner>/<repo>/pulls/<n>/comments/<databaseId>/replies -f body="$reply"
gh api graphql -f query='mutation($id:ID!){resolveReviewThread(input:{threadId:$id}){thread{isResolved}}}' -F id=<thread id>
```

Format every comment posted on the user's behalf as:

```md
[MODEL-SLUG] RESPONDING ON BEHALF OF GUSTAVO
------

[actual reply]
```

For a UI fix, a screenshot from the `device-interaction` skill in the PR body shows the result.

**Done when:** every item from step 1 is fixed and pushed, or answered and resolved.

## 3. Keep up with `main`

```bash
git fetch origin main && git log --oneline HEAD..origin/main
```

When `main` moved under this PR (a conflict, or commits touching the same files), `git rebase origin/main`, rerun the gate, and `git push --force-with-lease` with a 600000 ms timeout (the pre-push hook runs `scripts/quality --fast`).

If a merged or open PR that overlaps this one makes it obsolete, stop watching and report it to the user. Close the PR only when the user authorized closing it; otherwise ask.

## 4. Stop

While nothing changed, stay silent: post no status comments. Stop when, on the latest commit, `claude-review` has finished (a green check can mean it reviewed nothing: `quality-gate` section 6), every required check is green, and no bot thread is unresolved. The user merges every PR: report the PR ready with its link.
