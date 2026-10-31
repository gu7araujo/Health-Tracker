# Scripts

The bash tooling behind the quality gate, the git hooks and CI. Each script's header comment is its spec (purpose, usage, exit codes); read it before changing the script.

## Map

- `quality` — the one gate: runs every check and prints the pass/fail table (`--help` lists the modes).
- `bootstrap` — setup per clone or new worktree: enables `.githooks`, installs the pinned tools into `build/tools/bin` (`ci/install-tools.sh`), then runs `doctor`.
- `doctor` — compares installed tools with `tool-versions.env`; warns locally, fails under `CI=true`.
- `lib/` — helpers behind `quality`; each file's header names its job. `tools-path.sh` (`prepend_tools_path <root>`, the one build/tools/bin PATH lookup) is also sourced by `doctor`, `tests/run`, `.githooks/pre-commit` and `.claude/hooks/format-swift.sh`.
- `ci/` — GitHub Actions steps: pinned tool install, Xcode selection, the job summary.
- `fitness/` — cross-file checks; `fitness/run` runs them all, except `persisted-shape-guard.sh` (warn-only, needs a base ref).
- `tests/` — a `test-*.sh` per script or config it covers (fixtures in `tests/fixtures/`); `tests/run` picks up every `test-*.sh`. CI runs it in the macOS `test` job, `quality` does not, so run `scripts/tests/run` yourself after a script change.
- `tool-versions.env` — pinned SwiftLint, SwiftFormat, Xcode and Periphery versions, and the iPhone model `lib/simulator.sh` clones for tests.
- `quality-thresholds.env` — coverage thresholds and ratchets; lowering one is the user's call.
- `coverage-exceptions.txt`, `fitness/test-mirror-exceptions.txt` — exemption lists; editing either is the user's call.

## Pitfalls

<pitfall_1>
**SIGPIPE UNDER PIPEFAIL** — every script runs `set -o pipefail`, so a reader that stops early fails the whole pipeline. In `cmd | grep -q` or `cmd | head`, the reader exits on its first match or line, `cmd` dies writing to the closed pipe with status 141, and the pipeline reports failure even though the match was found. It is a race between the writer's next write and the reader exiting, so small fixtures stay green: in a macOS repro (`seq N | grep -q 1`, 200 runs per size) it never failed up to ~16 KB (macOS's default pipe buffer), failed about half the runs at ~19 KB and every run from ~39 KB. Linux, where the `lint` job runs fitness, buffers 64 KB, so the onset sits higher there. In #20, `test-mirror.sh`'s `! grep '{' <<<"$code" | grep -Evq ...` turned true on a 196 KB file and skipped it. Read the whole input in one `awk` pass (as `protocol_only` in `fitness/test-mirror.sh` does), or `grep -q` the file or a here-string directly; add a test with input past 64 KB, red on both (`test-fitness-test-mirror.sh`, "larger than a pipe buffer").
</pitfall_1>
