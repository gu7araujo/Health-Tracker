---
name: parallel-agents
description: Run several agents at once on HealthTracker, one per git worktree, without their Xcode builds, simulators and test runs colliding. Use when fanning work out to parallel agents or a Workflow, when you are an agent working in a worktree while others build or test, or when an Xcode MCP call fails with "Unknown workspace identifier" or "There is already a test running".
---

# Parallel agents

One agent per worktree (`.claude/worktrees/<branch-name>`), **at most two building or testing at once**; any further agents only read or edit until one of the two finishes. A third build exhausts the Mac's processes (`fork failed: resource temporarily unavailable`, after which every tool call fails). A single running Xcode serves every worktree's Xcode MCP calls concurrently, so parallel agents stay on the MCP. What they share is the hazard: Xcode's simulator-clone pool, the active run destination, and timestamp-named result files. Each step below keeps one of those from crossing between agents.

1. **Set up the worktree:** run `scripts/bootstrap` in it before its first push.
2. **Open your worktree's project:** `XcodeOpenWorkspace` with the absolute path `<worktree>/HealthTracker.xcodeproj`. Xcode rejects tool calls for a project it hasn't opened ("Unknown workspace identifier"), and a new agent's first open asks the user to approve it in Xcode. **Done when:** it returns a `workspaceIdentifier`.
3. **Pass that `workspaceIdentifier` on every Xcode MCP call.** The main checkout and each worktree are all open as `HealthTracker.xcodeproj`; the identifier is what keeps a build or test on your branch.
4. **Switch to a simulator of your own before your first test call.** Tests run on the workspace's active run destination, which Xcode shuts down to clone. Use `XcodeListRunDestinations` and `XcodeSwitchRunDestination` to pick an `HT-<branch>` simulator, leaving the user's selected simulator as it was.
5. **Build and run unit tests freely** (`BuildProject`, `RunSomeTests` on `HealthTrackerTests`): each worktree builds into its own DerivedData.
6. **Run UI tests through the MCP from one agent at a time**: `HealthTrackerUITests`, and `RunAllTests`, which includes them. Concurrent runs share the clone pool: when one run finishes, the other's clones are torn down and rebuilt, stretching a ~4 min suite past 15 min or stalling it outright, even with each worktree on its own run destination. Iterate on unit tests; run the full suite once at the end.
7. **Read results from the tool response** (pass/fail counts, errors) or `GetBuildLog` with your `workspaceIdentifier`. The artifact files it points to (`fullLogPath`, test console logs, `.xcresult`) are named by timestamp and overwritten when two runs finish in the same second.
8. **Stop what you abandon.** A run keeps going inside Xcode after its caller gives up, and blocks the next one ("There is already a test running"). `StopProject` with your `workspaceIdentifier` clears it; do the same for a test run with no result after ~15 min. A stuck gate: `scripts/quality --stop` in its worktree, never `kill` or `pkill`.
9. **Wait on events.** Wait for a background run with Monitor, and for CI with `gh pr checks <n> --watch` or a scheduled check-in: each wakes you when the run ends.
10. **Keep the user able to see progress.** A workflow script calls `log()` with one line per phase, and the orchestrator posts a one-line status once a background workflow passes 20 min.

## On the `xcodebuild` fallback

Test on a simulator of your own: the `cli-test` skill's parallel setup. Isolated from the shared clone pool, UI tests can run in parallel there. For ad-hoc `xcodebuild` runs leave `-derivedDataPath` at its default, which already separates worktrees by path. `scripts/quality` isolates itself: it builds into its own `build/DerivedData` and tests on its own `HT-<branch>` clone. `--full` runs take turns across worktrees (`quality-gate` skill, section 1), so a run printing `Lock: waiting for <branch>` is working: leave it waiting.
