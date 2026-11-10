# The gate in a cloud session

The Mac-only gates run on CI, and you run them there yourself. Without `gh` in the container, dispatch, list and read logs with the GitHub MCP's matching workflow-run tools.

1. Run what Linux can locally first: `scripts/tests/run` for the script tests that need no Xcode or SwiftLint, ShellCheck as CI's `lint` job runs it, and `scripts/fitness/run`.
2. Commit and push the branch, then dispatch CI on it: `gh workflow run ci.yml --ref <branch>` (no PR needed). That run does `lint`, then `test`: `scripts/tests/run` and `CI=true scripts/quality --full`.
3. Find the run with `gh run list --workflow ci.yml --event workflow_dispatch --commit "$(git rev-parse HEAD)"` (it takes a few seconds to appear), and wait for it with a scheduled check-in or Monitor (~25 min).
4. Read each job's result; on red, read the failing step's log (`gh run view <id> --log-failed`), fix, push, and dispatch again.

Ask the user to run a command on their Mac only for what CI cannot do: a device, the Simulator UI, an Xcode MCP tool such as `RenderPreview`.

**Done when:** the dispatched run on the branch's last commit is green, and the gate table that ends its `Quality gate` step's log is pasted, with the run link, into the final report and PR.
