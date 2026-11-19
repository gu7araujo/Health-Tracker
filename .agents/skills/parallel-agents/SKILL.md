---
name: parallel-agents
description: Delegate HealthTracker work to subagents, and run several at once, one per git worktree, without their Xcode builds, simulators and test runs colliding. Use when handing a step to a subagent or Workflow, when waiting on background work or a PR, when fanning work out to parallel agents, when working in a worktree, or when an Xcode MCP call fails with "Unknown workspace identifier" or "There is already a test running".
---

# Parallel agents

## Delegating

The orchestrating main session hands a subagent any step it needs back only as a conclusion: a broad search, a long log, a review pass, an independent slice. Work needing the user's judgement or the conversation's history stays in the main session.

- Run a subagent in the foreground when your next step needs its result, and in the background (the [harness routing](#harness-routing) table) otherwise. Run independent slices, or a staged pipeline (implement → review → verify), as a Workflow only when the user asks for one; without one, the orchestrator is the verify stage and checks each report field itself.
- Brief each subagent as a cold start: the goal, the files, the constraints, its done-criterion, and the shape of the report to return. Write each skill it needs as a call in its first step (`Skill("tdd")` for an implementer, plus the skill the hooks require for the files it edits).
- In an implementer's report, `red_evidence` is the test name plus its failing assertion line, `green_evidence` the gate table, `scenario` the en and pt-BR check for user-facing behaviour, `previews` the snapshots when Views changed. The PR body's "How verified" lists the `skills_loaded`.
- Create a worktree only when the task requires it or the user asks.
- A cloud subagent (`Agent` with `isolation: "remote"`) exists only in the Claude Code CLI. Elsewhere that call runs on this Mac: in T3 Code, ask the user for a linked environment or a cloud session started from claude.ai instead.

## Harness routing

The skills say what must happen; this table says how, per harness. Under T3 Code (`CLAUDE_CODE_ENTRYPOINT=t3-code`), its column overrides any other tool a skill names for the same need.

| Need | Claude Code CLI | T3 Code |
|---|---|---|
| Wait on a background command, without ending the turn | `Monitor` | `t3_background_wait` with its task ID |
| Wait on a delegated agent | the Workflow or `Agent` notification | follow the `delegate_task` run's `next` |
| Watch a PR's checks and comments | `gh pr checks <n> --watch`, or poll `gh` ~10 min (`babysit-pr`) | `watch_pull_request`, after `link_pull_request` |
| A background agent | `Agent` with `run_in_background` | `delegate_task` |
| A child in its own checkout | `.claude/worktrees/<branch>` | `delegate_task` with `isolation: "worktree"` |
| The Codex review pass | `codex review` (`reviewing` section 2) | `delegate_task` to a Codex model, briefed with the pass contract |
| Hand the work to a fresh session | `claude-handoff` | a forked thread, which carries the context |
| Reconnect the Xcode MCP | the user runs `/mcp` | the user picks Restart agent |

## Running agents at once

One agent per worktree (the one your harness made, or `.claude/worktrees/<branch-name>`), **at most two building or testing at once**, counting subagents, `delegate_task` children and Codex threads on this Mac; any further agents only read or edit until one of the two finishes. A third build exhausts the Mac's processes (`fork failed: resource temporarily unavailable`, after which every tool call fails). A single running Xcode serves every worktree's Xcode MCP calls concurrently, so parallel agents stay on the MCP. What they share is the hazard: Xcode's simulator-clone pool, the active run destination, and timestamp-named result files. Each step below keeps one of those from crossing between agents.

1. **Set up the worktree:** run `scripts/bootstrap` in it first, unless its `build/tools/bin/swiftlint` exists (T3 Code runs it on worktree creation through `t3.json`): the pre-push gate needs its tools, and swift-lsp its `buildServer.json`. From then on run one plain command per Bash call from the worktree root: Claude Code's worktree guard refuses a compound command it can't verify (`$(…)` feeding `xcodebuild`, `xcrun` or `git`, a heredoc into `gh` or `python`). Write text to a file and pass the file (`gh pr create --body-file <file>`, `python3 <script>`).
2. **Open your worktree's project:** `XcodeOpenWorkspace` with the absolute path `<worktree>/HealthTracker.xcodeproj`. Xcode rejects tool calls for a project it hasn't opened ("Unknown workspace identifier"), and a new agent's first open asks the user to approve it in Xcode. **Done when:** it returns a `workspaceIdentifier`.
3. **Pass that `workspaceIdentifier` on every Xcode MCP call.** The main checkout and each worktree are all open as `HealthTracker.xcodeproj`; the identifier is what keeps a build or test on your branch.
4. **Switch to a simulator of your own before your first test call.** Tests run on the workspace's active run destination, which Xcode shuts down to clone. Use `XcodeListRunDestinations` and `XcodeSwitchRunDestination` to pick an `HT-<branch>` simulator, leaving the user's selected simulator as it was.
5. **Build and run unit tests freely** (`BuildProject`, `RunSomeTests` on `HealthTrackerTests`): each worktree builds into its own DerivedData.
6. **Run UI tests through the MCP from one agent at a time**: `HealthTrackerUITests`, and `RunAllTests`, which includes them. Concurrent runs share the clone pool: when one run finishes, the other's clones are torn down and rebuilt, stretching a ~4 min suite past 15 min or stalling it outright, even with each worktree on its own run destination. Iterate on unit tests; run the full suite once at the end.
7. **Read results from the tool response** (pass/fail counts, errors) or `GetBuildLog` with your `workspaceIdentifier`. The artifact files it points to (`fullLogPath`, test console logs, `.xcresult`) are named by timestamp and overwritten when two runs finish in the same second.
8. **Stop what you abandon.** A run keeps going inside Xcode after its caller gives up, and blocks the next one ("There is already a test running"). `StopProject` with your `workspaceIdentifier` clears it; do the same for a test run with no result after ~15 min. A stuck gate: `scripts/quality --stop` in its worktree (`quality-gate` skill, section 1).
9. **Wait for a background run without ending your turn**: the [harness routing](#harness-routing) table names the wait that wakes you when it ends.
10. **Keep the user able to see progress.** A delegated run reports one line per phase (a Workflow script through `log()`), and the orchestrator posts a one-line status once a background run passes 20 min.

## On the `xcodebuild` fallback

Test on a simulator of your own: the `cli-test` skill's parallel setup. Isolated from the shared clone pool, UI tests can run in parallel there. For ad-hoc `xcodebuild` runs leave `-derivedDataPath` at its default, which already separates worktrees by path. `scripts/quality` isolates itself: it builds into its own `build/DerivedData` and tests on its own `HT-<branch>` clone. `--full` runs take turns across worktrees (`quality-gate` skill, section 1), so a run printing `Lock: waiting for <branch>` is working: leave it waiting.
