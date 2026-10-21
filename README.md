## Setup

Make sure SwiftLint, SwiftFormat, xcbeautify and jq are installed on your machine via Homebrew:

```bash
brew install swiftlint swiftformat xcbeautify jq
```

Then, once per clone, install the git hooks and check tool versions:

```bash
scripts/bootstrap
```

Run the quality gate with `scripts/quality --fast` while working and `scripts/quality --full` before opening a PR.
