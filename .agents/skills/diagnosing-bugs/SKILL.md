---
name: diagnosing-bugs
description: Diagnosis loop for hard bugs, flaky tests and performance regressions. Use when the user says "diagnose"/"debug this", or reports something broken/throwing/failing/slow.
---

# Diagnosing Bugs

A discipline for hard bugs. Skip phases only when explicitly justified. A red gate or CI check starts in the `quality-gate` skill (sections 3 and 7); come here when its cause is not obvious from the log.

## Redact

This skill has you show commands, outputs and captured artifacts. A captured `HealthTrackerData.json` holds a person's health data: quote only the lines that carry the signal, and write `<REDACTED>` over the rest.

If the redacted output is not enough to diagnose the bug, say so and ask the user.

## Phase 1: Build a feedback loop

**This is the skill.** Everything else is mechanical. If you have a **tight** pass/fail signal for the bug (one that goes red on _this_ bug), you will find the cause; bisection, hypothesis-testing, and instrumentation all just consume it. If you don't have one, no amount of staring at code will save you.

Spend disproportionate effort here. **Be aggressive. Be creative. Refuse to give up.**

### Ways to construct one, in roughly this order

Run tests through the runner the root `AGENTS.md` names (`RunSomeTests` in a main session); the `xcodebuild` fallback has its own rule there.

1. **Failing unit test** at whatever seam reaches the bug: a Domain entity or use case, the repository, the ViewModel. `RunSomeTests` on that one test.
2. **Code snippet.** `RunCodeSnippet` on a pure Domain function with a fixture input, compared against a literal known-good value.
3. **Replay a captured store.** Save the `HealthTrackerData.json` that shows the bug (the `mock-sim-data` skill finds the file) and load it through the repository in a test.
4. **UI or intent test.** An XCUITest that drives the app and asserts by label, or an AppIntentsTesting test for an intent (`HealthTrackerUITests/AGENTS.md`, `HealthTrackerIntentsUITests/AGENTS.md`).
5. **Throwaway harness.** A test that builds only the objects on the bug's path, with the repo's mocks for the rest, and calls them once.
6. **Property loop.** If the bug is "sometimes wrong output", run the function over many generated inputs in one test and look for the failure mode.
7. **Bisection.** If the bug appeared between two known commits, `git bisect` in a worktree and run the loop at each step.
8. **Differential loop.** Run the same input on `main` and on the branch (two worktrees, `parallel-agents` skill) and diff the outputs.
9. **Running app.** A `device-interaction` session on a store seeded with `mock-sim-data`, asserting on the UI hierarchy.
10. **HITL bash script.** Last resort. If a human must tap, drive _them_ with a copy of [`scripts/hitl-loop.template.sh`](scripts/hitl-loop.template.sh) (in this skill's folder) so the loop is still structured. The user runs the copy in a terminal, since an agent's shell has no keyboard to answer its prompts, and the `--- Captured ---` block comes back to you.

Build the right feedback loop, and the bug is 90% fixed.

### Tighten the loop

Treat the loop as a product. Once you have _a_ loop, **tighten** it:

- Can I make it faster? (One test instead of the suite, a unit seam instead of a UI test.)
- Can I make the signal sharper? (Assert on the specific symptom, not "didn't crash".)
- Can I make it more deterministic? (Pin the date with `TestDataBuilder.fixedDate`, use the isolated store the `-uiTesting` switch gives, seed the generator.)

A 30-second flaky loop is barely better than no loop; a 2-second deterministic one is tight, a debugging superpower.

### Non-deterministic bugs

The goal is not a clean repro but a **higher reproduction rate**. Repeat the trigger (the same test 20 or 100 times), run it while the Mac is under load, narrow timing windows, inject sleeps. A 50%-flake bug is debuggable; 1% is not, so keep raising the rate until it's debuggable. Record the rate as a count (`3 of 20 red`): it is the baseline the fix is measured against.

### When you genuinely cannot build a loop

Stop and say so explicitly. List what you tried. Ask the user for: (a) the device or environment that reproduces it, (b) a redacted captured artifact (the store file, an xcresult bundle, a console log, a screen recording with timestamps), or (c) permission to add temporary instrumentation. Do **not** proceed to hypothesise without a loop.

### Completion criterion: a tight loop that goes red

Phase 1 is done when the loop is **tight** and **red-capable**: you can name **one command or tool call** (a test, a snippet, a script path) that you have **already run at least once** (show the invocation and its output, redacted), and that is:

- [ ] **Red-capable**: it drives the actual bug code path and asserts the **user's exact symptom**, so it can go red on this bug and green once fixed. Not "runs without erroring"; it must be able to _catch this specific bug_.
- [ ] **Deterministic**: same verdict every run (flaky bugs: a pinned, high reproduction rate, per above).
- [ ] **Fast**: seconds, not minutes.
- [ ] **Agent-runnable**: you can run it unattended; a human in the loop only via the HITL script (item 10).

If you catch yourself reading code to build a theory before this command exists, **stop: jumping straight to a hypothesis is the exact failure this skill prevents.** No red-capable command, no Phase 2.

## Phase 2: Reproduce + minimise

Run the loop. Watch it go red as the bug appears.

Confirm:

- [ ] The loop produces the failure mode the **user** described, not a different failure that happens to be nearby. Wrong bug = wrong fix.
- [ ] The failure is reproducible across multiple runs (or, for non-deterministic bugs, reproducible at a high enough rate to debug against).
- [ ] You have captured the exact symptom (error message, wrong output, slow timing) so later phases can verify the fix actually addresses it.

### Minimise

Once it's red, shrink the repro to the **smallest scenario that still goes red**. Cut inputs, callers, config, data, and steps **one at a time**, re-running the loop after each cut, and keep only what's load-bearing for the failure.

Why bother: a minimal repro shrinks the hypothesis space in Phase 3 (fewer moving parts left to suspect) and becomes the clean regression test in Phase 5.

Done when **every remaining element is load-bearing**: removing any one of them makes the loop go green.

Do not proceed until you have reproduced **and** minimised.

## Phase 3: Hypothesise

**Search for an earlier fix first.** `git log --all --grep '<symptom or test name>'` and the closed issues (`gh issue list --state closed --search '<keywords>'`). A bug that was fixed before is a **regression** of that fix: the premise the earlier fix rested on is hypothesis 1, and a second fix on the same premise will fail the same way.

Generate **3–5 ranked hypotheses** before testing any of them. Single-hypothesis generation anchors on the first plausible idea.

Each hypothesis must be **falsifiable**: state the prediction it makes.

> Format: "If <X> is the cause, then <changing Y> will make the bug disappear / <changing Z> will make it worse."

If you cannot state the prediction, the hypothesis is a vibe: discard or sharpen it.

**Show the ranked list to the user before testing.** They often have domain knowledge that re-ranks instantly ("we just merged a change to #3"), or know hypotheses they've already ruled out. Cheap checkpoint, big time saver. Don't block on it; proceed with your ranking if the user is AFK.

## Phase 4: Instrument

Each probe must map to a specific prediction from Phase 3. **Change one variable at a time.**

Tool preference:

1. **Debugger** on the running app (`InvokeDebuggerCommand`). One breakpoint beats ten logs.
2. **Targeted logs** at the boundaries that distinguish hypotheses, read with `GetConsoleOutput`.
3. Never "log everything and grep".

**Tag every debug log** with a unique prefix, e.g. `[DEBUG-a4f2]`. Cleanup at the end becomes a single grep. Untagged logs survive; tagged logs die.

**Perf branch.** For performance regressions, logs are usually wrong. Instead: establish a baseline measurement (Instruments, or `measure(metrics:)` in a `HealthTrackerUITests` test; the unit-test target takes no XCTest), then bisect. Measure first, fix second.

## Phase 5: Fix + regression test

Write the regression test **before the fix** (`tdd` skill), but only if there is a **correct seam** for it.

A correct seam is one where the test exercises the **real bug pattern** as it occurs at the call site. If the only available seam is too shallow (single-caller test when the bug needs multiple callers, unit test that can't replicate the chain that triggered the bug), a regression test there gives false confidence.

**If no correct seam exists, that itself is the finding.** Note it. The codebase architecture is preventing the bug from being locked down. File it (`issue-tracking` skill).

If a correct seam exists:

1. Turn the minimised repro into a failing test at that seam.
2. Watch it fail, and keep its name and failing assertion line: item 1 of the root **Definition of done**. If you forced the red by mutating code or a fixture, `git diff` to prove the mutation landed before you trust it.
3. Apply the fix.
4. Watch it pass.
5. Re-run the Phase 1 feedback loop against the original (un-minimised) scenario. For a flaky bug, re-run it as many times as the baseline and report both counts.

## Phase 6: Cleanup

Required before declaring done:

- [ ] Original repro no longer reproduces (re-run the Phase 1 loop)
- [ ] Regression test passes (or absence of seam is documented)
- [ ] All `[DEBUG-...]` instrumentation removed (`grep` the prefix)
- [ ] Throwaway harnesses deleted
- [ ] The hypothesis that turned out correct is stated in the PR's Summary (`file-pr` skill), so the next debugger learns
